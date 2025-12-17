#!/usr/bin/env Rscript
# Test: DLLs after loading rmarkdown (known to crash)
# Expected: FAILURE on R x64 Windows ARM (exit -1073741569)
#
# Purpose: Document which DLLs rmarkdown loads before the crash.
# The crash occurs during process termination, AFTER this script completes.
# Compare output against baseline and knitr to identify rmarkdown-specific DLLs.
# These rmarkdown-specific DLLs are the prime suspects for WOW64 incompatibility.

cat("=== DLLs after loading rmarkdown ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("\n")

cat("Loading rmarkdown...\n")
library(rmarkdown)
cat("rmarkdown version: ", as.character(packageVersion("rmarkdown")), "\n", sep = "")
cat("\n")

dlls <- getLoadedDLLs()
cat("Loaded DLLs:\n")
for (dll_name in sort(names(dlls))) {
  dll <- dlls[[dll_name]]
  cat(sprintf("  %-20s %s\n", dll_name, dll[["path"]]))
}

cat("\nTotal DLLs: ", length(dlls), "\n", sep = "")
cat("\nTest: test-dlls-rmarkdown\n")
cat("Result: SUCCESS (if you see this, script completed before crash)\n")
cat("Note: Crash occurs during process termination, not during execution\n")
