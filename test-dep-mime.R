#!/usr/bin/env Rscript
# Test: rmarkdown dependency - mime
# Expected: UNKNOWN on R x64 Windows ARM
# Used by: bslib

cat("Loading mime package...\n")
library(mime)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("mime version: ", as.character(packageVersion("mime")), "\n", sep = "")

cat("Test: test-dep-mime\n")
cat("Result: SUCCESS (if you see this, mime loads without crashing)\n")
