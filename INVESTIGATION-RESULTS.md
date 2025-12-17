# rmarkdown Crash Investigation Results

## Investigation Date
December 17, 2025

## Objective
Identify why the rmarkdown R package crashes on R x64 Windows ARM with exit code -1073741569 (STATUS_NOT_SUPPORTED) during process termination.

## Investigation Phases Completed

### Phase 1: Individual Dependency Testing

**Goal:** Test each rmarkdown dependency individually to identify failing packages.

**Results:** ✅ **ALL 24 dependencies PASS individually**

Tested dependencies:
- **Direct dependencies:** bslib, evaluate, fontawesome, htmltools, jquerylib, jsonlite, knitr, tinytex, xfun, yaml
- **Transitive dependencies:** base64enc, cachem, cli, digest, fastmap, fs, glue, highr, lifecycle, memoise, mime, R6, rappdirs, rlang, sass

**Key findings:**
- Every package loads and terminates successfully when tested alone
- High suspects (tinytex, htmltools, bslib, sass, fs) all work individually
- Exit code 0 for all 24 packages

**Conclusion:** The crash is NOT caused by a single failing dependency.

### Phase 2: DLL Investigation

**Goal:** Identify which native DLLs are loaded by rmarkdown vs knitr.

**Method:** Compare loaded DLLs across three scenarios:
1. Baseline R (no packages)
2. R + knitr (works)
3. R + rmarkdown (crashes)

**Results:**

**Baseline R (6 DLLs):**
- base, graphics, grDevices, methods, stats, utils

**knitr (8 DLLs):**
- Baseline + tools.dll + xfun.dll

**rmarkdown (13 DLLs):**
- knitr's 8 + **5 additional DLLs:**
  - cli.dll
  - digest.dll
  - fastmap.dll
  - htmltools.dll
  - rlang.dll

**Key finding:** rmarkdown loads 5 DLLs that knitr doesn't use.

### Phase 3: DLL Combination Testing

**Goal:** Test if combinations of the 5 suspect DLLs cause the crash.

**Results:** ✅ **ALL combinations PASS**

Tested combinations:
- cli + htmltools ✅
- rlang + htmltools ✅
- fastmap + htmltools ✅
- digest + rlang ✅
- cli + htmltools + rlang (triplet) ✅
- **All 5 together (cli + digest + fastmap + htmltools + rlang)** ✅

**Conclusion:** Even loading all 5 suspect DLLs together does NOT cause the crash.

## Critical Findings

### What We've Proven

1. ✅ **All 24 individual dependencies work** (tested individually)
2. ✅ **All DLL combinations work** (including all 5 suspect DLLs together)
3. ❌ **Only rmarkdown itself crashes** when loaded

### What This Means

**The crash is NOT in rmarkdown's dependencies or DLLs.**

The crash MUST be in:
- **rmarkdown's own initialization/cleanup code** (.onLoad, .onUnload, .onDetach hooks)
- **Operations rmarkdown performs** after loading its dependencies
- **How rmarkdown uses these packages** (not just loading them)

## DeepWiki Insight: Pandoc Management

Querying the rmarkdown repository revealed critical information:

**What rmarkdown does that knitr doesn't:**

1. **During initialization (.onLoad):**
   - Calls `find_pandoc()` to locate Pandoc executable
   - Searches system PATH and environment variables
   - Checks RStudio-specific paths
   - **Involves system calls that could fail under x64 emulation**

2. **Process spawning:**
   - Uses `system()` calls to execute external Pandoc binary
   - Spawns x64 Pandoc process under emulation
   - **Could trigger STATUS_NOT_SUPPORTED in emulated environment**

3. **Cleanup operations:**
   - Registers `on.exit()` handlers for temporary file cleanup
   - Uses `unlink()`, `list.files()`, `dir.create()`
   - **File system operations during termination**

**Key difference from knitr:**
- knitr focuses on code chunk execution and markdown output
- rmarkdown manages external tool (Pandoc) requiring system calls
- rmarkdown's Pandoc detection/execution introduces WOW64 emulation issues

