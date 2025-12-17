#!/usr/bin/env Rscript
# Test: Combination - rlang + htmltools
# Expected: UNKNOWN on R x64 Windows ARM
#
# These 2 packages are both loaded by rmarkdown but not by knitr.

cat("=== Testing combination: rlang + htmltools ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("\n")

cat("Loading rlang...\n")
library(rlang)
cat("  rlang version: ", as.character(packageVersion("rlang")), "\n", sep = "")

cat("Loading htmltools...\n")
library(htmltools)
cat("  htmltools version: ", as.character(packageVersion("htmltools")), "\n", sep = "")

cat("\nTest: test-combo-rlang-htmltools\n")
cat("Result: SUCCESS (if you see this, combination loads without crashing)\n")
