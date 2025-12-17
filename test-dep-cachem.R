#!/usr/bin/env Rscript
# Test: rmarkdown dependency - cachem
# Expected: UNKNOWN on R x64 Windows ARM
# Used by: bslib, memoise

cat("Loading cachem package...\n")
library(cachem)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("cachem version: ", as.character(packageVersion("cachem")), "\n", sep = "")

cat("Test: test-dep-cachem\n")
cat("Result: SUCCESS (if you see this, cachem loads without crashing)\n")
