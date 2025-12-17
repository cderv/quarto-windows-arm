#!/usr/bin/env Rscript
# Test: rmarkdown dependency - rappdirs
# Expected: UNKNOWN on R x64 Windows ARM
# Used by: sass

cat("Loading rappdirs package...\n")
library(rappdirs)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("rappdirs version: ", as.character(packageVersion("rappdirs")), "\n", sep = "")

cat("Test: test-dep-rappdirs\n")
cat("Result: SUCCESS (if you see this, rappdirs loads without crashing)\n")
