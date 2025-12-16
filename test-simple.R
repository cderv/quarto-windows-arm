#!/usr/bin/env Rscript
# Test 1: Simple R script with no package loading
# Expected: SUCCESS on Windows ARM x64

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("Calculation: 2 + 2 = ", 2 + 2, "\n", sep = "")
cat("Test: simple\n")
cat("Result: SUCCESS\n")
