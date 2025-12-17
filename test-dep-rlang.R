#!/usr/bin/env Rscript
# Test: rmarkdown DLL suspect - rlang
# Expected: UNKNOWN on R x64 Windows ARM
#
# rlang is loaded by rmarkdown but NOT by knitr.
# This is one of 5 DLLs unique to rmarkdown's dependency chain.

cat("Loading rlang package...\n")
library(rlang)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("rlang version: ", as.character(packageVersion("rlang")), "\n", sep = "")

cat("Test: test-dep-rlang\n")
cat("Result: SUCCESS (if you see this, rlang loads without crashing)\n")
