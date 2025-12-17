# Phase 8: Namespace Loading Mechanics Investigation

## Investigation Date
December 17, 2025

## Background

After 7 phases and 5 rejected hypotheses, we're investigating the **namespace loading mechanism itself**. The crash occurs during rmarkdown package loading, but NOT in `.onLoad`, NOT in dependencies, NOT in DLLs, and NOT in package combinations.

## Critical Discovery from Phase 5

Phase 5 testing revealed that when rmarkdown crashed, these packages WERE loaded:
- ✅ evaluate
- ✅ htmltools (+ base64enc, digest, fastmap, rlang)
- ✅ knitr (+ xfun, highr)
- ❌ **bslib was NOT loaded**

This means **the crash happens AFTER loading the working set but BEFORE bslib loads**.

## New Hypothesis: Namespace Loading Operations

The crash occurs during R's namespace loading process, specifically in operations that happen BETWEEN:
1. Loading imports (evaluate, htmltools, knitr, xfun) ← Works
2. Loading bslib ← Never reaches here

### Potential Root Causes

#### Hypothesis 8A: loadNamespace() vs library() Difference

**Observation:** Phase 1 tested packages using `library()` calls, but R uses `loadNamespace()` for import resolution.

**Key Differences:**
- `library()`: Loads namespace, attaches to search path, returns package environment
- `loadNamespace()`: Loads namespace, runs `.onLoad`, does NOT attach

**Why this matters:**
Under WOW64 emulation, `loadNamespace()` might trigger different Windows APIs than `library()`, and these APIs could return STATUS_NOT_SUPPORTED.

**Test:** `test-phase8-loadnamespace.R` - Load all imports using `loadNamespace()` instead of `library()`

#### Hypothesis 8B: S3 Method Cross-Namespace Registration

**Observation:** rmarkdown's NAMESPACE declares S3 methods for generics in OTHER packages:

```
S3method(knit_print,grouped_df)           # knitr generic
S3method(knit_print,output_format_dependency)
S3method(knit_print,rowwise_df)
S3method(knit_print,tbl_sql)
S3method(prepare_evaluate_output,default) # evaluate generic
S3method(prepare_evaluate_output,htmlwidget)
S3method(prepare_evaluate_output,knit_asis)
S3method(prepare_evaluate_output,list)
S3method(print,paged_df)                  # base R generic
```

**Why this matters:**
When R processes `S3method()` declarations in NAMESPACE, it must:
1. Access the namespace where the generic is defined (knitr, evaluate)
2. Register the method in the S3 dispatch table
3. Create cross-namespace references

Under WOW64, this cross-namespace operation during package loading might fail. The cleanup of these cross-namespace references during termination could trigger STATUS_NOT_SUPPORTED.

**Test:** `test-phase8-s3methods.R` - Manually register S3 methods across namespaces

#### Hypothesis 8C: Import Resolution Order

**Observation:** R loads imports in dependency order, not alphabetical order.

**Dependency Analysis:**

rmarkdown's Imports (from DESCRIPTION):
```
bslib, evaluate, fontawesome, htmltools, jquerylib, jsonlite,
knitr, methods, tinytex, tools, utils, xfun, yaml
```

Dependency chains:
- **htmltools** → base64enc, digest, fastmap, rlang
- **jquerylib** → htmltools
- **fontawesome** → rlang, htmltools
- **bslib** → base64enc, cachem, fastmap, htmltools, jquerylib, jsonlite, lifecycle, memoise, mime, rlang, sass
- **tinytex** → xfun
- **jsonlite** → (none, just methods)
- **yaml** → (none)

**Loading sequence (likely):**
1. Simple deps: yaml, jsonlite
2. tinytex (needs xfun)
3. htmltools (brings many deps)
4. knitr, evaluate
5. jquerylib, fontawesome (need htmltools)
6. **→ Crash happens somewhere here ←**
7. bslib deps: cachem, lifecycle, memoise, sass
8. bslib

**Why this matters:**
One of the packages loaded AFTER the Phase 5 working set (evaluate, htmltools, knitr, xfun) but BEFORE bslib could be triggering the crash. Candidates:
- jquerylib
- fontawesome
- sass (bslib dep with compiled code)
- cachem, lifecycle, memoise, mime

**Test:** `test-phase8-import-order.R` - Load imports incrementally using `library()` to identify which one crashes

## Test Strategy

### Test 1: loadNamespace() Approach
**File:** `test-phase8-loadnamespace.R`

Replicate exact namespace loading using `loadNamespace()`:
1. Load Phase 5 working set (evaluate, htmltools, knitr)
2. Load remaining imports: jsonlite, yaml, tinytex
3. Load packages before bslib: jquerylib, fontawesome
4. Load bslib dependencies: cachem, lifecycle, memoise, mime, sass
5. Load bslib

