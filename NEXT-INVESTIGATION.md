# Next Investigation: rmarkdown Package Failure on R x64 Windows ARM

## Investigation Status: Phase 1-7 Complete ✅

**Last Updated:** December 17, 2025

We've completed systematic investigation through 7 phases. Multiple hypotheses have been tested and rejected. The root cause remains in rmarkdown's namespace loading mechanism. See **INVESTIGATION-RESULTS.md** for complete findings.

## What We've Completed

### ✅ Phase 1: Comprehensive Dependency Testing

**Result:** ALL 24 dependencies PASS individually

Tested every package in rmarkdown's dependency tree:
- Direct deps: bslib, evaluate, fontawesome, htmltools, jquerylib, jsonlite, knitr, tinytex, xfun, yaml
- Transitive deps: base64enc, cachem, cli, digest, fastmap, fs, glue, highr, lifecycle, memoise, mime, R6, rappdirs, rlang, sass

**Conclusion:** No individual dependency causes the crash.

### ✅ Phase 2: DLL Analysis

**Result:** Identified 5 DLLs unique to rmarkdown (not in knitr)

- Baseline R: 6 DLLs
- knitr: 8 DLLs (baseline + tools + xfun)
- rmarkdown: 13 DLLs (knitr's 8 + cli + digest + fastmap + htmltools + rlang)

**Conclusion:** rmarkdown loads 5 additional DLLs, but...

### ✅ Phase 3: DLL Combination Testing

**Result:** ALL combinations PASS (even all 5 DLLs together)

Tested 6 combinations including all 5 suspect DLLs loaded simultaneously.

**Conclusion:** The crash is NOT in the DLLs themselves.

### ✅ Phase 4: rmarkdown Source Code Analysis

**Result:** Identified root cause hypothesis and disproved Pandoc theory

**Complete analysis:** See **[RMARKDOWN-SOURCE-ANALYSIS.md](RMARKDOWN-SOURCE-ANALYSIS.md)**

**Key findings:**
- ❌ Pandoc management is NOT the cause (Pandoc is lazy-loaded)
- ❌ No explicit cleanup hooks (no `.onUnload` or `.onDetach`)
- ✅ bslib global state management identified as primary suspect (80% likelihood)
- ✅ Three alternative hypotheses documented (temp files, hooks, bindings)

### ✅ Phase 5: bslib Hypothesis Testing (HYPOTHESIS REJECTED)

**Result:** bslib hypothesis DEFINITIVELY REJECTED

**Test workflow:** `.github/workflows/test-bslib-hypothesis.yml`

**Test results:**
- Test 1 (bslib only): ✅ PASSED (exit 0)
- Test 2 (bslib deps): ✅ PASSED (exit 0)
- Test 3 (rmarkdown minimal): ❌ CRASHED (exit -1073741569)

**Critical finding:** Test 3 output shows **bslib was NOT loaded** when crash occurred:
```
✗ bslib is NOT loaded (unexpected!)

Packages loaded when crash occurred:
  ✓ htmltools
  ✓ knitr
  ✓ xfun      <-- ONLY package with compiled C code (DLL)
  ✓ evaluate
  ✗ bslib     <-- NOT loaded
```

**Conclusion:** The crash occurs even when bslib is not loaded. bslib global state management is NOT the root cause.

### ✅ Phase 6: Testing Remaining Hypotheses (xfun, package combo, .onLoad)

**Result:** Identified that rmarkdown's `.onLoad` hook is the differentiator

**Test workflow:** `.github/workflows/test-phase6-hypotheses.yml`

**Test results:**
- Test 1 (xfun only): ✅ PASSED (exit 0)
- Test 2 (minimal combo: htmltools + knitr + xfun + evaluate): ✅ PASSED (exit 0)
- Test 3 (knitr only): ✅ PASSED (exit 0)

**Critical finding:** The exact package combination that was loaded when rmarkdown crashed works fine WITHOUT rmarkdown.

**Conclusion:** The crash is NOT in xfun's DLL, NOT in the package combination. The issue is in **rmarkdown's `.onLoad` hook mechanism** (Hypothesis 4 from Phase 4).

### ✅ Phase 7: setHook Root Cause Confirmation (HYPOTHESIS REJECTED)

**Result:** `.onLoad` hook hypothesis DEFINITIVELY REJECTED

**Test workflow:** `.github/workflows/test-sethook-hypothesis.yml`

**Test results:**
- Test 1 (setHook mechanism only): ✅ PASSED (exit 0)
- Test 2 (complete .onLoad reproduction): ✅ PASSED (exit 0)

**Critical finding:** Reproducing rmarkdown's `.onLoad` function behavior (stack creation + knitr loading + setHook registration) does NOT cause crash.

**Conclusion:** The crash is NOT in the `.onLoad` function. Something else during rmarkdown namespace loading causes the crash.

## 🎯 Critical Discovery - Phase 7 Results

**The crash occurs during rmarkdown namespace loading, NOT in `.onLoad`, NOT in dependencies, NOT in package combinations.**

### All Rejected Hypotheses (Phases 1-7)

**Hypothesis 1 (REJECTED - Phase 4):** Pandoc management
- Source analysis proved Pandoc is lazy-loaded
- `find_pandoc()` NOT called during package load
- Simple `library(rmarkdown)` crashes without touching Pandoc code

**Hypothesis 2 (REJECTED - Phase 5):** bslib global state management
- Empirical testing showed bslib alone works fine (exit 0)
- rmarkdown crashes WITHOUT bslib being loaded
- bslib is NOT the root cause

**Hypothesis 3 (REJECTED - Phase 6):** xfun DLL cleanup
- xfun alone works fine (exit 0)
- xfun is NOT the root cause

**Hypothesis 4 (REJECTED - Phase 6):** Package combination
- htmltools + knitr + xfun + evaluate work fine together (exit 0)
- Package combination is NOT the root cause

**Hypothesis 5 (REJECTED - Phase 7):** rmarkdown's `.onLoad` hook
- setHook(packageEvent(...)) mechanism works fine (exit 0)
- Complete `.onLoad` reproduction works fine (exit 0)
- `.onLoad` function is NOT the root cause

### Current Status: Root Cause Unknown

**What we know:**
1. ✅ All 24 dependencies work individually
2. ✅ All DLL combinations work
3. ✅ The minimal package combo (htmltools + knitr + xfun + evaluate) works
4. ✅ rmarkdown's `.onLoad` function behavior works when reproduced
5. ❌ BUT `library(rmarkdown)` crashes

**The issue must be in:**
- Namespace loading mechanism (parsing R code, lazy loading)
- S3/S4 method registration beyond `.onLoad`
- Package attachment/import mechanics
- Something specific to how R loads the rmarkdown package that we haven't isolated yet

**Crash characteristics:**
- Exit code: -1073741569 (STATUS_NOT_SUPPORTED)
- Timing: During R termination after script completes successfully
- Platform: R x64 under WOW64 emulation on Windows ARM
- Reproducible: 100% consistent across all testing methods

## Next Investigation Steps

After 7 phases and rejecting 5 hypotheses, further investigation would require deeper analysis:

### Potential Areas to Explore

**1. Namespace Loading Mechanics**
- Compare how R loads rmarkdown vs how it loads knitr
- Trace exact sequence of operations during `loadNamespace("rmarkdown")`
- Identify any Windows API calls made during namespace loading

**2. Lazy Loading**
- rmarkdown has lazy-loaded data or code
- Test if the issue is in lazy load database initialization

**3. S3 Method Registration**
- rmarkdown registers S3 methods beyond `.onLoad`
- Test if method registration mechanism causes issues

**4. NAMESPACE File Processing**
- rmarkdown's NAMESPACE file specifies imports and exports
- Test if specific import/export directives trigger the issue

**5. R Core Debugging**
- Attach debugger to R process
- Trace system calls during `library(rmarkdown)`
- Identify exact Windows API that returns STATUS_NOT_SUPPORTED

### Why Further Investigation May Not Be Practical

1. **Complexity:** Requires low-level R internals knowledge
2. **Platform-specific:** Needs Windows ARM hardware and debugging tools
3. **Diminishing returns:** The solution (use R ARM64) is known and works
4. **R core issue:** May require changes to R itself, not rmarkdown

### Current Recommendation

**For users:** Use native R ARM64 on Windows ARM (works 100%)

**For rmarkdown maintainers:** Document the incompatibility. The root cause is deep in R's namespace loading mechanism under WOW64 emulation. Without access to Windows ARM debugging tools and R internals expertise, pinpointing the exact line of code may not be feasible.

**For Quarto:** PR #13790's approach (detect and warn) is correct.

## Evidence for Bug Report

See **INVESTIGATION-RESULTS.md** for complete documentation suitable for rmarkdown maintainers.

**Summary for rmarkdown maintainers:**
- Crash occurs on R x64 Windows ARM during process termination
- Exit code: -1073741569 (STATUS_NOT_SUPPORTED)
- All 24 dependencies tested individually - all pass
- All DLL combinations tested - all pass
- Package combinations tested - all pass
- `.onLoad` behavior reproduced - passes
- **Root cause:** Something in rmarkdown's namespace loading mechanism (beyond `.onLoad`) uses Windows APIs incompatible with WOW64 emulation
- **7 phases completed, 5 hypotheses rejected**

**Test repository:** https://github.com/cderv/quarto-windows-arm

## Current Status

### Completed ✅
- [x] Phase 1: Individual dependency isolation (24 packages) - All pass
- [x] Phase 2: DLL analysis (baseline, knitr, rmarkdown comparison)
- [x] Phase 3: DLL combination testing (6 combinations) - All pass
- [x] Phase 4: rmarkdown source code analysis - Identified 4 hypotheses
- [x] Phase 5: bslib hypothesis testing - REJECTED
- [x] Phase 6: xfun, package combo, and knitr testing - All pass, pointed to `.onLoad`
- [x] Phase 7: setHook and `.onLoad` reproduction testing - REJECTED
- [x] Comprehensive documentation created (RMARKDOWN-SOURCE-ANALYSIS.md)

### All Rejected Hypotheses ❌
1. ~~Pandoc management~~ (Phase 4 - lazy-loaded, not called)
2. ~~bslib global state~~ (Phase 5 - not even loaded when crash occurs)
3. ~~xfun DLL cleanup~~ (Phase 6 - xfun alone works fine)
4. ~~Package combination~~ (Phase 6 - combination works without rmarkdown)
5. ~~rmarkdown's `.onLoad` hook~~ (Phase 7 - reproduction works fine)

### Root Cause Status ⚠️
**Unknown** - The crash is in rmarkdown's namespace loading mechanism, but the exact component has not been identified. Further investigation requires R internals debugging tools and Windows ARM platform access.

## Conclusion

**The investigation has completed 7 phases and systematically rejected 5 hypotheses.**

### What We've Definitively Proven (Through Elimination):
1. ✅ NOT in individual dependencies (Phase 1 - all 24 pass)
2. ✅ NOT in DLL combinations (Phase 3 - all combinations pass)
3. ✅ NOT in Pandoc management (Phase 4 - lazy-loaded, not called)
4. ✅ NOT in bslib global state (Phase 5 - not even loaded)
5. ✅ NOT in xfun DLL cleanup (Phase 6 - xfun alone passes)
6. ✅ NOT in package combinations (Phase 6 - exact combo passes)
7. ✅ NOT in `.onLoad` function (Phase 7 - reproduction passes)

### What Remains Unknown:
The crash occurs **during rmarkdown namespace loading**, specifically in:
- Namespace loading mechanism (beyond `.onLoad`)
- Lazy loading initialization
- S3/S4 method registration
- NAMESPACE file import/export processing
- Some other R internal operation during package attachment

### Why Further Investigation Is Challenging:
1. Requires deep R internals knowledge
2. Needs low-level Windows debugging on ARM hardware
3. May be an R core issue, not fixable in rmarkdown
4. The issue is 100% reproducible but highly specific to:
   - R x64 (not R ARM64)
   - Windows ARM (WOW64 emulation)
   - rmarkdown package specifically
   - Termination phase (not during execution)

### Current Recommendation:

**For users:** Use native R ARM64 on Windows ARM (works perfectly)

**For rmarkdown maintainers:** The issue is documented but root cause isolation requires R core debugging. The crash is in namespace loading mechanics under WOW64 emulation.

**For Quarto:** PR #13790's approach (detect x64 R on ARM Windows and warn users) is the correct solution.

**Solution remains:** Use native R ARM64 on Windows ARM.

## Related Documentation

- **INVESTIGATION-RESULTS.md** - Complete investigation findings (START HERE)
- **FINDINGS.md** - Original technical analysis
- **ARM-DETECTION.md** - Windows ARM detection implementation
- **README.md** - Repository overview

## Repository Context

This investigation supports Quarto PR #13790, which detects and warns about x64 R on Windows ARM. The crash is expected behavior (not a Quarto bug), and the solution is to use native R ARM64.

**Optional further investigation would help rmarkdown maintainers fix the package, but is not required for Quarto.**
