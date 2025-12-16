# Technical Findings: R x64 on Windows ARM

## Executive Summary

R x64 (emulated via WOW64) on Windows 11 ARM crashes when loading the **rmarkdown package**, regardless of how R is invoked. This is **NOT a subprocess spawning issue** or Quarto/Deno problem - it's a fundamental incompatibility between the rmarkdown package and R x64 emulation on Windows ARM.

Scripts complete execution and produce valid output, but crash during process termination with exit code `-1073741569` (STATUS_NOT_SUPPORTED).

## Root Cause

**Specific issue:** The `rmarkdown` R package cannot properly unload/terminate when running under R x64 emulation on Windows ARM.

**Affected scenarios:**
- ❌ Any R script that loads `library(rmarkdown)` on R x64 Windows ARM
- ❌ Quarto's `knitr.R` capabilities check (loads both knitr and rmarkdown)

**Unaffected scenarios:**
- ✅ Simple R scripts without packages
- ✅ R scripts loading only `library(knitr)`
- ✅ R ARM64 (native) with any packages

## Comprehensive Test Results

### Test Matrix

| Test Scenario | PowerShell→R | Deno→R | Node→R | Python→R | Result |
|--------------|--------------|--------|--------|----------|--------|
| Simple R script (no packages) | ✅ 0 | ✅ 0 | - | - | SUCCESS |
| Load `knitr` only | ✅ 0 | ✅ 0 | - | - | SUCCESS |
| Load `rmarkdown` only | ❌ -1073741569 | ❌ -1073741569 | ❌ 3221225727 | ❌ 3221225727 | **FAILURE** |
| Load both knitr + rmarkdown | ❌ -1073741569 | ❌ -1073741569 | ❌ 3221225727 | ❌ 3221225727 | **FAILURE** |
| Quarto knitr.R (loads both) | ❌ -1073741569 | ❌ -1073741569 | - | - | **FAILURE** |

**Exit codes:**
- `0` = Success
- `-1073741569` (0xC00000BB) = STATUS_NOT_SUPPORTED (Windows error)
- `3221225727` (0xBFFF00FF) = Generic subprocess crash

### Key Findings

1. **rmarkdown is the culprit:** Scripts loading only `knitr` succeed; scripts loading `rmarkdown` (with or without knitr) fail
2. **Universal failure pattern:** The crash occurs across ALL invocation methods (PowerShell, Deno, Node.js, Python)
3. **NOT subprocess-related:** Direct PowerShell execution also fails, proving it's not about subprocess spawning
4. **NOT Deno-specific:** All 4 tested Deno versions (2.4.5, 2.5.0, 2.6.0, latest) show identical behavior
5. **Termination issue:** Scripts complete execution and produce valid output before crashing during cleanup

## Evidence

All tests run on GitHub Actions `windows-11-arm` runners with R x64 4.5.1.

### Test 1: R Package Loading (Direct Execution)

