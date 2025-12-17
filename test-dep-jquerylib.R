#!/usr/bin/env Rscript
# Test: rmarkdown dependency - jquerylib
# Expected: SUCCESS on R x64 Windows ARM (low suspect - JavaScript assets)

cat("Loading jquerylib package...\n")
library(jquerylib)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("jquerylib version: ", as.character(packageVersion("jquerylib")), "\n", sep = "")

cat("Test: test-dep-jquerylib\n")
cat("Result: SUCCESS (if you see this, jquerylib loads without crashing)\n")
