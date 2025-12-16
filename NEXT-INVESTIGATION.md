# Next Investigation: rmarkdown Package Failure on R x64 Windows ARM

## Current Status

We've definitively identified the root cause of Quarto's R x64 Windows ARM issue through systematic testing in the `quarto-windows-arm` repository.

**Confirmed root cause:** The `rmarkdown` R package crashes during process termination when running under R x64 emulation on Windows ARM (exit code -1073741569 / STATUS_NOT_SUPPORTED).

**Critical confirmation:** This happens even with **direct PowerShell → Rscript execution** (no subprocess spawning), proving it's a fundamental R x64 emulation issue.

## What We Know

### Test Results Summary

| Test | Result | Conclusion |
|------|--------|------------|
| Simple R scripts | ✅ Always succeed | R x64 emulation works |
| Scripts loading `knitr` | ✅ Always succeed | knitr is compatible |
| Scripts loading `rmarkdown` | ❌ Always fail | **rmarkdown is the problem** |
| Scripts loading both | ❌ Always fail | rmarkdown causes crash |

### Key Findings

1. **Consistent across all invocation methods:**
   - ❌ Direct PowerShell → Rscript (CONFIRMED - no subprocess)
   - ❌ Deno x64 → Rscript (all versions 2.4.5-2.6.1)
   - ❌ Node.js ARM64 → Rscript
   - ❌ Python ARM64 → Rscript

2. **Crash occurs during termination:**
   - Scripts execute completely
   - Produce valid output
   - Print "SUCCESS" message
   - Then crash during cleanup

3. **Exit code:** -1073741569 (0xC00000BB) = STATUS_NOT_SUPPORTED

4. **NOT a subprocess issue:** Confirmed via direct PowerShell execution test

5. **NOT Deno-specific:** Identical across 4 Deno versions

6. **Specific to rmarkdown:** knitr alone works fine

### Evidence Location

