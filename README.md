# Quarto on Windows ARM Testing

This repository tests Quarto website rendering on Windows 11 ARM runners in GitHub Actions with different R configurations.

## Purpose

Demonstrate and verify the behavior of Quarto rendering with different R architectures on Windows ARM:

- **Quarto without R**: Works ✅
- **Quarto with R x64 (emulated)**: Does not work ❌
- **Quarto with R aarch64 (native ARM)**: Works ✅

Additionally, test with a special Quarto build from [PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790) that provides improved error messages for architecture mismatches.

## Test Scenarios

Thirteen GitHub Actions workflows organized by purpose test different configurations.

### Build Workflows (5)

These workflows focus solely on Quarto rendering - they test whether Quarto can successfully render content with different R configurations.

#### 1. No R ([build-no-r.yml](.github/workflows/build-no-r.yml))

Tests pure Quarto rendering without R dependencies.

- Renders only static content (index, about pages)
- No R installation required
- **Status**: ✅ Expected to work

#### 2. R x64 - Emulated ([build-r-x64.yml](.github/workflows/build-r-x64.yml))

Tests Quarto rendering with default R x86_64 (runs under emulation on ARM).

- Uses pre-installed R x64 from the runner
- Renders R-dependent content
- **Status**: ❌ Expected to fail - R x64 emulation issues on Windows ARM

#### 3. R aarch64 - Native ARM ([build-r-aarch64.yml](.github/workflows/build-r-aarch64.yml))

Tests Quarto rendering with native ARM64 R installation.

- Installs R 4.5.0 aarch64 explicitly
- Installs RTools45 for ARM64
- Uses `QUARTO_R` environment variable to point to ARM R
- **Status**: ✅ Expected to work

#### 4. R x64 with Artifact Quarto ([build-r-x64-artifact.yml](.github/workflows/build-r-x64-artifact.yml))

Tests Quarto artifact from [PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790) rendering with emulated R x64.

