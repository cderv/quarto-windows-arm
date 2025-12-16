#!/usr/bin/env Rscript
# Comprehensive R script test suite for Windows ARM x64 emulation
# Tests different levels of complexity to isolate crash conditions

cat("=== R Script Test Suite ===\n\n")

# Test 1: Simple script (no packages)
test_simple <- function() {
  cat("Test 1: Simple R operations (no packages)\n")
  result <- list(
    test = "simple",
    platform = R.version[['platform']],
    version = R.version[['version.string']],
    calculation = 2 + 2
  )
  cat(yaml::as.yaml(result))
  cat("Test 1: PASSED\n\n")
}

# Test 2: Load knitr only
test_knitr <- function() {
  cat("Test 2: Loading knitr package\n")
  library(knitr)
  result <- list(
    test = "knitr",
    platform = R.version[['platform']],
    knitr_version = as.character(packageVersion("knitr"))
  )
  cat(yaml::as.yaml(result))
  cat("Test 2: PASSED\n\n")
}

# Test 3: Load rmarkdown only
test_rmarkdown <- function() {
  cat("Test 3: Loading rmarkdown package\n")
  library(rmarkdown)
  result <- list(
    test = "rmarkdown",
    platform = R.version[['platform']],
    rmarkdown_version = as.character(packageVersion("rmarkdown"))
  )
  cat(yaml::as.yaml(result))
  cat("Test 3: PASSED\n\n")
}

# Test 4: Load both (like Quarto's knitr.R)
test_both <- function() {
  cat("Test 4: Loading both knitr and rmarkdown\n")
  library(knitr)
  library(rmarkdown)
  result <- list(
    test = "both",
    platform = R.version[['platform']],
    knitr_version = as.character(packageVersion("knitr")),
    rmarkdown_version = as.character(packageVersion("rmarkdown"))
  )
  cat(yaml::as.yaml(result))
  cat("Test 4: PASSED\n\n")
}

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
test_name <- if (length(args) > 0) args[1] else "all"

# Run requested test
if (test_name == "simple") {
  test_simple()
} else if (test_name == "knitr") {
  test_knitr()
} else if (test_name == "rmarkdown") {
  test_rmarkdown()
} else if (test_name == "both") {
  test_both()
} else if (test_name == "all") {
  test_simple()
  test_knitr()
  test_rmarkdown()
  test_both()
} else {
  cat("Usage: Rscript test-r-scripts.R [simple|knitr|rmarkdown|both|all]\n")
  quit(status = 1)
}

cat("=== All requested tests completed ===\n")
