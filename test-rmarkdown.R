#!/usr/bin/env Rscript
# Test 3: R script loading rmarkdown package
# Expected: FAILURE on Windows ARM x64 (crash during termination)

cat("Loading rmarkdown package...\n")
library(rmarkdown)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("rmarkdown version: ", as.character(packageVersion("rmarkdown")), "\n", sep = "")
cat("Test: rmarkdown\n")
cat("Result: SUCCESS (if you see this, rmarkdown loaded successfully)\n")
