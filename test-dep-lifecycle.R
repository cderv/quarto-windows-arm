#!/usr/bin/env Rscript
# Test: rmarkdown dependency - lifecycle
# Expected: UNKNOWN on R x64 Windows ARM
# Used by: bslib

cat("Loading lifecycle package...\n")
library(lifecycle)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("lifecycle version: ", as.character(packageVersion("lifecycle")), "\n", sep = "")

cat("Test: test-dep-lifecycle\n")
cat("Result: SUCCESS (if you see this, lifecycle loads without crashing)\n")
