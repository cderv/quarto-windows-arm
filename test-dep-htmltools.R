#!/usr/bin/env Rscript
# Test: rmarkdown dependency - htmltools
# Expected: UNKNOWN on R x64 Windows ARM (HIGH SUSPECT - native code)

cat("Loading htmltools package...\n")
library(htmltools)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("htmltools version: ", as.character(packageVersion("htmltools")), "\n", sep = "")

cat("Test: test-dep-htmltools\n")
cat("Result: SUCCESS (if you see this, htmltools loads without crashing)\n")
