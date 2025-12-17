#!/usr/bin/env Rscript
# Test: DLLs after loading knitr (known to work)
# Expected: SUCCESS on R x64 Windows ARM
#
# Purpose: Document which DLLs knitr loads. This is the "working" comparison case.
# Compare against baseline to see knitr-specific DLLs.
# Compare against rmarkdown to identify what's different about rmarkdown.

cat("=== DLLs after loading knitr ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("\n")

cat("Loading knitr...\n")
library(knitr)
cat("knitr version: ", as.character(packageVersion("knitr")), "\n", sep = "")
cat("\n")

dlls <- getLoadedDLLs()
cat("Loaded DLLs:\n")
for (dll_name in sort(names(dlls))) {
  dll <- dlls[[dll_name]]
  cat(sprintf("  %-20s %s\n", dll_name, dll[["path"]]))
}

cat("\nTotal DLLs: ", length(dlls), "\n", sep = "")
cat("\nTest: test-dlls-knitr\n")
cat("Result: SUCCESS (if you see this, knitr loads without crashing)\n")
