#!/usr/bin/env Rscript
# Test: rmarkdown dependency - R6
# Expected: SUCCESS on R x64 Windows ARM (pure R OOP system)
# Used by: sass

cat("Loading R6 package...\n")
library(R6)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("R6 version: ", as.character(packageVersion("R6")), "\n", sep = "")

cat("Test: test-dep-r6\n")
cat("Result: SUCCESS (if you see this, R6 loads without crashing)\n")