- Downloads Quarto build artifact from [GitHub Actions run #20273691338](https://github.com/quarto-dev/quarto-cli/actions/runs/20273691338)
- Uses pre-installed R x64 from the runner
- Renders R-dependent content
- **Status**: ❌ Expected to fail with improved error messages

#### 5. R aarch64 with Artifact Quarto ([build-r-aarch64-artifact.yml](.github/workflows/build-r-aarch64-artifact.yml))

Tests Quarto artifact build from [PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790) with native ARM64 R.

- Downloads Quarto build artifact from [GitHub Actions run #20273691338](https://github.com/quarto-dev/quarto-cli/actions/runs/20273691338)
- Installs R 4.5.0 aarch64 explicitly
- Installs RTools45 for ARM64
- Uses `QUARTO_R` environment variable to point to ARM R
- **Status**: ✅ Expected to work

### Test Workflows (8)

These workflows perform focused investigation of specific technical questions about R x64 compatibility.

#### 6. Direct R Execution ([test-subprocess-direct-rscript.yml](.github/workflows/test-subprocess-direct-rscript.yml))

Tests R x64 execution directly without any subprocess layer.

- Runs R scripts directly with Rscript (PowerShell → Rscript)
- Tests simple scripts, knitr-only, rmarkdown-only, and both packages
- **Purpose**: Isolate whether issues are in R x64 itself vs. subprocess spawning
- **Expected**: rmarkdown-loading scripts fail due to R x64/ARM incompatibility

#### 7. Deno Subprocess Spawning ([test-subprocess-deno.yml](.github/workflows/test-subprocess-deno.yml))

Tests Deno subprocess spawning behavior with R x64.

- Tests Deno spawning Rscript with different R scripts
- Tests 5 different workaround approaches
- **Purpose**: Isolate Deno-specific subprocess spawning issues
- **Expected**: Fails when loading rmarkdown package

#### 8. Other Runtime Subprocess Spawning ([test-subprocess-runtimes.yml](.github/workflows/test-subprocess-runtimes.yml))

Tests whether subprocess spawning issues affect other runtimes.

- Node.js spawning Rscript subprocesses
- Python spawning Rscript subprocesses
- **Purpose**: Determine if issue is Deno-specific or affects multiple runtimes
- **Expected**: All runtimes show same failure pattern with rmarkdown

#### 9. Sequential Execution Consistency ([test-sequential-consistency.yml](.github/workflows/test-sequential-consistency.yml))

**Critical test for sequential execution reliability** - Tests whether running R scripts multiple times in succession produces consistent results.

- Runs same R script 5× sequentially
- Alternates between 3 different R scripts
- Tests Deno spawning same script 5× sequentially
- Tests Quarto rendering same file 3× sequentially
- **Purpose**: Catch state corruption bugs where first execution works but subsequent executions fail
- **Expected**: Exit codes should be consistent across all iterations

#### 10. R Package Loading ([test-r-package-loading.yml](.github/workflows/test-r-package-loading.yml))

Tests R package loading in isolation.

- Direct PowerShell execution only (no subprocess layer)
- Tests simple script, knitr-only, rmarkdown-only, both packages
- **Purpose**: Primary direct execution test baseline
- **Expected**: Isolates package-specific failures

#### 11. Deno Version Comparison ([test-deno-versions-isolated.yml](.github/workflows/test-deno-versions-isolated.yml))

Tests multiple Deno versions with proper per-job isolation.

- Matrix: 4 Deno versions (2.4.5, 2.5.0, 2.6.0, latest) × 3 R scripts = 12 jobs
- Each matrix job installs R packages independently
- **Purpose**: Determine if newer Deno versions fix the issue
- **Expected**: All versions show identical behavior (version-independent issue)

#### 12. ARM Detection ([test-arm-detection.yml](.github/workflows/test-arm-detection.yml))

Tests Windows ARM detection from x64 processes.

- Demonstrates that x64 processes report arch as "x86_64" not "ARM"
- Tests Deno FFI calling IsWow64Process2 Windows API
- Tests R FFI limitations with Windows API
- **Purpose**: Validate PR #13790's ARM detection approach
- **Result**: Deno FFI works successfully, R FFI has limitations

## Implementation Details

### Quarto Profiles

Five profiles control which content gets rendered:

- **`no-r`**: Renders only `index.qmd` and `about.qmd`
- **`r-x64`**: Renders all content including R-dependent pages
- **`r-aarch64`**: Renders all content including R-dependent pages
- **`r-x64-artifact`**: Renders all content with artifact Quarto and R x64
- **`r-aarch64-artifact`**: Renders all content with artifact Quarto and R aarch64

Profile configurations are in `_quarto-*.yml` files.

### R Architecture Detection

The R-dependent pages (`r-analysis.qmd`, `r-plots.qmd`) include code to display:

```r
R.version$platform
R.version$version.string
```

This shows which R architecture is being used:
- `x86_64-w64-mingw32` = x64 R (emulated)
- `aarch64-w64-mingw32` = ARM64 R (native)

### Key Configuration

**R aarch64 workflow** uses:
- R installation path: `C:\Program Files\R-aarch64\R-4.5.0\`
- `QUARTO_R` environment variable pointing to `Rscript.exe`
- RTools45 ARM64 version

## Key Findings

### R x64 Emulation Works, But Not Through Deno

Testing reveals that **R x64 runs successfully on Windows ARM when called directly**, but **fails when called through Deno** (Quarto's JavaScript runtime):

- **Direct execution** (PowerShell → Rscript): ✅ Exit code 0, valid YAML output
- **Through Quarto/Deno**: ❌ Exit code -1073741569 (STATUS_NOT_SUPPORTED)

This means:
1. R x64 emulation itself works on Windows ARM
2. The issue is specific to **Deno's subprocess spawning** on Windows ARM
3. Quarto can detect and report this error (PR #13790), but the root cause is in Deno

**Evidence**: See [workflow run #20234173159](https://github.com/cderv/quarto-windows-arm/actions/runs/20234173159) where the same `knitr.R` script succeeds when called directly but fails during `quarto check`.

For detailed technical analysis, see [FINDINGS.md](FINDINGS.md).

## Workflow Status

Check the [Actions tab](../../actions) to see the latest workflow runs.

## Repository Structure

```
.
├── .github/workflows/
│   ├── build-no-r.yml                        # Build: Quarto without R
│   ├── build-r-x64.yml                       # Build: Quarto with R x64
│   ├── build-r-aarch64.yml                   # Build: Quarto with R ARM64
│   ├── build-r-x64-artifact.yml              # Build: Artifact Quarto with R x64
│   ├── build-r-aarch64-artifact.yml          # Build: Artifact Quarto with R ARM64
│   ├── test-subprocess-direct-rscript.yml    # Test: Direct R execution
│   ├── test-subprocess-deno.yml              # Test: Deno subprocess spawning
│   ├── test-subprocess-runtimes.yml          # Test: Node.js/Python subprocess spawning
│   ├── test-sequential-consistency.yml       # Test: Sequential execution consistency
│   ├── test-r-package-loading.yml            # Test: R package loading
│   ├── test-deno-versions-isolated.yml       # Test: Deno version comparison
│   └── test-arm-detection.yml                # Test: ARM Windows detection
├── _quarto.yml                                # Base Quarto configuration
├── _quarto-no-r.yml                  # Profile for no-R scenario
├── _quarto-r-x64.yml                 # Profile for R x64 scenario
├── _quarto-r-aarch64.yml             # Profile for R ARM64 scenario
├── _quarto-r-x64-artifact.yml        # Profile for R x64 with artifact Quarto
├── _quarto-r-aarch64-artifact.yml    # Profile for R ARM64 with artifact Quarto
├── index.qmd                          # Homepage (all profiles)
├── about.qmd                          # About page (all profiles)
├── r-analysis.qmd                    # R analysis demo (R profiles only)
├── r-plots.qmd                       # R visualization demo (R profiles only)
└── FINDINGS.md                       # Technical analysis of R x64/Deno issue
```

## Resources

- [Windows ARM runner documentation](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources)
- [R for Windows ARM](https://www.r-project.org/nosvn/winutf8/aarch64/R-4-signed/)
- [RTools45 for ARM](https://cran.r-project.org/bin/windows/Rtools/rtools45/files/)
- [Quarto Profiles documentation](https://quarto.org/docs/projects/profiles.html)
