# Phase 8: Identify which Import package causes crash
#
# Phase 5 showed crash occurs with:
# - evaluate, htmltools, knitr, xfun loaded (✓ working)
# - bslib NOT loaded (crash before it loads)
#
# Test hypothesis: One of the imports loaded BETWEEN the working set
# and bslib causes the crash.
#
# Candidates (rmarkdown Imports not in Phase 5 loaded set):
# - fontawesome
# - jquerylib
# - jsonlite
# - tinytex
# - yaml
# - methods/tools/utils (base packages, unlikely)
# - bslib itself

cat("\n=== Phase 8: Testing Import Load Order ===\n\n")

# Test 1: Working baseline (Phase 5 confirmed working)
cat("Test 1: Known working set (htmltools + knitr + xfun + evaluate)\n")
library(htmltools)
library(knitr)
library(xfun)
library(evaluate)
cat("✓ Baseline working set loaded successfully\n\n")

# Test 2: Add fontawesome
cat("Test 2: + fontawesome\n")
tryCatch({
  library(fontawesome)
  cat("✓ fontawesome loaded\n\n")
}, error = function(e) {
  cat("✗ fontawesome failed:", conditionMessage(e), "\n\n")
})

# Test 3: Add jquerylib
cat("Test 3: + jquerylib\n")
tryCatch({
  library(jquerylib)
  cat("✓ jquerylib loaded\n\n")
}, error = function(e) {
  cat("✗ jquerylib failed:", conditionMessage(e), "\n\n")
})

# Test 4: Add jsonlite
cat("Test 4: + jsonlite\n")
tryCatch({
  library(jsonlite)
  cat("✓ jsonlite loaded\n\n")
}, error = function(e) {
  cat("✗ jsonlite failed:", conditionMessage(e), "\n\n")
})

# Test 5: Add tinytex
cat("Test 5: + tinytex\n")
tryCatch({
  library(tinytex)
  cat("✓ tinytex loaded\n\n")
}, error = function(e) {
  cat("✗ tinytex failed:", conditionMessage(e), "\n\n")
})

# Test 6: Add yaml
cat("Test 6: + yaml\n")
tryCatch({
  library(yaml)
  cat("✓ yaml loaded\n\n")
}, error = function(e) {
  cat("✗ yaml failed:", conditionMessage(e), "\n\n")
})

# Test 7: Finally try bslib
cat("Test 7: + bslib (this should be where Phase 5 crashed)\n")
tryCatch({
  library(bslib)
  cat("✓ bslib loaded\n\n")
}, error = function(e) {
  cat("✗ bslib failed:", conditionMessage(e), "\n\n")
})

cat("\n=== Test Complete ===\n")
cat("If this script exits cleanly, all packages loaded successfully.\n")
cat("If crash occurs, it's during R termination (cleanup phase).\n")
