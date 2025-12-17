# Phase 9: Test if bslib + knitr combination crashes
#
# HYPOTHESIS: The crash is triggered by loading bslib + knitr together,
# not by rmarkdown's code itself.
#
# This would explain:
# - Why knitr alone works (no bslib)
# - Why bslib alone works (tested in Phase 1)
# - Why rmarkdown crashes (has both as dependencies)

cat("\n=== Phase 9: Testing bslib + knitr Combination ===\n\n")

# Test 1: knitr alone (known to work)
cat("Test 1: knitr alone (baseline)\n")
library(knitr)
cat("✓ knitr loaded\n\n")

# Test 2: Add bslib (this is what rmarkdown does)
cat("Test 2: + bslib (critical test)\n")
library(bslib)
cat("✓ bslib loaded\n\n")

cat("=== Both packages loaded successfully ===\n")
cat("If crash occurs, it's during R termination.\n")
cat("\nThis would prove the issue is the bslib + knitr combination,\n")
cat("not rmarkdown's code itself.\n")
