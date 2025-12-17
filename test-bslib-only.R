# Test: bslib Package in Isolation
#
# Purpose: Determine if bslib alone (without rmarkdown) causes crash on R x64 Windows ARM
#
# Expected result if bslib is the root cause:
#   - Script completes successfully (prints "SUCCESS")
#   - Process crashes during R termination with exit code -1073741569
#
# Expected result if bslib is NOT the root cause:
#   - Script completes successfully
#   - Process exits cleanly with exit code 0

cat("=== bslib Isolation Test ===\n")
cat("\n")

cat("Loading bslib package...\n")
library(bslib)
cat("  bslib loaded successfully\n")
cat("\n")

cat("Getting current global theme...\n")
old_theme <- bs_global_get()
cat("  Old theme class:", class(old_theme), "\n")
cat("  Old theme:", if (is.null(old_theme)) "NULL" else "set", "\n")
cat("\n")

cat("Creating new theme with custom colors...\n")
new_theme <- bs_theme(bg = "#000000", fg = "#FFFFFF", primary = "#FF0000")
cat("  New theme created\n")
cat("\n")

cat("Setting new global theme...\n")
bs_global_set(new_theme)
cat("  Global theme set successfully\n")
cat("\n")

cat("Verifying theme was set...\n")
current_theme <- bs_global_get()
cat("  Current theme class:", class(current_theme), "\n")
cat("\n")

cat("=== SUCCESS: Script completed ===\n")
cat("\n")
cat("If this script crashes, the crash will occur during R termination.\n")
cat("Watch for exit code -1073741569 (STATUS_NOT_SUPPORTED).\n")
