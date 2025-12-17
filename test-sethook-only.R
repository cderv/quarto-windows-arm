# Test: setHook() Mechanism in Isolation
#
# Purpose: Test if setHook(packageEvent(...)) alone causes crash
#
# This mimics what rmarkdown does in its .onLoad function:
#   setHook(packageEvent("knitr", "onLoad"), ...)
#
# Expected result if setHook is the root cause:
#   - Script completes successfully (prints "SUCCESS")
#   - Process crashes during R termination with exit code -1073741569
#
# Expected result if setHook is NOT the cause:
#   - Script completes successfully
#   - Process exits cleanly with exit code 0

cat("=== setHook() Isolation Test ===\n")
cat("\n")

cat("This test mimics what rmarkdown does in R/zzz.R:1-9\n")
cat("\n")

cat("Loading knitr (required for packageEvent)...\n")
library(knitr)
cat("  knitr loaded successfully\n")
cat("\n")

cat("Registering a persistent hook via setHook(packageEvent(...))...\n")
cat("This is EXACTLY what rmarkdown's .onLoad does:\n")
cat("\n")

# This mimics rmarkdown's registerMethods() which does:
# setHook(packageEvent(pkg, "onLoad"), function(...) { ... })
test_function <- function(...) {
  cat("Hook would be called here\n")
}

cat("Calling: setHook(packageEvent('knitr', 'onLoad'), test_function)\n")
setHook(packageEvent("knitr", "onLoad"), test_function)
cat("  Hook registered successfully\n")
cat("\n")

cat("Checking registered hooks...\n")
hooks <- getHook(packageEvent("knitr", "onLoad"))
cat("  Number of hooks registered:", length(hooks), "\n")
cat("  Hook function class:", class(hooks[[1]]), "\n")
cat("\n")

cat("=== SUCCESS: Script completed ===\n")
cat("\n")
cat("If this script crashes during termination, it CONFIRMS:\n")
cat("  The root cause is setHook(packageEvent(...)) registration/cleanup\n")
cat("  under WOW64 emulation on Windows ARM.\n")
cat("\n")
cat("If this script exits cleanly, it REJECTS our hypothesis:\n")
cat("  Something else in rmarkdown's .onLoad is the issue.\n")
cat("\n")
cat("Watch for exit code -1073741569 (STATUS_NOT_SUPPORTED).\n")
