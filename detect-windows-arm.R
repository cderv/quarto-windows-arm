#!/usr/bin/env Rscript
# Demonstrates R x64 cannot detect Windows ARM via IsWow64Process2
#
# LIMITATION: R's .Call() FFI is designed for R's C API, not arbitrary
# Windows API calls. The IsWow64Process2 function requires pointer
# output parameters that .Call() doesn't handle correctly.
#
# Result: This detection FAILS on Windows ARM (returns FALSE when it
# should return TRUE), proving R scripts cannot self-detect ARM Windows.

is_windows_arm <- function() {
  if (.Platform$OS.type != "windows")
    return(FALSE)

  kernel32 <- "kernel32.dll"

  # Try to get IsWow64Process2 symbol (may not exist on older Windows)
  iswow64process2 <- tryCatch(
    getNativeSymbolInfo(
      name = "IsWow64Process2",
      PACKAGE = kernel32,
      withRegistrationInfo = FALSE
    ),
    error = function(e) NULL
  )

  if (is.null(iswow64process2))
    return(FALSE)

  processMachine <- as.integer(0)
  nativeMachine  <- as.integer(0)

  # KNOWN ISSUE: R's .Call() cannot properly handle Windows API pointer parameters
  # The following code WILL FAIL to detect ARM even on ARM Windows
  # Output parameters (processMachine, nativeMachine) are not modified
  res <- .Call(
    iswow64process2,
    getNativeSymbolInfo("GetCurrentProcess", kernel32),
    processMachine,
    nativeMachine
  )

  # IMAGE_FILE_MACHINE_ARM64 = 0xAA64 = 43620
  # This check always returns FALSE because nativeMachine is never updated
  nativeMachine == 0xAA64
}

# Test and display results
cat("=== Windows ARM Detection from R ===\n")
cat("OS Type:", .Platform$OS.type, "\n")
cat("R Platform:", R.version[["platform"]], "\n")
cat("R Version:", R.version[["version.string"]], "\n")
cat("\nIs Windows ARM:", is_windows_arm(), "\n")

# Additional diagnostic info
if (.Platform$OS.type == "windows") {
  cat("\nDiagnostic Info:\n")
  cat("- Running on Windows\n")

  # Check if we're running under WOW64
  kernel32 <- "kernel32.dll"
  iswow64 <- tryCatch(
    getNativeSymbolInfo(
      name = "IsWow64Process",
      PACKAGE = kernel32,
      withRegistrationInfo = FALSE
    ),
    error = function(e) NULL
  )

  if (!is.null(iswow64)) {
    result <- integer(1)
    .Call(
      iswow64,
      getNativeSymbolInfo("GetCurrentProcess", kernel32),
      result
    )
    cat("- IsWow64Process:", result == 1, "\n")
  }

  cat("- R Architecture:", .Platform$r_arch, "\n")
}
