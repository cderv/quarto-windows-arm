#!/usr/bin/env Rscript
# Test 2: R script loading knitr package
# Expected: FAILURE on Windows ARM x64 (crash during termination)

cat("Loading knitr package...\n")
library(knitr)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("knitr version: ", as.character(packageVersion("knitr")), "\n", sep = "")
cat("Test: knitr\n")
cat("Result: SUCCESS (if you see this, knitr loaded successfully)\n")
