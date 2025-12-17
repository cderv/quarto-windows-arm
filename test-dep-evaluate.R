#!/usr/bin/env Rscript
# Test: rmarkdown dependency - evaluate
# Expected: UNKNOWN on R x64 Windows ARM (medium suspect - code evaluation)

cat("Loading evaluate package...\n")
library(evaluate)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("evaluate version: ", as.character(packageVersion("evaluate")), "\n", sep = "")

cat("Test: test-dep-evaluate\n")
cat("Result: SUCCESS (if you see this, evaluate loads without crashing)\n")
