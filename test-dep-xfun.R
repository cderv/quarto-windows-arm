#!/usr/bin/env Rscript
# Test: rmarkdown dependency - xfun
# Expected: UNKNOWN on R x64 Windows ARM (medium suspect - utility functions)

cat("Loading xfun package...\n")
library(xfun)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("xfun version: ", as.character(packageVersion("xfun")), "\n", sep = "")

cat("Test: test-dep-xfun\n")
cat("Result: SUCCESS (if you see this, xfun loads without crashing)\n")
