# Detecting Windows ARM from x64 Processes

## The Problem

**Critical issue for PR #13790:** When running x64 processes (Deno, R) on Windows ARM via WOW64 emulation, standard architecture detection returns `x86_64`, not `ARM64`.

This means:
- `Deno.build.arch` returns `"x86_64"` ❌
- `R.version[['platform']]` returns `"x86_64-w64-mingw32"` ❌
- Neither can detect they're actually running on ARM Windows!

**Why this matters:** Quarto PR #13790 needs to detect "x64 R on ARM Windows" to show the appropriate error message. Without native ARM detection, the check doesn't work.

## The Solution

Use Windows API `IsWow64Process2` which returns the **native machine architecture** even when running under emulation.

### Windows API: IsWow64Process2

```c
BOOL IsWow64Process2(
  HANDLE hProcess,
  USHORT *pProcessMachine,
  USHORT *pNativeMachine  // ← This tells us the real architecture
);
```

**Returns:**
- `pNativeMachine = 0xAA64` (43620) → Windows ARM64
- `pNativeMachine = 0x8664` (34404) → Windows x64

This works even from x64 processes running under WOW64 emulation.

## Implementation

### R Implementation

**⚠️ LIMITATION: R cannot reliably detect ARM Windows**

R's `.Call()` FFI is designed for R's internal C API, not arbitrary Windows DLL calls. The `IsWow64Process2` function requires pointer output parameters that `.Call()` doesn't handle correctly.

**Test result on Windows ARM x64:** Returns `FALSE` when it should return `TRUE`

```r
# This code FAILS on Windows ARM - included for demonstration only
is_windows_arm <- function() {
  # ... attempts to use IsWow64Process2 via .Call() ...

  # PROBLEM: Output parameters (processMachine, nativeMachine) are
  # never modified by .Call() when calling Windows API functions
  # The check always returns FALSE even on ARM Windows
}
```

**Why this fails:**
- R's `.Call()` is designed for R's C API, not arbitrary DLL calls
- Windows API functions with pointer output parameters don't work correctly
- Proper detection would require a compiled C extension or specialized package

**Conclusion:** R scripts **cannot self-detect** ARM Windows. Quarto (via Deno) must do the detection.

**Test script:** `detect-windows-arm.R` (demonstrates the failure)

### Deno/TypeScript Implementation

**✅ WORKS: Deno can successfully detect ARM Windows**

```typescript
function isWindowsArm(): boolean {
  if (Deno.build.os !== "windows") {
    return false;
  }

  try {
    const kernel32 = Deno.dlopen("kernel32.dll", {
      IsWow64Process2: {
        parameters: ["pointer", "pointer", "pointer"],
        result: "i32",
      },
      GetCurrentProcess: {
        parameters: [],
        result: "pointer",
      },
    });

    const hProcess = kernel32.symbols.GetCurrentProcess();
    const processMachineBuffer = new Uint16Array(1);
    const nativeMachineBuffer = new Uint16Array(1);

    // CRITICAL: Use Deno.UnsafePointer.of() to convert TypedArrays to pointers
    const result = kernel32.symbols.IsWow64Process2(
      hProcess,
      Deno.UnsafePointer.of(processMachineBuffer),
      Deno.UnsafePointer.of(nativeMachineBuffer)
    );

    kernel32.close();

    if (result === 0) return false;

    // IMAGE_FILE_MACHINE_ARM64 = 0xAA64 = 43620
    const IMAGE_FILE_MACHINE_ARM64 = 0xAA64;
    return nativeMachineBuffer[0] === IMAGE_FILE_MACHINE_ARM64;
  } catch (error) {
    return false;
  }
}
```

**Key points:**
- Uses Deno FFI (`Deno.dlopen`) to call Windows API
- **CRITICAL:** Must use `Deno.UnsafePointer.of()` to convert TypedArray buffers to pointers
- Requires `--allow-ffi` permission
- Returns `false` if API not available or error occurs
- Uses `Uint16Array` for USHORT parameters

**Test result on Windows ARM x64:** ✅ Returns `true` correctly

**Test script:** `detect-windows-arm.ts`

## Testing

