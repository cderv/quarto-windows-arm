#!/usr/bin/env Rscript
# Test: rmarkdown dependency - fs
# Expected: UNKNOWN on R x64 Windows ARM (SUSPECT - file system operations)
# Used by: sass

cat("Loading fs package...\n")
library(fs)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("fs version: ", as.character(packageVersion("fs")), "\n", sep = "")

cat("Test: test-dep-fs\n")
cat("Result: SUCCESS (if you see this, fs loads without crashing)\n")
