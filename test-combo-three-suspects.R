#!/usr/bin/env Rscript
# Test: Combination - Top 3 most complex DLLs
# Expected: UNKNOWN on R x64 Windows ARM
#
# Testing the 3 most likely suspects together:
# - cli (complex console interactions)
# - htmltools (native HTML generation)
# - rlang (low-level R internals)

cat("=== Testing combination: cli + htmltools + rlang ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("\n")

cat("Loading cli...\n")
library(cli)
cat("  cli version: ", as.character(packageVersion("cli")), "\n", sep = "")

cat("Loading htmltools...\n")
library(htmltools)
cat("  htmltools version: ", as.character(packageVersion("htmltools")), "\n", sep = "")

cat("Loading rlang...\n")
library(rlang)
cat("  rlang version: ", as.character(packageVersion("rlang")), "\n", sep = "")

cat("\nTest: test-combo-three-suspects\n")
cat("Result: SUCCESS (if you see this, combination loads without crashing)\n")
