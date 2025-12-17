#!/usr/bin/env Rscript
# Test: rmarkdown dependency - memoise
# Expected: UNKNOWN on R x64 Windows ARM
# Used by: bslib

cat("Loading memoise package...\n")
library(memoise)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("memoise version: ", as.character(packageVersion("memoise")), "\n", sep = "")

cat("Test: test-dep-memoise\n")
cat("Result: SUCCESS (if you see this, memoise loads without crashing)\n")
