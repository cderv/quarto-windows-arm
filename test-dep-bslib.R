#!/usr/bin/env Rscript
# Test: rmarkdown dependency - bslib
# Expected: UNKNOWN on R x64 Windows ARM (HIGH SUSPECT - native code)

cat("Loading bslib package...\n")
library(bslib)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("bslib version: ", as.character(packageVersion("bslib")), "\n", sep = "")

cat("Test: test-dep-bslib\n")
cat("Result: SUCCESS (if you see this, bslib loads without crashing)\n")
