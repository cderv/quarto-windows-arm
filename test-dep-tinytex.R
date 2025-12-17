#!/usr/bin/env Rscript
# Test: rmarkdown dependency - tinytex
# Expected: UNKNOWN on R x64 Windows ARM (HIGH SUSPECT - Pandoc integration)

cat("Loading tinytex package...\n")
library(tinytex)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("tinytex version: ", as.character(packageVersion("tinytex")), "\n", sep = "")

cat("Test: test-dep-tinytex\n")
cat("Result: SUCCESS (if you see this, tinytex loads without crashing)\n")
