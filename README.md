# Quarto on Windows ARM Testing

This repository tests Quarto website rendering on Windows 11 ARM runners in GitHub Actions with different R configurations.

## Purpose

Demonstrate and verify the behavior of Quarto rendering with different R architectures on Windows ARM:

- **Quarto without R**: Works ✅
- **Quarto with R x64 (emulated)**: Does not work ❌
- **Quarto with R aarch64 (native ARM)**: Works ✅

Additionally, test with a special Quarto build from [PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790) that provides improved error messages for architecture mismatches.

## Test Scenarios

Five separate GitHub Actions workflows test different configurations:

### 1. No R ([build-no-r.yml](.github/workflows/build-no-r.yml))

Tests pure Quarto rendering without R dependencies.

- Renders only static content (index, about pages)
- No R installation required
- **Status**: ✅ Expected to work

### 2. R x64 - Emulated ([build-r-x64.yml](.github/workflows/build-r-x64.yml))

Tests Quarto with default R x86_64 (runs under emulation on ARM).

- Uses pre-installed R x64 from the runner
- Attempts to render R-dependent content
- **Status**: ❌ Expected to fail - R x64 emulation issues on Windows ARM

### 3. R aarch64 - Native ARM ([build-r-aarch64.yml](.github/workflows/build-r-aarch64.yml))

Tests Quarto with native ARM64 R installation.

- Installs R 4.5.0 aarch64 explicitly
- Installs RTools45 for ARM64
- Uses `QUARTO_R` environment variable to point to ARM R
- **Status**: ✅ Expected to work

### 4. R x64 with Artifact Quarto ([build-r-x64-artifact.yml](.github/workflows/build-r-x64-artifact.yml))

Tests Quarto artifact build from [PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790) with emulated R x64.

- Downloads Quarto build artifact from [GitHub Actions run #20233979482](https://github.com/quarto-dev/quarto-cli/actions/runs/20233979482)
- Uses pre-installed R x64 from the runner
- Attempts to render R-dependent content
- **Status**: ❌ Expected to fail with improved error messages

### 5. R aarch64 with Artifact Quarto ([build-r-aarch64-artifact.yml](.github/workflows/build-r-aarch64-artifact.yml))

Tests Quarto artifact build from [PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790) with native ARM64 R.

- Downloads Quarto build artifact from [GitHub Actions run #20233979482](https://github.com/quarto-dev/quarto-cli/actions/runs/20233979482)
- Installs R 4.5.0 aarch64 explicitly
- Installs RTools45 for ARM64
- Uses `QUARTO_R` environment variable to point to ARM R
- **Status**: ✅ Expected to work

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

## Workflow Status

Check the [Actions tab](../../actions) to see the latest workflow runs.

## Repository Structure

```
.
├── .github/workflows/
│   ├── build-no-r.yml                # Workflow without R
│   ├── build-r-x64.yml               # Workflow with R x64
│   ├── build-r-aarch64.yml           # Workflow with R ARM64
│   ├── build-r-x64-artifact.yml      # Workflow with R x64 and artifact Quarto
│   └── build-r-aarch64-artifact.yml  # Workflow with R ARM64 and artifact Quarto
├── _quarto.yml                        # Base Quarto configuration
├── _quarto-no-r.yml                  # Profile for no-R scenario
├── _quarto-r-x64.yml                 # Profile for R x64 scenario
├── _quarto-r-aarch64.yml             # Profile for R ARM64 scenario
├── _quarto-r-x64-artifact.yml        # Profile for R x64 with artifact Quarto
├── _quarto-r-aarch64-artifact.yml    # Profile for R ARM64 with artifact Quarto
├── index.qmd                          # Homepage (all profiles)
├── about.qmd                          # About page (all profiles)
├── r-analysis.qmd                    # R analysis demo (R profiles only)
└── r-plots.qmd                       # R visualization demo (R profiles only)
```

## Resources

- [Windows ARM runner documentation](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources)
- [R for Windows ARM](https://www.r-project.org/nosvn/winutf8/aarch64/R-4-signed/)
- [RTools45 for ARM](https://cran.r-project.org/bin/windows/Rtools/rtools45/files/)
- [Quarto Profiles documentation](https://quarto.org/docs/projects/profiles.html)