**Workflow:** [`.github/workflows/test-arm-detection.yml`](https://github.com/cderv/quarto-windows-arm/actions/runs/20272725035)

Tests both implementations on Windows ARM GitHub Actions runner.

### Actual Test Results

**Test environment:** Windows 11 ARM, GitHub Actions `windows-11-arm` runner

1. **Deno x64 → ARM detection** ✅ SUCCESS
   - Deno reports `x86_64` (standard detection)
   - Detection function returns `true` (IsWow64Process2)
   - **Correctly identifies ARM Windows**

2. **R x64 → ARM detection** ❌ FAILURE
   - R reports `x86_64-w64-mingw32` (standard detection)
   - Detection function returns `FALSE` (IsWow64Process2 fails)
   - **Cannot detect ARM Windows due to FFI limitation**

### Detection Comparison

| Process | Standard Detection | IsWow64Process2 Detection | Works? |
|---------|-------------------|---------------------------|--------|
| Deno x64 on ARM | `x86_64` | ✅ Windows ARM | ✅ YES |
| R x64 on ARM | `x86_64-w64-mingw32` | ❌ Not detected | ❌ NO |
| R ARM64 on ARM | `aarch64-w64-mingw32` | N/A (already native) | N/A |
| Deno x64 on x64 | `x86_64` | ❌ Not ARM | ✅ YES |

**Conclusion:** Only Deno can reliably detect ARM Windows from x64 processes. R cannot.

## For Quarto PR #13790

### Current Issue

The PR likely checks:
```typescript
// This doesn't work from x64 Deno!
if (Deno.build.arch === "aarch64" && Deno.build.os === "windows") {
  // Check if R is x64
}
```

This fails because `Deno.build.arch` returns `"x86_64"` when Quarto is running under x64 Deno on ARM.

### Required Change

Replace architecture check with Windows API detection:

```typescript
function isWindowsArm(): boolean {
  // Use IsWow64Process2 implementation above
}

// In R capabilities check:
if (isWindowsArm() && rPlatform.includes("x86_64")) {
  // Detected: x64 R on Windows ARM
  // Show error message
}
```

### Implementation Locations

In Quarto CLI codebase, this detection needs to be added:

1. **In Deno/TypeScript code** (where R capabilities are checked):
   - Add `isWindowsArm()` function using FFI
   - Replace `Deno.build.arch` checks with `isWindowsArm()`

2. **Permissions required:**
   - Quarto will need `--allow-ffi` permission for Deno
   - This is only needed on Windows

3. **Fallback handling:**
   - If `IsWow64Process2` fails (older Windows), assume not ARM
   - This is safe - older Windows versions don't have ARM variants

## Compatibility

**IsWow64Process2 availability:**
- ✅ Windows 10 version 1511+ (November 2015)
- ✅ Windows 11 (all versions)
- ❌ Windows 7, 8, 8.1, 10 pre-1511

**Fallback behavior:**
- If API not available, return `FALSE` / `false`
- Safe default: assume x64 Windows, not ARM
- Pre-2015 Windows doesn't have ARM variants anyway

## Verification

To verify the implementations work:

```bash
# Clone test repository
git clone https://github.com/cderv/quarto-windows-arm
cd quarto-windows-arm

# View workflow results
gh run list --workflow="Test Windows ARM Detection"

# Or run locally on Windows ARM:
Rscript detect-windows-arm.R
deno run --allow-ffi detect-windows-arm.ts
```

## References

- **Windows API Documentation:** [IsWow64Process2](https://learn.microsoft.com/en-us/windows/win32/api/wow64apiset/nf-wow64apiset-iswow64process2)
- **Machine Type Constants:** [PE Format](https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#machine-types)
- **Deno FFI:** [Foreign Function Interface](https://deno.land/manual/runtime/ffi_api)
- **R Foreign:** [.Call Interface](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Calling-_002eCall)

## Summary

**Key findings from test results:**

1. **Deno FFI works** ✅
   - Deno x64 can successfully detect ARM Windows using `IsWow64Process2`
   - Requires `Deno.UnsafePointer.of()` for pointer conversion
   - Returns correct results on both ARM and x64 Windows

2. **R FFI fails** ❌
   - R's `.Call()` cannot handle Windows API pointer parameters
   - R x64 cannot self-detect ARM Windows
   - Would require compiled C extension to work

**Implications for PR #13790:**

**Without IsWow64Process2:**
- ❌ Deno's `Deno.build.arch` returns `x86_64` on ARM (wrong)
- ❌ PR #13790's detection won't work with architecture strings
- ❌ Users get generic errors, not ARM-specific guidance

**With IsWow64Process2 (Deno FFI):**
- ✅ Deno can detect Windows ARM from x64 processes
- ✅ PR #13790 can identify "x64 R on ARM Windows"
- ✅ Users get helpful error messages with ARM64 R download links
- ✅ R scripts don't need to self-detect (Quarto does it)

**This is essential for the PR to work correctly.**
