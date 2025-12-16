#!/usr/bin/env Rscript
# Detect Windows ARM from x64 R process
# Uses IsWow64Process2 Windows API to get native architecture

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

  res <- .Call(
    iswow64process2,
    getNativeSymbolInfo("GetCurrentProcess", kernel32),
    processMachine,
    nativeMachine
  )

  # IMAGE_FILE_MACHINE_ARM64 = 0xAA64 = 43620
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
