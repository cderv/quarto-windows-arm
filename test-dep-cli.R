#!/usr/bin/env Rscript
# Test: rmarkdown DLL suspect - cli
# Expected: UNKNOWN on R x64 Windows ARM
#
# cli is loaded by rmarkdown but NOT by knitr.
# This is one of 5 DLLs unique to rmarkdown's dependency chain.

cat("Loading cli package...\n")
library(cli)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("cli version: ", as.character(packageVersion("cli")), "\n", sep = "")

cat("Test: test-dep-cli\n")
cat("Result: SUCCESS (if you see this, cli loads without crashing)\n")
