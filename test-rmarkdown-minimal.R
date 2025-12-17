# Test: Minimal rmarkdown Loading
#
# Purpose: Load rmarkdown without calling any functions to see if crash occurs
#
# Expected result if bslib is the root cause:
#   - Script completes successfully (prints "SUCCESS")
#   - Process crashes during R termination with exit code -1073741569
#   - This would prove that just loading rmarkdown (which loads bslib) causes the crash
#
# Expected result if bslib is NOT the root cause:
#   - Script completes successfully
#   - Process exits cleanly with exit code 0

cat("=== Minimal rmarkdown Loading Test ===\n")
cat("\n")

cat("Loading rmarkdown package (no function calls)...\n")
library(rmarkdown)
cat("  rmarkdown loaded successfully\n")
cat("\n")

cat("Checking what was initialized...\n")
cat("  .render_context exists:", exists(".render_context", envir = asNamespace("rmarkdown")), "\n")

# Check if internal state was initialized
if (exists(".render_context", envir = asNamespace("rmarkdown"))) {
  cat("  .render_context is a stack (expected)\n")
}
cat("\n")

cat("Checking if bslib was loaded as a dependency...\n")
if ("bslib" %in% loadedNamespaces()) {
  cat("  ✓ bslib is loaded (as expected - rmarkdown imports it)\n")
  cat("\n")

  cat("Checking bslib global state...\n")
  theme <- bslib::bs_global_get()
  cat("  Global theme class:", class(theme), "\n")
  cat("  Global theme value:", if (is.null(theme)) "NULL (default)" else "set", "\n")
} else {
  cat("  ✗ bslib is NOT loaded (unexpected!)\n")
}
cat("\n")

cat("Checking which packages were loaded:\n")
loaded <- loadedNamespaces()
rmarkdown_deps <- c("bslib", "htmltools", "knitr", "jsonlite", "yaml",
                    "xfun", "tinytex", "evaluate", "fontawesome", "jquerylib")
for (pkg in rmarkdown_deps) {
  status <- if (pkg %in% loaded) "✓" else "✗"
  cat("  ", status, pkg, "\n")
}
cat("\n")

cat("=== SUCCESS: rmarkdown loaded minimally ===\n")
cat("\n")
cat("No functions were called, only library(rmarkdown) executed.\n")
cat("If this script crashes during termination, the issue is in:\n")
cat("  - Package loading itself, OR\n")
cat("  - Cleanup of loaded dependencies (specifically bslib)\n")
cat("\n")
cat("Watch for exit code -1073741569 (STATUS_NOT_SUPPORTED).\n")
