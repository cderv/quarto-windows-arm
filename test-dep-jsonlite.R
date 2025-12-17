#!/usr/bin/env Rscript
# Test: rmarkdown dependency - jsonlite
# Expected: SUCCESS on R x64 Windows ARM (low suspect - pure R/C without complex cleanup)

cat("Loading jsonlite package...\n")
library(jsonlite)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("jsonlite version: ", as.character(packageVersion("jsonlite")), "\n", sep = "")

cat("Test: test-dep-jsonlite\n")
cat("Result: SUCCESS (if you see this, jsonlite loads without crashing)\n")
