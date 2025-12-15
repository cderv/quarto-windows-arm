# Technical Findings: R x64 on Windows ARM

## Summary

R x64 (emulated) runs successfully on Windows 11 ARM when called directly from PowerShell, but fails when called through Deno's subprocess mechanism. This means the issue is not with R emulation itself, but with how Deno spawns processes on Windows ARM.

## Background

Quarto uses Deno as its JavaScript runtime. When Quarto needs to check R capabilities or execute R code, it spawns Rscript as a subprocess through Deno's process APIs. On Windows ARM with x64 R, this subprocess creation fails even though R x64 can run successfully under emulation.

## Testing Methodology

We created a test that runs the same R script (`share/capabilities/knitr.R`) in two different contexts:

1. **Direct execution**: PowerShell → Rscript
2. **Through Quarto**: PowerShell → Quarto → Deno → Rscript

Both tests use:
- Same Windows 11 ARM runner (GitHub Actions `windows-11-arm`)
- Same R x64 installation (pre-installed on runner)
- Same capabilities script from Quarto installation
- Same `knitr` and `rmarkdown` packages

## Results

### Test 1: Direct Rscript Execution

Workflow step in `.github/workflows/build-r-x64-artifact.yml`:

```yaml
- name: Test R x64 capabilities directly (outside Quarto/Deno)
  continue-on-error: true
  run: |
    $quartoPath = Split-Path -Parent (Split-Path -Parent (Get-Command quarto).Source)
    $capabilitiesScript = Join-Path $quartoPath "share\capabilities\knitr.R"
    $output = Rscript $capabilitiesScript 2>&1
    $exitCode = $LASTEXITCODE
```

**Result**: ✅ Success
- Exit code: `0`
- Output: Valid YAML with complete R version and capabilities information

```yaml
--- YAML_START ---
versionMajor: 4
versionMinor: 5
versionPatch: 1
home: C:/PROGRA~2/R/R-45~1.1
libPaths:
  - "C:/Program Files (x86)/R/R-4.5.1/library"
platform: x86_64-w64-mingw32
packages:
  knitr: "1.50"
  rmarkdown: "2.30"
--- YAML_END ---
```

### Test 2: Quarto Check (Deno Subprocess)

Same workflow, subsequent step:

```yaml
- name: Verify Quarto setup
  continue-on-error: true
  run: quarto check --log-level=debug
```

**Result**: ❌ Failure
- Exit code: `-1073741569` (hex: `0xC00000BB`)
- Windows error: `STATUS_NOT_SUPPORTED`
- Quarto error: "Problem with results of knitr capabilities check"

Log excerpt:

```
[execProcess] C:\Program Files (x86)\R\R-4.5.1\bin\x64\Rscript.exe C:\a\_temp\quarto\share\capabilities\knitr.R
[execProcess] Success: false, code: -1073741569

++ Problem with results of knitr capabilities check.
    Return Code: -1073741569 (success is false)
    with stdout from R:
--- YAML_START ---
```

Note that the script produces valid YAML output before crashing, indicating partial execution success.

### Test 3: Direct Deno Subprocess (Verification)

To verify the hypothesis that Deno's subprocess spawning is the root cause, we added a test that calls Rscript through Deno directly, bypassing Quarto entirely.

Test script (`test-deno-rscript.ts`):

```typescript
const command = new Deno.Command(rscriptPath, {
  args: [capabilitiesScript],
  stdout: "piped",
  stderr: "piped",
});

const { code, stdout, stderr } = await command.output();
```

**Result**: ❌ Failure
- Exit code: `-1073741569` (same as Quarto)
- Output: Valid YAML with complete R capabilities before crash

