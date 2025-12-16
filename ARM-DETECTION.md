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

```r
is_windows_arm <- function() {
  if (.Platform$OS.type != "windows")
    return(FALSE)

  kernel32 <- "kernel32.dll"

  iswow64process2 <- getNativeSymbolInfo(
    name = "IsWow64Process2",
    PACKAGE = kernel32,
    withRegistrationInfo = FALSE,
    mustExist = FALSE
  )

  if (is.null(iswow64process2))
    return(FALSE)

  processMachine <- as.integer(0)
  nativeMachine  <- as.integer(0)

  res <- .Call(
    iswow64process2,
    getNativeSymbolInfo("GetCurrentProcess", kernel32),
    processMachine,
    nativeMachine
  )

  # IMAGE_FILE_MACHINE_ARM64 = 0xAA64 = 43620
  nativeMachine == 0xAA64
}
```

**Key points:**
- Uses `getNativeSymbolInfo` to get function pointer
- Returns `FALSE` if API not available (Windows < 10)
- Checks `nativeMachine` against ARM64 constant

**Test script:** `detect-windows-arm.R`

### Deno/TypeScript Implementation

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
    const processMachine = new Uint16Array(1);
    const nativeMachine = new Uint16Array(1);

    const result = kernel32.symbols.IsWow64Process2(
      hProcess,
      processMachine,
      nativeMachine
    );

    kernel32.close();

    if (result === 0) return false;

    // IMAGE_FILE_MACHINE_ARM64 = 0xAA64 = 43620
    const IMAGE_FILE_MACHINE_ARM64 = 0xAA64;
    return nativeMachine[0] === IMAGE_FILE_MACHINE_ARM64;
  } catch (error) {
    return false;
  }
}
```

**Key points:**
- Uses Deno FFI (`Deno.dlopen`) to call Windows API
- Requires `--allow-ffi` permission
- Returns `false` if API not available or error occurs
- Uses `Uint16Array` for USHORT parameters

**Test script:** `detect-windows-arm.ts`

## Testing

**Workflow:** `.github/workflows/test-arm-detection.yml`

Tests both implementations on Windows ARM GitHub Actions runner:

1. **R x64 → ARM detection**
   - R reports `x86_64-w64-mingw32`
   - Detection function returns `TRUE`

2. **Deno x64 → ARM detection**
   - Deno reports `x86_64`
   - Detection function returns `true`

**Expected behavior:**

| Process | Standard Detection | IsWow64Process2 Detection |
|---------|-------------------|---------------------------|
| R x64 on ARM | `x86_64-w64-mingw32` | ✅ Windows ARM |
| R ARM64 on ARM | `aarch64-w64-mingw32` | ✅ Windows ARM |
| Deno x64 on ARM | `x86_64` | ✅ Windows ARM |
| R x64 on x64 | `x86_64-w64-mingw32` | ❌ Not ARM |

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

**Without IsWow64Process2:**
- ❌ x64 processes on ARM cannot detect they're on ARM
- ❌ PR #13790's detection won't work
- ❌ Users get generic errors, not ARM-specific guidance

**With IsWow64Process2:**
- ✅ x64 processes can detect Windows ARM
- ✅ PR #13790 can identify "x64 R on ARM Windows"
- ✅ Users get helpful error messages with ARM64 R download links

This is **essential** for the PR to work correctly.
