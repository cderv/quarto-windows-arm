# Test: knitr Package in Isolation
#
# Purpose: Verify knitr alone works (we already know this, but need to confirm)
#
# knitr is known to work on R x64 Windows ARM from earlier testing.
# knitr also loads xfun (same as rmarkdown), but doesn't crash.
#
# This test helps us understand WHY knitr works when it loads the same
# xfun DLL that rmarkdown loads.
#
# Expected result:
#   - Script completes successfully
#   - Process exits cleanly with exit code 0
#
# If this crashes, something has changed since earlier testing.

cat("=== knitr Isolation Test ===\n")
cat("\n")

cat("Loading knitr package...\n")
library(knitr)
cat("  knitr loaded successfully\n")
cat("\n")

cat("Checking what was loaded...\n")
loaded <- loadedNamespaces()
packages_to_check <- c("knitr", "xfun", "evaluate", "highr", "yaml", "htmltools", "rmarkdown")
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
  cat("  ✓ xfun.dll is loaded (same as rmarkdown)\n")
  xfun_dll <- loaded_dlls[["xfun"]]
  cat("    Path:", xfun_dll[["path"]], "\n")
} else {
  cat("  ✗ xfun.dll is NOT loaded (unexpected!)\n")
}
cat("\n")

cat("=== SUCCESS: knitr loaded successfully ===\n")
cat("\n")
cat("knitr is known to work on R x64 Windows ARM.\n")
cat("knitr loads xfun (same DLL as rmarkdown), but doesn't crash.\n")
cat("\n")
cat("This helps us understand the differential behavior:\n")
cat("  - knitr + xfun = works ✓\n")
cat("  - rmarkdown + xfun = crashes ✗\n")