## Test Evidence Location

All tests run on GitHub Actions `windows-11-arm` runners with R x64 4.5.1.

**Workflows:**
- Individual dependencies: `.github/workflows/investigate-rmarkdown-deps.yml`
- Suspect DLLs: `.github/workflows/investigate-suspect-dlls.yml`
- DLL investigation: `.github/workflows/investigate-rmarkdown-dlls.yml`
- DLL combinations: `.github/workflows/investigate-dll-combinations.yml`

**Test scripts:**
- Individual deps: `test-dep-*.R` (24 files)
- DLL analysis: `test-dlls-*.R` (3 files)
- Combinations: `test-combo-*.R` (6 files)

**Key workflow runs:**
- Dependency isolation: https://github.com/cderv/quarto-windows-arm/actions/runs/20304574201
- DLL investigation: https://github.com/cderv/quarto-windows-arm/actions/runs/20304574236
- DLL combinations: https://github.com/cderv/quarto-windows-arm/actions/runs/20304782348
- Suspect DLLs: https://github.com/cderv/quarto-windows-arm/actions/runs/20304871958

## Next Steps for Investigation

### Recommended: Pandoc-Related Testing

Since deepwiki revealed Pandoc management is unique to rmarkdown:

1. **Test Pandoc detection during library loading:**
   - Does rmarkdown call `find_pandoc()` when you just load the library?
   - Can we isolate Pandoc detection operations?

2. **Test with/without Pandoc available:**
   - Does the crash occur if Pandoc is not found?
   - Does disabling Pandoc detection prevent the crash?

3. **Examine cleanup hooks:**
   - What does rmarkdown's .onUnload/.onDetach do?
   - Are there Pandoc-related cleanup operations?
   - Do cleanup hooks attempt system calls that fail under WOW64?

### Optional: Phase 3 Hook Investigation

Create tests to examine:
- `test-hooks-rmarkdown.R` - Document .onLoad/.onUnload/.onDetach hooks
- `test-namespace-only.R` - Test loadNamespace() vs library()
- `test-namespace-comparison.R` - Compare knitr vs rmarkdown loading

## Findings for rmarkdown Maintainers

### Summary for Bug Report

**Issue:** rmarkdown R package crashes during process termination on R x64 Windows ARM with exit code -1073741569 (STATUS_NOT_SUPPORTED).

**What we've proven:**
- ❌ NOT caused by individual dependencies (all 24 pass)
- ❌ NOT caused by DLL combinations (all combinations pass)
- ❌ NOT caused by native libraries (all DLLs work together)
- ✅ ONLY occurs when loading rmarkdown itself
- ✅ Scripts complete successfully before crashing during termination

**Root cause hypothesis:**
The crash is in rmarkdown's own initialization/cleanup code, specifically operations related to Pandoc management:
- Pandoc detection during `.onLoad` (system PATH searches, environment queries)
- Pandoc process spawning via `system()` calls
- Cleanup operations during `.onUnload`/`.onDetach`

These operations likely use Windows API calls that return STATUS_NOT_SUPPORTED under x64 emulation on Windows ARM.

**Tested environment:**
- R x64 4.5.1 on Windows 11 ARM (GitHub Actions `windows-11-arm` runners)
- rmarkdown 2.30
- All tests via direct `library(rmarkdown)` calls (no rendering)

**Evidence:** Complete test suite with 24 individual dependency tests, DLL analysis, and combination testing available at https://github.com/cderv/quarto-windows-arm

## Related Documentation

- **FINDINGS.md** - Original technical analysis proving R x64/rmarkdown incompatibility
- **NEXT-INVESTIGATION.md** - Initial investigation plan (superseded by this document)
- **ARM-DETECTION.md** - Windows ARM detection implementation details
- **README.md** - Repository overview and test scenarios

## Repository Context

This investigation supports Quarto PR #13790, which detects and warns about x64 R on Windows ARM. The crash is expected behavior (not a Quarto bug), and the solution is to use native R ARM64.