- **Repository:** https://github.com/cderv/quarto-windows-arm
- **Findings:** `FINDINGS.md` - Complete analysis with workflow links
- **Test Scripts:** `test-simple.R`, `test-knitr.R`, `test-rmarkdown.R`, `test-both.R`
- **Key Workflows:**
  - `test-r-package-loading.yml` - **Direct R execution** proving no subprocess issue
    - [Workflow run](https://github.com/cderv/quarto-windows-arm/actions/runs/20266226901)
    - Test 3 shows direct `Rscript test-rmarkdown.R` failing with -1073741569
  - `test-deno-versions.yml` - Deno version comparison (all fail identically)

## Next Investigation Phase

**Goal:** Identify the specific rmarkdown package operation that fails during termination on R x64 Windows ARM.

### Investigation Questions

1. **Which rmarkdown dependencies cause the crash?**
   - Does the issue occur with specific transitive dependencies?
   - Can we isolate it to a single sub-package?
   - rmarkdown depends on: jsonlite, tinytex, xfun, evaluate, yaml, knitr, jquerylib, bslib, htmltools, and more

2. **What cleanup operations fail?**
   - Native DLL unloading?
   - File handle cleanup?
   - Process spawning/cleanup (Pandoc related)?
   - Temporary file cleanup?
   - Registry operations?

3. **Can we create a minimal reproduction?**
   - What's the smallest rmarkdown functionality that triggers the crash?
   - Can we reproduce outside of rmarkdown by calling specific functions?
   - Does just attaching the namespace crash? `loadNamespace("rmarkdown")`

4. **What does rmarkdown do that knitr doesn't?**
   - Compare package initialization/cleanup code
   - Identify unique operations in rmarkdown
   - Check for .onLoad / .onUnload / .onDetach hooks

### Suggested Approach

#### Step 1: Dependency Isolation

Test loading rmarkdown's dependencies individually to isolate the failing component:

```r
# test-deps-individual.R
# Test each dependency separately to find which one(s) fail

test_package <- function(pkg_name) {
  cat("Testing package:", pkg_name, "\n")
  tryCatch({
    library(pkg_name, character.only = TRUE)
    cat("  Loaded successfully\n")
  }, error = function(e) {
    cat("  ERROR loading:", e$message, "\n")
  })
}

# Test major rmarkdown dependencies
test_package("jsonlite")
test_package("tinytex")
test_package("xfun")
test_package("evaluate")
test_package("yaml")
test_package("jquerylib")
test_package("bslib")
test_package("htmltools")

cat("All tests complete\n")
```

Then test combinations:
```r
# test-deps-combinations.R
# If individual packages work, test combinations
library(jsonlite)
library(tinytex)
# Add more as needed
```

#### Step 2: Namespace vs Full Load

Test whether the crash is in package loading or just namespace attachment:

```r
# test-namespace-only.R
# Does loadNamespace crash vs library()?
cat("Loading rmarkdown namespace (not attaching)...\n")
loadNamespace("rmarkdown")
cat("Namespace loaded successfully\n")
# Exit - does this crash?
```

```r
# test-library-attach.R
cat("Attaching rmarkdown with library()...\n")
library(rmarkdown)
cat("Library attached successfully\n")
# Exit - we know this crashes
```

#### Step 3: Function-Level Testing

Test specific rmarkdown functions to narrow down the issue:

```r
# test-minimal-function.R
# Load package and call minimal function
library(rmarkdown)

# Try simplest possible function
result <- rmarkdown::pandoc_available()
cat("Pandoc available:", result, "\n")

# Exit and see if it still crashes
```

#### Step 4: Native Code Investigation

Check for native DLLs and their cleanup:

```r
# test-loaded-dlls.R
cat("Initial DLLs:\n")
print(names(getLoadedDLLs()))

library(rmarkdown)

cat("\nAfter loading rmarkdown:\n")
print(names(getLoadedDLLs()))

cat("\nChecking for x64-specific DLLs...\n")
dlls <- getLoadedDLLs()
for (dll_name in names(dlls)) {
  dll <- dlls[[dll_name]]
  cat(sprintf("  %s: %s\n", dll_name, dll[["path"]]))
}
```

#### Step 5: Package Hook Investigation

Check what cleanup hooks rmarkdown registers:

```r
# test-package-hooks.R
library(rmarkdown)

# Check for registered finalizers/cleanup hooks
cat("Package environment:\n")
print(ls(asNamespace("rmarkdown"), all.names = TRUE))

# Look for .onUnload, .onDetach, .Last.lib
if (exists(".onUnload", where = asNamespace("rmarkdown"))) {
  cat("\n.onUnload hook exists\n")
}
if (exists(".onDetach", where = asNamespace("rmarkdown"))) {
  cat("\n.onDetach hook exists\n")
}
```

#### Step 6: Gradual Feature Testing

Test rmarkdown's features progressively:

```r
# test-rmarkdown-minimal.R
library(rmarkdown)

# Level 1: Just load - we know this crashes

# Level 2: Check Pandoc (if we get here)
# rmarkdown::find_pandoc()

# Level 3: Simple metadata
# rmarkdown::metadata

# Level 4: Try to render nothing
# (probably won't get here)
```

### Implementation Plan

**Create test suite in repository:**

```
tests/
  dependency-isolation/
    test-individual-deps.R
    test-dep-combinations.R
  loading-mechanisms/
    test-namespace-only.R
    test-library-attach.R
  function-level/
    test-minimal-function.R
    test-pandoc-functions.R
  native-code/
    test-loaded-dlls.R
  hooks/
    test-package-hooks.R
```

**Add workflow to run tests:**

```yaml
# .github/workflows/investigate-rmarkdown.yml
- name: Test individual dependencies
  run: Rscript tests/dependency-isolation/test-individual-deps.R

- name: Test namespace loading
  run: Rscript tests/loading-mechanisms/test-namespace-only.R

# etc.
```

### Tools and Resources

**On Windows ARM runner (GitHub Actions):**
- Can add debugging steps to workflows
- Can install additional R packages for testing
- Can capture full output before crash
- Limited debugging tools available

**Potentially useful R packages:**
```r
library(rlang)     # Error inspection
library(pryr)      # Memory/object inspection
library(pkgload)   # Package loading utilities
```

**Windows debugging (if we get local access):**
- Process Monitor (procmon) - Track system calls
- Dependency Walker - Check DLL dependencies
- Windows Error Reporting - Crash dump analysis
- DebugView - Capture debug output

### Expected Outcomes

**Minimum success:** Identify which specific rmarkdown dependency or dependencies cause the crash

**Medium success:** Understand whether crash is in initialization, normal operation, or cleanup phase

**Ideal success:** Identify the exact operation (DLL unload, file cleanup, etc.) that returns STATUS_NOT_SUPPORTED, enabling actionable bug report to rmarkdown maintainers

### Known Constraints

- GitHub Actions Windows ARM runners have limited debugging capabilities
- May need access to actual Windows ARM hardware for deeper investigation
- rmarkdown is complex with many dependencies - could be time-consuming
- Fix (if possible) would need to come from rmarkdown maintainers, not Quarto
- Issue may be in native code where R-level debugging won't help

### Success Criteria

**Phase 1 (Isolation):**
- ✅ Identify minimum set of packages that reproduce the crash
- ✅ Confirm whether it's package-specific or combination-specific

**Phase 2 (Characterization):**
- ✅ Determine if crash is in load, run, or unload phase
- ✅ Identify any error messages beyond STATUS_NOT_SUPPORTED

**Phase 3 (Root Cause):**
- ✅ Understand what Windows API operation fails
- ✅ Document findings for rmarkdown maintainers

## Starting the Investigation

### Quick Start Prompt for Next Session

```
I'm investigating why the rmarkdown R package crashes on R x64 Windows ARM during
process termination (exit -1073741569 / STATUS_NOT_SUPPORTED).

Context:
- Repository: C:\Users\chris\Documents\DEV_OTHER\01-DEMOS\quarto-windows-arm
- We've PROVEN it's rmarkdown-specific (knitr alone works fine)
- Happens with direct PowerShell execution (NOT subprocess issue)
- Happens across all invocation methods (Deno, Node, Python)
- Script completes successfully but crashes during cleanup

See FINDINGS.md for complete background evidence.
See NEXT-INVESTIGATION.md (this file) for investigation approach.

Next step: Start with dependency isolation (Step 1) to find which specific
rmarkdown dependency causes the crash.
```

### Initial Commands

```powershell
# Navigate to repository
cd C:\Users\chris\Documents\DEV_OTHER\01-DEMOS\quarto-windows-arm

# Read background
cat FINDINGS.md

# Review test scripts
ls test-*.R

# Check current test results
gh run list --workflow="Test R x64 Package Loading on Windows ARM" --limit 3
```

## Related Links

- **Quarto PR #13790:** https://github.com/quarto-dev/quarto-cli/pull/13790
- **Test repository:** https://github.com/cderv/quarto-windows-arm
- **rmarkdown package:** https://github.com/rstudio/rmarkdown
- **rmarkdown dependencies:** https://cran.r-project.org/web/packages/rmarkdown/index.html
- **R ARM downloads:** https://www.r-project.org/nosvn/winutf8/aarch64/R-4-signed/

## Notes

- This investigation is optional - PR #13790 is already the correct solution
- Goal is to understand the issue better and potentially help rmarkdown maintainers
- If investigation becomes too complex, document what we found and move on
- Priority is documenting the findings, not necessarily fixing rmarkdown
