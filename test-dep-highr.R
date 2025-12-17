#!/usr/bin/env Rscript
# Test: rmarkdown dependency - highr
# Expected: SUCCESS on R x64 Windows ARM (syntax highlighting, pure R)
# Used by: knitr

cat("Loading highr package...\n")
library(highr)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("highr version: ", as.character(packageVersion("highr")), "\n", sep = "")

cat("Test: test-dep-highr\n")
cat("Result: SUCCESS (if you see this, highr loads without crashing)\n")
