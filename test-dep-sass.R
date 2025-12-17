#!/usr/bin/env Rscript
# Test: rmarkdown dependency - sass
# Expected: UNKNOWN on R x64 Windows ARM (HIGH SUSPECT - native Sass compiler)
# Used by: bslib

cat("Loading sass package...\n")
library(sass)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("sass version: ", as.character(packageVersion("sass")), "\n", sep = "")

cat("Test: test-dep-sass\n")
cat("Result: SUCCESS (if you see this, sass loads without crashing)\n")