Log excerpt from [workflow run #20235400009](https://github.com/cderv/quarto-windows-arm/actions/runs/20235400009/job/58088650203):

```
Testing Deno subprocess spawning of Rscript...
Rscript: C:\Program Files (x86)\R\R-4.5.1\bin\x64\Rscript.exe
Script: C:\a\_temp\quarto\share\capabilities\knitr.R

Exit code: -1073741569
Stdout:
--- YAML_START ---
versionMajor: 4
versionMinor: 5
versionPatch: 1
platform: x86_64-w64-mingw32
packages:
  knitr: "1.50"
  rmarkdown: "2.30"
--- YAML_END ---

Deno subprocess spawn FAILED with exit code -1073741569
```

**Conclusion**: This definitively proves the issue is **Deno's subprocess spawning mechanism**, not Quarto-specific code.

## Technical Analysis

### Error Code: -1073741569 (0xC00000BB)

This is Windows NTSTATUS code `STATUS_NOT_SUPPORTED`, which indicates:

> "The request is not supported."

This error typically occurs when a system component detects an unsupported operation or configuration at runtime.

### Why Direct Execution Works

When PowerShell spawns Rscript directly:
- Windows recognizes the x64 binary
- Automatically activates x64 emulation layer
- Process launches successfully under WOW64 (Windows-on-Windows 64-bit)

### Why Deno Subprocess Fails

**Confirmed**: Test 3 proves this is a Deno subprocess spawning issue, not Quarto-specific. When Deno attempts to spawn an x64 process on Windows ARM, it fails with `STATUS_NOT_SUPPORTED` even though:
- The same x64 binary runs successfully when spawned by PowerShell
- The process partially executes (produces valid output before crashing)
- Windows WOW64 emulation is functional

Possible root causes within Deno:

1. **Process creation flags**: Deno may use process creation flags incompatible with cross-architecture execution
2. **Environment inheritance**: ARM64 Deno may not properly configure the environment for x64 child processes
3. **WOW64 integration**: Deno's Windows ARM implementation may not correctly interface with WOW64 for subprocess spawning

This is definitively a **Deno limitation on Windows ARM**, not a Quarto issue.

## Implications

### For Quarto Users

1. R x64 on Windows ARM is **not a viable configuration** when using Quarto
2. Users must install native ARM64 R (`aarch64-w64-mingw32`) to use R with Quarto
3. PR #13790 improves error detection and messaging for this scenario

### For Quarto Development

1. The improved error handling in PR #13790 correctly detects this failure
2. Error message should guide users to install ARM64 R, not debug R x64
3. This is working as designed - the issue is external to Quarto

### For Deno Development

This finding may warrant investigation by the Deno team:
- Deno's subprocess spawning on Windows ARM needs cross-architecture support
- Other tools relying on Deno may encounter similar issues with x64 executables

## Evidence

All evidence from GitHub Actions workflow runs on `windows-11-arm` runners:

- **Test 1 - Direct PowerShell → Rscript** (✅ Success): [Workflow run #20234173159, step 7](https://github.com/cderv/quarto-windows-arm/actions/runs/20234173159/job/58084315795#step:7:11)
  - Exit code: 0
  - Valid YAML output

- **Test 2 - Quarto → Deno → Rscript** (❌ Failed): [Same workflow, step 8](https://github.com/cderv/quarto-windows-arm/actions/runs/20234173159/job/58084315795#step:8:55)
  - Exit code: -1073741569
  - Valid YAML output before crash

- **Test 3 - Direct Deno → Rscript** (❌ Failed): [Workflow run #20235400009, step 7](https://github.com/cderv/quarto-windows-arm/actions/runs/20235400009/job/58088650203#step:7:38)
  - Exit code: -1073741569 (identical to Test 2)
  - Proves issue is Deno subprocess spawning, not Quarto

## Related Work

- [Quarto PR #13790](https://github.com/quarto-dev/quarto-cli/pull/13790): Detect and warn about x64 R on Windows ARM
- [This test repository](https://github.com/cderv/quarto-windows-arm): Comprehensive testing of R configurations on Windows ARM

## Recommendations

### For Users

Install native ARM64 R on Windows ARM:
- Download: [R for Windows ARM](https://www.r-project.org/nosvn/winutf8/aarch64/R-4-signed/)
- RTools: [RTools45 ARM64](https://cran.r-project.org/bin/windows/Rtools/rtools45/files/)
- Set `QUARTO_R` to point to ARM64 Rscript.exe

### For Developers

When debugging R issues on Windows ARM:
1. Test R directly first (PowerShell → Rscript)
2. Only investigate Quarto/Deno if direct execution also fails
3. Architecture mismatch errors during subprocess creation are expected behavior

### For Future Investigation

Potential Deno investigation topics:
- How Deno spawns processes on Windows ARM
- Whether process creation flags need adjustment for WOW64
- If other Deno-based tools encounter similar cross-architecture issues

## Conclusion

This testing demonstrates that **the root cause is not R x64 emulation** (which works fine) but **Deno's subprocess spawning mechanism on Windows ARM**. Quarto's error detection and messaging improvements in PR #13790 are appropriate responses to this external limitation.

The recommended solution remains: **use native ARM64 R with Quarto on Windows ARM**.
