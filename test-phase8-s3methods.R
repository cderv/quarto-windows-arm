# Phase 8: Test S3 Method Registration Cross-Namespace
#
# HYPOTHESIS: The crash occurs during S3 method registration
#
# rmarkdown's NAMESPACE declares S3 methods for generics in other packages:
# - knit_print (knitr generic)
# - prepare_evaluate_output (evaluate generic)
#
# When R processes these S3method() declarations, it needs to:
# 1. Load the namespace where the generic is defined
# 2. Register the method in the S3 dispatch table
# 3. This is cross-namespace operation that might fail under WOW64

cat("\n=== Phase 8: Testing S3 Method Registration ===\n\n")

# Load the base namespaces
cat("Loading required namespaces:\n")
loadNamespace("evaluate")
cat("✓ evaluate (has generic: prepare_evaluate_output)\n")
loadNamespace("knitr")
cat("✓ knitr (has generic: knit_print)\n\n")

# Test manual S3 method registration (what R does during NAMESPACE processing)
cat("Test 1: Register S3 method for knitr generic\n")

# Create a dummy method function
knit_print.test_class <- function(x, ...) {
  cat("Test method called\n")
}

# Register it using registerS3method (what R does internally)
tryCatch({
  registerS3method("knit_print", "test_class", knit_print.test_class,
                   envir = asNamespace("knitr"))
  cat("✓ S3 method registered successfully\n\n")
}, error = function(e) {
  cat("✗ S3 method registration failed:", conditionMessage(e), "\n\n")
})

# Test calling the method
cat("Test 2: Call the registered method\n")
test_obj <- structure(list(), class = "test_class")
tryCatch({
  knitr::knit_print(test_obj)
  cat("✓ Method dispatch worked\n\n")
}, error = function(e) {
  cat("✗ Method dispatch failed:", conditionMessage(e), "\n\n")
})

# Test multiple registrations (rmarkdown has 4 knit_print methods)
cat("Test 3: Register multiple S3 methods (like rmarkdown does)\n")

knit_print.test_class2 <- function(x, ...) cat("Test 2\n")
knit_print.test_class3 <- function(x, ...) cat("Test 3\n")
knit_print.test_class4 <- function(x, ...) cat("Test 4\n")

tryCatch({
  registerS3method("knit_print", "test_class2", knit_print.test_class2,
                   envir = asNamespace("knitr"))
  registerS3method("knit_print", "test_class3", knit_print.test_class3,
                   envir = asNamespace("knitr"))
  registerS3method("knit_print", "test_class4", knit_print.test_class4,
                   envir = asNamespace("knitr"))
  cat("✓ Multiple S3 methods registered\n\n")
}, error = function(e) {
  cat("✗ Multiple registration failed:", conditionMessage(e), "\n\n")
})

# Test evaluate generic
cat("Test 4: Register method for evaluate generic\n")

prepare_evaluate_output.test_output <- function(x, ...) {
  cat("Evaluate method called\n")
  x
}

tryCatch({
  registerS3method("prepare_evaluate_output", "test_output",
                   prepare_evaluate_output.test_output,
                   envir = asNamespace("evaluate"))
  cat("✓ evaluate generic method registered\n\n")
}, error = function(e) {
  cat("✗ evaluate method registration failed:", conditionMessage(e), "\n\n")
})

cat("\n=== All S3 Methods Registered Successfully ===\n")
cat("If crash occurs, it's during R termination when cleaning up\n")
cat("the S3 method table or cross-namespace references.\n")
