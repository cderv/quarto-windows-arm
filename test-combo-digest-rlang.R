#!/usr/bin/env Rscript
# Test: Combination - digest + rlang
# Expected: UNKNOWN on R x64 Windows ARM
#
# These 2 packages are both loaded by rmarkdown but not by knitr.

cat("=== Testing combination: digest + rlang ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("\n")

cat("Loading digest...\n")
library(digest)
cat("  digest version: ", as.character(packageVersion("digest")), "\n", sep = "")

cat("Loading rlang...\n")
library(rlang)
cat("  rlang version: ", as.character(packageVersion("rlang")), "\n", sep = "")

cat("\nTest: test-combo-digest-rlang\n")
cat("Result: SUCCESS (if you see this, combination loads without crashing)\n")
