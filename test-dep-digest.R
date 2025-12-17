#!/usr/bin/env Rscript
# Test: rmarkdown DLL suspect - digest
# Expected: UNKNOWN on R x64 Windows ARM
#
# digest is loaded by rmarkdown but NOT by knitr.
# This is one of 5 DLLs unique to rmarkdown's dependency chain.

cat("Loading digest package...\n")
library(digest)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("digest version: ", as.character(packageVersion("digest")), "\n", sep = "")

cat("Test: test-dep-digest\n")
cat("Result: SUCCESS (if you see this, digest loads without crashing)\n")
