# Next Investigation: rmarkdown Package Failure on R x64 Windows ARM

## Investigation Status: Phase 1-2 Complete ✅

**Last Updated:** December 17, 2025

We've completed systematic investigation into why rmarkdown crashes on R x64 Windows ARM. See **INVESTIGATION-RESULTS.md** for complete findings.

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

## 🎯 Critical Discovery

**The crash is in rmarkdown's own code, not its dependencies or DLLs.**

Based on DeepWiki analysis of rmarkdown repository, the crash is likely in **Pandoc management operations**:

1. **Pandoc detection during `.onLoad`:**
   - `find_pandoc()` searches system PATH
   - Queries environment variables
   - Checks RStudio-specific paths
   - Uses system calls that may fail under WOW64 emulation

2. **Process spawning:**
   - `system()` calls to execute Pandoc binary
   - Spawns x64 Pandoc under emulation
   - Could trigger STATUS_NOT_SUPPORTED

3. **Cleanup during termination:**
   - `.onUnload`/`.onDetach` hooks
   - Temporary file cleanup
   - Potential Pandoc process cleanup

**Key insight:** knitr doesn't manage external tools like Pandoc, so it doesn't have these system-level operations.

## Next Investigation Phase (Optional)

Since we've proven the issue is in rmarkdown's own code, further investigation would focus on **Pandoc-specific operations**.

### Recommended Tests

#### Test 1: Pandoc Detection Isolation

**Goal:** Determine if `find_pandoc()` is called during `library(rmarkdown)` and if it causes the crash.

```r
# test-pandoc-detection.R
# Test: Does rmarkdown call find_pandoc() during library loading?

cat("Loading rmarkdown...\n")
library(rmarkdown)

cat("Checking if Pandoc was detected:\n")
available <- pandoc_available()
cat("  pandoc_available():", available, "\n")

if (available) {
  version <- pandoc_version()
  cat("  pandoc_version():", as.character(version), "\n")
}

cat("Result: SUCCESS (if you see this)\n")
```

#### Test 2: Hook Investigation

**Goal:** Document what cleanup hooks rmarkdown registers.

```r
# test-hooks-rmarkdown.R
# Test: What cleanup operations does rmarkdown register?

library(rmarkdown)

ns <- asNamespace("rmarkdown")

cat("Checking for cleanup hooks:\n")

if (exists(".onUnload", where = ns, inherits = FALSE)) {
  cat("  .onUnload: EXISTS\n")
  cat("  Code:\n")
  print(body(get(".onUnload", envir = ns)))
} else {
  cat("  .onUnload: NOT FOUND\n")
}

if (exists(".onDetach", where = ns, inherits = FALSE)) {
  cat("  .onDetach: EXISTS\n")
  cat("  Code:\n")
  print(body(get(".onDetach", envir = ns)))
} else {
  cat("  .onDetach: NOT FOUND\n")
}

cat("Result: SUCCESS (if you see this - crash happens during termination)\n")
```

#### Test 3: Namespace Loading

**Goal:** Test if crash occurs with `loadNamespace()` vs `library()`.

```r
# test-namespace-only.R
# Test: Does loadNamespace crash or just library()?

cat("Loading rmarkdown namespace (not attaching)...\n")
loadNamespace("rmarkdown")
cat("Namespace loaded successfully\n")

cat("Result: SUCCESS (if you see this)\n")
# If this passes but library(rmarkdown) crashes,
# the issue is in attachment, not loading
```

### Implementation Notes

These tests are **optional** - they would help pinpoint the exact operation that fails, but we already have enough evidence for rmarkdown maintainers:

1. The crash is in rmarkdown's own code
2. It's related to operations rmarkdown performs that knitr doesn't (likely Pandoc management)
3. All dependencies work fine individually and in combination

## Evidence for Bug Report

See **INVESTIGATION-RESULTS.md** for complete documentation suitable for rmarkdown maintainers.

**Summary for rmarkdown maintainers:**
- Crash occurs on R x64 Windows ARM during process termination
- Exit code: -1073741569 (STATUS_NOT_SUPPORTED)
- All 24 dependencies tested individually - all pass
- All DLL combinations tested - all pass
- Only rmarkdown itself crashes
- Hypothesis: Pandoc management operations use Windows APIs incompatible with WOW64 emulation

**Test repository:** https://github.com/cderv/quarto-windows-arm

## Current Status

### Completed ✅
- [x] Individual dependency isolation (24 packages)
- [x] DLL analysis (baseline, knitr, rmarkdown comparison)
- [x] DLL combination testing (6 combinations)
- [x] Root cause identified (rmarkdown's own code, not dependencies)
- [x] Hypothesis formed (Pandoc management operations)
- [x] Documentation for maintainers

### Optional 🔍
- [ ] Pandoc detection testing
- [ ] Hook investigation
- [ ] Namespace vs library() testing

### Not Needed ❌
- ~~Function-level testing~~ (crash is in termination, not execution)
- ~~More dependency combinations~~ (all dependencies work)
- ~~Deeper DLL investigation~~ (all DLLs work together)

## Conclusion

**The investigation is sufficient for documentation.**

We've proven:
1. The crash is NOT in rmarkdown's dependencies
2. The crash IS in rmarkdown's own initialization/cleanup code
3. The likely culprit is Pandoc management operations

Further testing would only refine the exact line of code that fails, which isn't necessary for:
- Documenting the issue for rmarkdown maintainers
- Confirming Quarto PR #13790's approach is correct (detect and warn)
- Understanding why R ARM64 is required on Windows ARM

**Solution remains:** Use native R ARM64 on Windows ARM.

## Related Documentation

- **INVESTIGATION-RESULTS.md** - Complete investigation findings (START HERE)
- **FINDINGS.md** - Original technical analysis
- **ARM-DETECTION.md** - Windows ARM detection implementation
- **README.md** - Repository overview

## Repository Context

This investigation supports Quarto PR #13790, which detects and warns about x64 R on Windows ARM. The crash is expected behavior (not a Quarto bug), and the solution is to use native R ARM64.

**Optional further investigation would help rmarkdown maintainers fix the package, but is not required for Quarto.**
