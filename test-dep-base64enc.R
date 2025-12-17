#!/usr/bin/env Rscript
# Test: rmarkdown dependency - base64enc
# Expected: UNKNOWN on R x64 Windows ARM
# Used by: htmltools, bslib

cat("Loading base64enc package...\n")
library(base64enc)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("base64enc version: ", as.character(packageVersion("base64enc")), "\n", sep = "")

cat("Test: test-dep-base64enc\n")
cat("Result: SUCCESS (if you see this, base64enc loads without crashing)\n")
