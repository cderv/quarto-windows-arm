#!/usr/bin/env Rscript
# Test 4: R script loading both knitr and rmarkdown
# Expected: FAILURE on Windows ARM x64 (crash during termination)
# This mimics what Quarto's knitr.R capabilities script does

cat("Loading knitr and rmarkdown packages...\n")
library(knitr)
library(rmarkdown)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("knitr version: ", as.character(packageVersion("knitr")), "\n", sep = "")
cat("rmarkdown version: ", as.character(packageVersion("rmarkdown")), "\n", sep = "")
cat("Test: both\n")
cat("Result: SUCCESS (if you see this, both packages loaded successfully)\n")
