#!/usr/bin/env Rscript
# Test: rmarkdown DLL suspect - fastmap
# Expected: UNKNOWN on R x64 Windows ARM
#
# fastmap is loaded by rmarkdown but NOT by knitr.
# This is one of 5 DLLs unique to rmarkdown's dependency chain.

cat("Loading fastmap package...\n")
library(fastmap)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("fastmap version: ", as.character(packageVersion("fastmap")), "\n", sep = "")

cat("Test: test-dep-fastmap\n")
cat("Result: SUCCESS (if you see this, fastmap loads without crashing)\n")
