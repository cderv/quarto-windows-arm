#!/usr/bin/env Rscript
# Test: rmarkdown dependency - fontawesome
# Expected: UNKNOWN on R x64 Windows ARM
# Direct dependency of rmarkdown

cat("Loading fontawesome package...\n")
library(fontawesome)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("fontawesome version: ", as.character(packageVersion("fontawesome")), "\n", sep = "")

cat("Test: test-dep-fontawesome\n")
cat("Result: SUCCESS (if you see this, fontawesome loads without crashing)\n")
