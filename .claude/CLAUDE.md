# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a comprehensive testing suite for Quarto on Windows 11 ARM that:

- Tests Quarto website rendering with different R configurations
- Demonstrates R x64 vs R ARM64 compatibility on Windows ARM
- Investigates subprocess spawning behavior across different runtimes
- Supports Quarto PR #13790 (improved ARM detection and error messages)

**Key Finding:** R x64 (emulated) with rmarkdown package crashes on Windows ARM due to package cleanup incompatibility with WOW64 emulation. The solution is to use native R ARM64.

## Workflow Organization

13 GitHub Actions workflows organized into two categories:

### Build Workflows (5)
Test Quarto rendering with different R configurations:

- `build-no-r.yml` - Pure Quarto without R dependencies (✅ expected to work)
- `build-r-x64.yml` - Quarto with R x64 emulated (❌ expected to fail)
- `build-r-aarch64.yml` - Quarto with R ARM64 native (✅ expected to work)
- `build-r-x64-artifact.yml` - PR #13790 Quarto artifact with R x64
- `build-r-aarch64-artifact.yml` - PR #13790 Quarto artifact with R ARM64

### Test Workflows (8)
Focused technical investigations:

- `test-subprocess-direct-rscript.yml` - Direct R execution baseline (no subprocess layer)
- `test-subprocess-deno.yml` - Deno subprocess spawning tests with 5 workaround approaches
- `test-subprocess-runtimes.yml` - Node.js and Python subprocess spawning comparison
- `test-sequential-consistency.yml` - **Critical test** for sequential execution reliability
- `test-r-package-loading.yml` - R package loading in isolation
- `test-deno-versions-isolated.yml` - Deno version comparison (12 isolated jobs)
- `test-arm-detection.yml` - ARM Windows detection using IsWow64Process2 API

## Testing Commands

### View Workflow Status
```bash
# List all workflow runs
gh run list --repo cderv/quarto-windows-arm

# View specific run with logs
gh run view <run-id> --log

# View latest run for a specific workflow
gh run list --workflow="Build Website (R aarch64)" --limit 1
```

### Run Test Scripts Locally (Windows ARM only)
```bash
# R test scripts - test different package loading scenarios
Rscript test-simple.R          # No packages (baseline)
Rscript test-knitr.R           # Load knitr only (works)
Rscript test-rmarkdown.R       # Load rmarkdown only (fails)
Rscript test-both.R            # Load both (fails, mimics Quarto)

# Deno subprocess tests
deno run --allow-run test-deno-rscript.ts
deno run --allow-run test-deno-rscript-workarounds.ts

# ARM detection tests
deno run --allow-ffi detect-windows-arm.ts    # ✅ Works
Rscript detect-windows-arm.R                  # ❌ Fails (R FFI limitation)

# Other runtime tests
node test-node-rscript.js
python test-python-rscript.py
```

### Render with Quarto Profiles
```bash
quarto render --profile no-r          # Static content only
quarto render --profile r-x64         # With R x64 (emulated, will fail)
quarto render --profile r-aarch64     # With R ARM64 (native, will work)
```

## Test Script Organization

### R Test Scripts
Test different package loading scenarios to isolate the rmarkdown crash:

- `test-simple.R` - Baseline (no packages) ✅
- `test-knitr.R` - Load knitr only ✅
- `test-rmarkdown.R` - Load rmarkdown only ❌
- `test-both.R` - Load both knitr and rmarkdown ❌ (mimics Quarto's knitr.R)

### Subprocess Test Harnesses
Test subprocess spawning across different runtimes:

- `test-deno-rscript.ts` - Deno spawning Rscript
- `test-deno-rscript-workarounds.ts` - Tests 5 workaround approaches (all fail)
- `test-node-rscript.js` - Node.js spawning Rscript
- `test-python-rscript.py` - Python spawning Rscript

### ARM Detection Implementations
Test Windows ARM detection from x64 processes:

- `detect-windows-arm.ts` - Deno FFI calling IsWow64Process2 ✅ (works correctly)
- `detect-windows-arm.R` - R FFI attempting IsWow64Process2 ❌ (fails due to R FFI limitations with pointer parameters)

## Quarto Profiles

Five profiles control which content gets rendered (configurations in `_quarto-*.yml` files):

- **`no-r`** - Static pages only (index.qmd, about.qmd)
- **`r-x64`** - All pages including R-dependent content with R x64
- **`r-aarch64`** - All pages including R-dependent content with R ARM64
- **`r-x64-artifact`** - All pages with PR #13790 Quarto artifact and R x64
- **`r-aarch64-artifact`** - All pages with PR #13790 Quarto artifact and R ARM64

R-dependent pages (r-analysis.qmd, r-plots.qmd) display R.version information to verify architecture.

## R ARM64 Installation Pattern

Standard pattern used in ARM64 workflows:

```powershell
# Install R ARM64
$url = "https://www.r-project.org/nosvn/winutf8/aarch64/R-4-signed/R-4.5.0-aarch64.exe"
Invoke-WebRequest -Uri $url -OutFile R-4.5.0-aarch64.exe -UseBasicParsing -UserAgent "NativeHost"
Start-Process -FilePath R-4.5.0-aarch64.exe -ArgumentList "/install /norestart /verysilent /SUPPRESSMSGBOXES" -NoNewWindow -Wait

# Install RTools45 ARM64
$url = "https://cran.r-project.org/bin/windows/Rtools/rtools45/files/rtools45-aarch64-6691-6492.exe"
Invoke-WebRequest -Uri $url -OutFile rtools45-aarch64-6691-6492.exe -UseBasicParsing -UserAgent "NativeHost"
Start-Process -FilePath rtools45-aarch64-6691-6492.exe -ArgumentList "/install /norestart /verysilent /SUPPRESSMSGBOXES" -NoNewWindow -Wait

# Set QUARTO_R environment variable
echo "QUARTO_R=C:\Program Files\R-aarch64\R-4.5.0\bin\Rscript.exe" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append

# Verify installation
$rscript = "C:\Program Files\R-aarch64\R-4.5.0\bin\Rscript.exe"
& $rscript -e "cat('Platform:', R.version[['platform']], '\n')"  # Should show: aarch64-w64-mingw32
```

## Architecture Detection

**Critical issue for PR #13790:** Standard architecture detection fails from x64 processes running under WOW64 emulation on ARM Windows.

### The Problem
- `Deno.build.arch` returns `"x86_64"` (not `"aarch64"`)
- `R.version[['platform']]` returns `"x86_64-w64-mingw32"` (not `"aarch64-w64-mingw32"`)
- Neither can detect they're running on ARM Windows using standard methods

### The Solution
Use Windows API `IsWow64Process2` which returns the native machine architecture even from emulated processes:

```typescript
// Deno implementation (works ✅)
function isWindowsArm(): boolean {
  if (Deno.build.os !== "windows") return false;

  const kernel32 = Deno.dlopen("kernel32.dll", {
    IsWow64Process2: { parameters: ["pointer", "pointer", "pointer"], result: "i32" },
    GetCurrentProcess: { parameters: [], result: "pointer" },
  });

  const hProcess = kernel32.symbols.GetCurrentProcess();
  const processMachineBuffer = new Uint16Array(1);
  const nativeMachineBuffer = new Uint16Array(1);

  const result = kernel32.symbols.IsWow64Process2(
    hProcess,
    Deno.UnsafePointer.of(processMachineBuffer),
    Deno.UnsafePointer.of(nativeMachineBuffer)
  );

  kernel32.close();
  if (result === 0) return false;

  const IMAGE_FILE_MACHINE_ARM64 = 0xAA64;
  return nativeMachineBuffer[0] === IMAGE_FILE_MACHINE_ARM64;
}
```

**Key points:**
- Requires `--allow-ffi` permission for Deno
- Deno implementation works correctly ✅
- R implementation fails ❌ (R's .Call() FFI cannot handle Windows API pointer parameters)
- See `ARM-DETECTION.md` for complete implementation details

## Testing Strategy

### Sequential Consistency Testing
**Critical workflow:** `test-sequential-consistency.yml`

This test catches state corruption bugs where the first execution works but subsequent executions fail:

- Runs knitr script 5× sequentially (tests passing script consistency)
- Runs rmarkdown script 5× sequentially (tests failing script consistency)
- Alternates between 3 different R scripts (tests cross-script state)
- Tests Deno spawning same script 5× sequentially
- Tests Quarto rendering same file 3× sequentially

**Purpose:** Exit codes should be consistent across all iterations. Inconsistency indicates state corruption.

### Workflow Isolation
**Pattern from:** `test-deno-versions-isolated.yml`

Each matrix job installs R packages independently (12 total jobs: 4 Deno versions × 3 R scripts):

- Prevents state leakage between test configurations
- Ensures each test starts with clean state
- Critical for reliable cross-version testing

## Key Technical Findings

### Root Cause: rmarkdown Package Termination Issue
- R x64 works when called directly from PowerShell for simple scripts ✅
- R x64 crashes when loading rmarkdown package (exit code -1073741569 = STATUS_NOT_SUPPORTED) ❌
- Crash occurs during package cleanup/termination, **after** script completes and produces valid output
- Issue occurs across ALL invocation methods (PowerShell, Deno, Node.js, Python)
- This is NOT a subprocess spawning issue or Quarto/Deno bug
- Root cause: rmarkdown package cleanup operations incompatible with WOW64 emulation

### Affected vs Unaffected Scenarios
**Affected (fails):**
- ❌ Any R script loading `library(rmarkdown)` on R x64/Windows ARM
- ❌ Quarto's knitr.R capabilities check (loads both knitr and rmarkdown)

**Unaffected (works):**
- ✅ Simple R scripts without packages
- ✅ R scripts loading only `library(knitr)`
- ✅ All scenarios with R ARM64 (native)

### Solution
**Use native R ARM64 on Windows ARM.**

There is no workaround. Quarto PR #13790 correctly detects this unsupported configuration and provides helpful error messages directing users to R ARM64.

## Important Documentation

- `README.md` - Overview, test scenarios, repository structure
- `FINDINGS.md` - Comprehensive technical analysis of R x64/ARM incompatibility
- `ARM-DETECTION.md` - Windows ARM detection implementation details and test results
- `NEXT-INVESTIGATION.md` - Future investigation areas (if exists)

## Related Work

- [Quarto PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790) - Detect and warn about x64 R on Windows ARM
- [Test repository](https://github.com/cderv/quarto-windows-arm) - This comprehensive testing suite
