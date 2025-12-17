# Test: Minimal Package Combination (without rmarkdown)
#
# Purpose: Test if the specific combination of packages causes crash
#
# Phase 5 showed these packages were loaded when rmarkdown crashed:
#   - htmltools
#   - knitr
#   - xfun (only one with compiled C code)
#   - evaluate
#
# This test loads the same combination WITHOUT rmarkdown to see if
# the crash is in the package combination or in rmarkdown's .onLoad hook.
#
# Expected result if combination is the cause:
#   - Script completes successfully (prints "SUCCESS")
#   - Process crashes during R termination with exit code -1073741569
#
# Expected result if rmarkdown's .onLoad is the cause:
#   - Script completes successfully
#   - Process exits cleanly with exit code 0

cat("=== Minimal Package Combination Test ===\n")
cat("\n")

cat("Loading packages in the same order as rmarkdown...\n")
cat("\n")

cat("1. Loading htmltools...\n")
library(htmltools)
cat("   htmltools loaded successfully\n")
cat("\n")

cat("2. Loading knitr...\n")
library(knitr)
cat("   knitr loaded successfully\n")
cat("\n")

cat("3. Loading xfun...\n")
library(xfun)
cat("   xfun loaded successfully\n")
cat("\n")

cat("4. Loading evaluate...\n")
library(evaluate)
cat("   evaluate loaded successfully\n")
cat("\n")

cat("Checking what's loaded...\n")
loaded <- loadedNamespaces()
packages_to_check <- c("htmltools", "knitr", "xfun", "evaluate", "rmarkdown", "bslib")
for (pkg in packages_to_check) {
  status <- if (pkg %in% loaded) "✓" else "✗"
  cat("  ", status, pkg, "\n")
}
cat("\n")

cat("Checking loaded DLLs...\n")
loaded_dlls <- getLoadedDLLs()
dll_names <- names(loaded_dlls)
cat("  Total DLLs loaded:", length(dll_names), "\n")
if ("xfun" %in% dll_names) {
  cat("  ✓ xfun.dll is loaded\n")
}
cat("\n")

cat("=== SUCCESS: Package combination loaded ===\n")
cat("\n")
cat("This combination matches what was loaded when rmarkdown crashed.\n")
cat("If this crashes, the issue is in the package combination.\n")
cat("If this passes, the issue is in rmarkdown's .onLoad hook.\n")
cat("\n")
cat("Watch for exit code -1073741569 (STATUS_NOT_SUPPORTED).\n")
