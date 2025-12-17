#!/usr/bin/env Rscript
# Test: Combination - All 5 suspect DLLs
# Expected: FAILURE on R x64 Windows ARM
#
# These 5 packages are loaded by rmarkdown but not by knitr:
# cli, digest, fastmap, htmltools, rlang
#
# If these 5 together cause the crash (but individuals don't),
# it suggests cleanup ordering or interdependency issues.

cat("=== Testing combination: All 5 suspect DLLs ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("\n")

cat("Loading cli...\n")
library(cli)
cat("  cli version: ", as.character(packageVersion("cli")), "\n", sep = "")

cat("Loading digest...\n")
library(digest)
cat("  digest version: ", as.character(packageVersion("digest")), "\n", sep = "")

cat("Loading fastmap...\n")
library(fastmap)
cat("  fastmap version: ", as.character(packageVersion("fastmap")), "\n", sep = "")

cat("Loading htmltools...\n")
library(htmltools)
cat("  htmltools version: ", as.character(packageVersion("htmltools")), "\n", sep = "")

cat("Loading rlang...\n")
library(rlang)
cat("  rlang version: ", as.character(packageVersion("rlang")), "\n", sep = "")

cat("\nAll 5 packages loaded successfully\n")
cat("\nTest: test-combo-all-five\n")
cat("Result: SUCCESS (if you see this, script completed before crash)\n")
cat("Note: Crash may occur during process termination\n")
