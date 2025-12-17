#!/usr/bin/env Rscript
# Test: Combination - fastmap + htmltools
# Expected: UNKNOWN on R x64 Windows ARM
#
# These 2 packages are both loaded by rmarkdown but not by knitr.

cat("=== Testing combination: fastmap + htmltools ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("\n")

cat("Loading fastmap...\n")
library(fastmap)
cat("  fastmap version: ", as.character(packageVersion("fastmap")), "\n", sep = "")

cat("Loading htmltools...\n")
library(htmltools)
cat("  htmltools version: ", as.character(packageVersion("htmltools")), "\n", sep = "")

cat("\nTest: test-combo-fastmap-htmltools\n")
cat("Result: SUCCESS (if you see this, combination loads without crashing)\n")
