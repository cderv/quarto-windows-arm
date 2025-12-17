#!/usr/bin/env Rscript
# Test: rmarkdown dependency - glue
# Expected: SUCCESS on R x64 Windows ARM (string interpolation)
# Used by: lifecycle, cli

cat("Loading glue package...\n")
library(glue)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("glue version: ", as.character(packageVersion("glue")), "\n", sep = "")

cat("Test: test-dep-glue\n")
cat("Result: SUCCESS (if you see this, glue loads without crashing)\n")