**Workflow:** [test-r-package-loading.yml](https://github.com/cderv/quarto-windows-arm/actions/runs/20266226901)

**Note:** This is now the primary direct execution test baseline. See also [test-subprocess-direct-rscript.yml](.github/workflows/test-subprocess-direct-rscript.yml) for the updated comprehensive direct execution tests.

Results from direct PowerShell → Rscript execution:
- ✅ Simple script (test-simple.R): SUCCESS (exit 0)
- ✅ knitr only (test-knitr.R): SUCCESS (exit 0)
- ❌ rmarkdown only (test-rmarkdown.R): FAILURE (exit -1073741569)
- ❌ Both packages (test-both.R): FAILURE (exit -1073741569)

**Conclusion:** The issue occurs even without subprocess spawning - it's a direct R x64 emulation problem.

### Test 2: Deno Version Comparison

**Workflow:** [test-deno-versions-isolated.yml](https://github.com/cderv/quarto-windows-arm/actions/runs/20266226930) (renamed from test-deno-versions.yml)

**Note:** This workflow was restructured to install R packages independently per matrix job (12 jobs total) for proper test isolation.

Results from Deno x64 → Rscript x64 execution across 4 versions:

| Deno Version | Simple | knitr only | Both packages |
|--------------|--------|------------|---------------|
| 2.4.5 (Quarto bundled) | ✅ SUCCESS | ✅ SUCCESS | ❌ FAILURE |
| 2.5.0 | ✅ SUCCESS | ✅ SUCCESS | ❌ FAILURE |
| 2.6.0 | ✅ SUCCESS | ✅ SUCCESS | ❌ FAILURE |
| latest (2.6.1) | ✅ SUCCESS | ✅ SUCCESS | ❌ FAILURE |

**Conclusion:** Identical behavior across all Deno versions. The issue is NOT Deno version-specific.

### Test 3: Cross-Runtime Comparison

**Original workflow:** [build-r-x64-artifact.yml](https://github.com/cderv/quarto-windows-arm/actions/runs/20265656553)

**Note:** This evidence is now split across dedicated test workflows:
- Direct Rscript execution: [test-subprocess-direct-rscript.yml](.github/workflows/test-subprocess-direct-rscript.yml)
- Deno subprocess spawning: [test-subprocess-deno.yml](.github/workflows/test-subprocess-deno.yml)
- Node.js/Python subprocess spawning: [test-subprocess-runtimes.yml](.github/workflows/test-subprocess-runtimes.yml)

Results from Node.js ARM64 and Python ARM64 spawning R x64:
- ❌ Node.js → Rscript → knitr.R: FAILURE (exit 3221225727)
- ❌ Python → Rscript → knitr.R: FAILURE (exit 3221225727)
- ❌ Deno x64 → Rscript → knitr.R: FAILURE (exit -1073741569)
- ✅ PowerShell → Rscript (simple): SUCCESS (exit 0)

**Conclusion:** All subprocess mechanisms fail with rmarkdown, but simple scripts work everywhere.

## Technical Analysis

### Error Code: -1073741569 (0xC00000BB)

This is Windows NTSTATUS code `STATUS_NOT_SUPPORTED`:
> "The request is not supported."

This error occurs when Windows detects an unsupported operation during process termination. The rmarkdown package likely performs cleanup operations that are incompatible with WOW64 (Windows-on-Windows 64-bit) emulation.

### Why Scripts Produce Output Before Crashing

The R script executes successfully:
1. R starts under x64 emulation (WOW64)
2. Libraries load successfully
3. Script code executes
4. Output is produced correctly
5. **Script completes**
6. ❌ **Crash during package unload/cleanup**

This "partial success" pattern explains why Quarto receives valid YAML output but sees a failure exit code.

### Why rmarkdown Fails But knitr Succeeds

The `rmarkdown` package has more complex dependencies and likely performs operations during package unloading that are incompatible with x64 emulation on ARM. Possible causes:

- **Native code dependencies:** rmarkdown may use compiled libraries that don't cleanly terminate under WOW64
- **System integration:** rmarkdown integrates with system tools (Pandoc) in ways that don't work under emulation
- **Resource cleanup:** Package cleanup code may use Windows APIs that aren't properly supported in WOW64

## Windows ARM Detection Tests

### Critical Finding: Architecture Detection Limitation

**Test workflow:** [test-arm-detection.yml](https://github.com/cderv/quarto-windows-arm/actions/runs/20272725035)

x64 processes running under WOW64 emulation on Windows ARM report their architecture as `x86_64`, **not** ARM. This breaks simple architecture checks like `Deno.build.arch` or `R.version[['platform']]`.

**Test Results:**

| Runtime | Reported Arch | Detected ARM via IsWow64Process2 | Status |
|---------|--------------|----------------------------------|--------|
| Deno x64 2.4.5 | `x86_64` | ✅ TRUE | **SUCCESS** |
| R x64 4.5.1 | `x86_64-w64-mingw32` | ❌ FALSE | **FAILED** |

#### Deno: Successful Detection

Deno x64 can successfully detect it's running on ARM Windows using the `IsWow64Process2` Windows API via FFI:

```typescript
// Using Deno.dlopen() to call IsWow64Process2
const result = kernel32.symbols.IsWow64Process2(
  hProcess,
  Deno.UnsafePointer.of(processMachineBuffer),
  Deno.UnsafePointer.of(nativeMachineBuffer)
);
// Returns: nativeMachine == 0xAA64 (IMAGE_FILE_MACHINE_ARM64)
```

**Result:** Deno correctly identifies ARM Windows even though `Deno.build.arch` reports `x86_64`.

#### R: Cannot Self-Detect

R x64 cannot reliably self-detect it's running on ARM Windows due to FFI limitations:

```r
# R's .Call() FFI is designed for R's C API, not arbitrary Windows API calls
res <- .Call(iswow64process2, GetCurrentProcess(), processMachine, nativeMachine)
# Does not properly handle output pointer parameters
```

**Result:** R x64 reports `FALSE` when it should detect ARM. The issue is that:
- R's `.Call()` is designed for R's internal C API, not arbitrary DLL calls
- Windows API functions with pointer output parameters don't work correctly
- Proper detection would require a compiled C extension or specialized package

### Implications for PR #13790

**Quarto must use `IsWow64Process2` API, not `Deno.build.arch`:**

1. ✅ Deno FFI can successfully call `IsWow64Process2` and detect ARM
2. ❌ Simple checks like `Deno.build.arch` will report `x86_64` (wrong)
3. ❌ R scripts cannot self-detect ARM without compiled extensions
4. ✅ Quarto (via Deno) must detect ARM and inform the user

**Implementation requirement:** PR #13790 needs the `IsWow64Process2` Windows API implementation documented in [ARM-DETECTION.md](ARM-DETECTION.md), not architecture string checks.

## Implications

### For Quarto Users

**R x64 is not viable with Quarto on Windows ARM** because:
- Quarto's `knitr.R` capabilities check loads both knitr and rmarkdown
- This check fails every time, blocking all R-based rendering
- Workarounds are not possible - the issue is in R package internals

**Solution:** Install native ARM64 R:
- Download: [R for Windows ARM](https://www.r-project.org/nosvn/winutf8/aarch64/R-4-signed/)
- RTools: [RTools45 ARM64](https://cran.r-project.org/bin/windows/Rtools/rtools45/files/)
- Set `QUARTO_R` environment variable to ARM64 Rscript path

### For Quarto Development

**PR #13790 is the correct approach:**
- ✅ Detect x64 R on ARM Windows by checking `platform` field
- ✅ Parse YAML output despite non-zero exit code (output is valid)
- ✅ Provide clear error message directing users to ARM64 R
- ✅ This is not a bug to fix - it's a configuration to detect and report

The improved error handling correctly identifies this unsupported configuration.

### For R Development

This finding may warrant investigation by the R Core or rmarkdown maintainers:
- rmarkdown package termination fails under Windows ARM x64 emulation
- Error occurs consistently across all tested invocation methods
- May affect other R packages with similar cleanup patterns

## Why Initial Analysis Was Incorrect

Initial hypothesis was "Deno subprocess spawning issue" because:
- Quarto uses Deno, and Quarto's R check was failing
- Direct R script execution wasn't initially tested for comparison
- Simple test scripts (that don't load rmarkdown) worked through Deno

Systematic testing revealed:
1. **Direct PowerShell execution also fails** with rmarkdown → Not subprocess-specific
2. **Simple scripts work through Deno** → Not Deno-specific
3. **knitr alone works fine** → Not package loading in general
4. **All runtimes show same pattern** → Not runtime-specific

The root cause is specifically the **rmarkdown package on R x64 Windows ARM**, not subprocess mechanisms.

## Workaround Attempts

Multiple workaround approaches were tested and all failed:

| Approach | Result | Reason |
|----------|--------|--------|
| PowerShell intermediary | ❌ Failed | rmarkdown still crashes |
| cmd.exe intermediary | ❌ Failed | rmarkdown still crashes |
| Different Deno versions | ❌ Failed | Version-independent |
| Inherit stdio mode | ❌ Failed | Crash is in package cleanup |
| spawn() vs output() | ❌ Failed | API choice irrelevant |

**No workaround is possible** because the crash occurs during R package cleanup, which is beyond the control of the calling process.

## Recommendations

### For Users

**Use native ARM64 R with Quarto on Windows ARM:**
1. Uninstall R x64 (if present)
2. Install R ARM64 from https://www.r-project.org/nosvn/winutf8/aarch64/R-4-signed/
3. Install RTools45 ARM64 from https://cran.r-project.org/bin/windows/Rtools/rtools45/files/
4. Set `QUARTO_R` environment variable (if needed)

**Verify installation:**
```powershell
Rscript -e "R.version[['platform']]"
# Should show: aarch64-w64-mingw32
```

### For Developers

**When debugging R issues on Windows ARM:**
1. Check R platform first: `Rscript -e "R.version[['platform']]"`
2. Test with simple R scripts before investigating Quarto/Deno
3. Test with and without package loading to isolate package-specific issues
4. Remember: x64 R crashes are expected behavior, not bugs to fix

### For Future Investigation

**Areas worth exploring (by R/rmarkdown maintainers):**
- What specific cleanup operation in rmarkdown triggers STATUS_NOT_SUPPORTED?
- Do other R packages with complex dependencies show similar issues?
- Can rmarkdown's termination code be made WOW64-compatible?

## Related Work

- [Quarto PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790): Detect and warn about x64 R on Windows ARM
- [This test repository](https://github.com/cderv/quarto-windows-arm): Comprehensive testing demonstrating the issue

## Test Scripts

The repository contains systematic test scripts:

**Individual test scripts:**
- `test-simple.R`: Baseline (no packages)
- `test-knitr.R`: Load knitr only
- `test-rmarkdown.R`: Load rmarkdown only
- `test-both.R`: Load both (mimics Quarto's knitr.R)

**Test execution scripts:**
- `test-deno-rscript.ts`: Deno subprocess test harness
- `test-node-rscript.js`: Node.js subprocess test harness
- `test-python-rscript.py`: Python subprocess test harness

**Build Workflows** (rendering only):
- `.github/workflows/build-no-r.yml`: Pure Quarto without R
- `.github/workflows/build-r-x64.yml`: Quarto with R x64
- `.github/workflows/build-r-aarch64.yml`: Quarto with R ARM64
- `.github/workflows/build-r-x64-artifact.yml`: Artifact Quarto with R x64
- `.github/workflows/build-r-aarch64-artifact.yml`: Artifact Quarto with R ARM64

**Test Workflows** (focused investigation):
- `.github/workflows/test-subprocess-direct-rscript.yml`: Direct R execution (no subprocess)
- `.github/workflows/test-subprocess-deno.yml`: Deno subprocess spawning tests
- `.github/workflows/test-subprocess-runtimes.yml`: Node.js/Python subprocess tests
- `.github/workflows/test-sequential-consistency.yml`: Sequential execution consistency tests
- `.github/workflows/test-r-package-loading.yml`: R package loading baseline
- `.github/workflows/test-deno-versions-isolated.yml`: Deno version comparison (with per-job R installation)
- `.github/workflows/test-arm-detection.yml`: ARM Windows detection tests

## Conclusion

The root cause is a **fundamental incompatibility between the rmarkdown R package and x64 emulation on Windows ARM**. This is not a Quarto bug, Deno bug, or subprocess issue. R x64 cannot be used with Quarto on Windows ARM because Quarto's capabilities check loads rmarkdown, which consistently crashes during termination.

**The only solution is to use native ARM64 R.**

Quarto's error detection and messaging in PR #13790 appropriately handles this unsupported configuration.
