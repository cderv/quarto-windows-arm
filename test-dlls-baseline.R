#!/usr/bin/env Rscript
# Test: Baseline DLLs (no packages loaded)
# Expected: SUCCESS on all platforms
#
# Purpose: Establish baseline of which DLLs are loaded by R itself before any packages.
# This allows comparison with knitr and rmarkdown to identify package-specific DLLs.

cat("=== Baseline DLLs (no packages loaded) ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("\n")

dlls <- getLoadedDLLs()
cat("Loaded DLLs:\n")
for (dll_name in sort(names(dlls))) {
  dll <- dlls[[dll_name]]
  cat(sprintf("  %-20s %s\n", dll_name, dll[["path"]]))
}

cat("\nTotal DLLs: ", length(dlls), "\n", sep = "")
cat("\nTest: test-dlls-baseline\n")
cat("Result: SUCCESS\n")
