#!/usr/bin/env Rscript
# Test: Combination - cli + htmltools
# Expected: UNKNOWN on R x64 Windows ARM
#
# These 2 packages are both loaded by rmarkdown but not by knitr.

cat("=== Testing combination: cli + htmltools ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("\n")

cat("Loading cli...\n")
library(cli)
cat("  cli version: ", as.character(packageVersion("cli")), "\n", sep = "")

cat("Loading htmltools...\n")
library(htmltools)
cat("  htmltools version: ", as.character(packageVersion("htmltools")), "\n", sep = "")

cat("\nTest: test-combo-cli-htmltools\n")
cat("Result: SUCCESS (if you see this, combination loads without crashing)\n")
