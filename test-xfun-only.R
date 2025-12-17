# Test: xfun Package in Isolation
#
# Purpose: Determine if xfun alone causes crash on R x64 Windows ARM
#
# xfun is the ONLY package with compiled C code (DLL) that was loaded
# when rmarkdown crashed in Phase 5 testing.
#
# Expected result if xfun is the root cause:
#   - Script completes successfully (prints "SUCCESS")
#   - Process crashes during R termination with exit code -1073741569
#
# Expected result if xfun is NOT the root cause:
#   - Script completes successfully
#   - Process exits cleanly with exit code 0

cat("=== xfun Isolation Test ===\n")
cat("\n")

cat("Loading xfun package...\n")
library(xfun)
cat("  xfun loaded successfully\n")
cat("\n")

cat("Using xfun functions to ensure DLL is loaded...\n")
cat("  Testing base64_encode() with file...\n")
temp_file1 <- tempfile()
writeLines("test data", temp_file1)
result <- base64_encode(temp_file1)
cat("    Result:", result, "\n")
unlink(temp_file1)
cat("\n")

cat("  Testing read_utf8()...\n")
temp_file2 <- tempfile()
writeLines("test content", temp_file2)
content <- read_utf8(temp_file2)
cat("    Content:", content, "\n")
unlink(temp_file2)
cat("\n")

cat("Checking loaded DLLs...\n")
loaded_dlls <- getLoadedDLLs()
if ("xfun" %in% names(loaded_dlls)) {
  cat("  ✓ xfun.dll is loaded\n")
  xfun_dll <- loaded_dlls[["xfun"]]
  cat("    Path:", xfun_dll[["path"]], "\n")
} else {
  cat("  ✗ xfun.dll is NOT loaded (unexpected!)\n")
}
cat("\n")

cat("=== SUCCESS: Script completed ===\n")
cat("\n")
cat("If this script crashes, the crash will occur during R termination.\n")
cat("Watch for exit code -1073741569 (STATUS_NOT_SUPPORTED).\n")