**Expected outcome:**
- If crash occurs: Identifies which `loadNamespace()` call triggers it
- If no crash: Rules out `loadNamespace()` as root cause

### Test 2: S3 Method Registration
**File:** `test-phase8-s3methods.R`

Test cross-namespace S3 method registration:
1. Load knitr and evaluate namespaces
2. Manually register S3 methods using `registerS3method()`
3. Test multiple registrations (rmarkdown has 4 knit_print methods)
4. Test method dispatch

**Expected outcome:**
- If crash occurs: S3 method registration or cleanup is root cause
- If no crash: Rules out S3 method registration

### Test 3: Import Order
**File:** `test-phase8-import-order.R`

Incrementally load imports using `library()`:
1. Start with Phase 5 working set
2. Add fontawesome
3. Add jquerylib
4. Add jsonlite
5. Add tinytex
6. Add yaml
7. Add bslib

**Expected outcome:**
- Identifies which specific import triggers the crash
- Narrows down the problem to a specific package

### Test 4: Direct rmarkdown Loading
**Workflow only**

Simply call `loadNamespace("rmarkdown")` and observe:
- Which namespaces get loaded before crash
- Exact point where crash occurs

## Running the Tests

### Locally (if you have Windows ARM hardware):
```powershell
Rscript test-phase8-loadnamespace.R
Rscript test-phase8-s3methods.R
Rscript test-phase8-import-order.R
```

### On GitHub Actions:
```bash
# Trigger the workflow
gh workflow run test-phase8-namespace-loading.yml

# View results
gh run list --workflow="Phase 8: Namespace Loading Investigation"
gh run view <run-id> --log
```

## Expected Outcomes

### If Hypothesis 8A Confirmed (loadNamespace difference):
- One of the `loadNamespace()` calls crashes
- Identifies which package's namespace loading triggers STATUS_NOT_SUPPORTED under WOW64
- Next step: Investigate that package's `.onLoad` and namespace initialization

### If Hypothesis 8B Confirmed (S3 method registration):
- S3 method registration or cross-namespace reference cleanup crashes
- Root cause is in R's S3 dispatch table management under WOW64
- Likely an R core issue, not fixable in rmarkdown

### If Hypothesis 8C Confirmed (specific import):
- One specific package (jquerylib, fontawesome, sass, etc.) triggers crash
- Next step: Deep dive into that package's initialization

### If All Tests Pass:
- All operations work individually but rmarkdown still crashes
- Suggests the issue is in **cumulative state** or interaction between multiple operations
- May need to test combinations of operations

## Differential Analysis: knitr vs rmarkdown

### What knitr does that works ✅:
- Imports: evaluate, highr, xfun, yaml (simple deps)
- No S3method declarations for external generics
- Simple `.onLoad` with no hook registration
- No bslib dependency

### What rmarkdown adds that might fail ❌:
- 9 additional imports including bslib (complex dep chain)
- 9 S3method declarations for external generics (cross-namespace refs)
- `.onLoad` with `setHook(packageEvent(...))` registration
- Depends on htmltools (brings rlang, fastmap, digest)

## Key Questions to Answer

1. **Does `loadNamespace()` behave differently from `library()` under WOW64?**
   - Test: loadnamespace approach
   - If yes: Root cause is in R's namespace loading mechanism

2. **Do cross-namespace S3 method registrations fail under WOW64?**
   - Test: S3 methods approach
   - If yes: R core issue with S3 dispatch table cleanup

3. **Which specific import triggers the crash?**
   - Test: Import order approach
   - If identified: Focus investigation on that package

4. **Is the issue in cumulative namespace state?**
   - If all individual tests pass but rmarkdown fails
   - Suggests interactions between multiple loaded namespaces

## Next Steps Based on Results

### If a specific operation is identified:
1. Create minimal reproduction case
2. Trace Windows API calls during that operation
3. Identify which API returns STATUS_NOT_SUPPORTED
4. Determine if issue is in R core or package code

### If issue remains elusive:
1. Attach debugger to R process on Windows ARM
2. Enable R debugging output: `R --vanilla --verbose`
3. Trace system calls during package loading
4. May require R internals expertise

## Related Documentation

- **NEXT-INVESTIGATION.md** - Phase 1-7 results and rejected hypotheses
- **RMARKDOWN-SOURCE-ANALYSIS.md** - Phase 4 source code analysis
- **INVESTIGATION-RESULTS.md** - Complete investigation findings

## Workflow

**File:** `.github/workflows/test-phase8-namespace-loading.yml`

Four jobs test each hypothesis independently on `windows-11-arm` runners with R x64 4.5.1.
