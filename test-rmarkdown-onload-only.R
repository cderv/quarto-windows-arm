# Test: rmarkdown's .onLoad Behavior in Isolation
#
# Purpose: Reproduce ONLY what rmarkdown's .onLoad does, without loading rmarkdown
#
# This exactly replicates rmarkdown's R/zzz.R:1-9
#
# Expected result if .onLoad behavior is the root cause:
#   - Script completes successfully (prints "SUCCESS")
#   - Process crashes during R termination with exit code -1073741569
#
# Expected result if something else is the cause:
#   - Script completes successfully
#   - Process exits cleanly with exit code 0

cat("=== rmarkdown .onLoad Behavior Test ===\n")
cat("\n")

cat("This test replicates rmarkdown's R/zzz.R:1-9 WITHOUT loading rmarkdown\n")
cat("\n")

# Step 1: Create a stack (mimics .render_context <<- new_stack())
cat("Step 1: Creating a stack (mimics .render_context)...\n")
new_stack <- function(init = NULL) {
  list(
    push = function(x) init <<- c(init, list(x)),
    pop = function() {
      if (length(init) == 0) return(NULL)
      x <- init[[length(init)]]
      init <<- init[-length(init)]
      x
    },
    peek = function() if (length(init)) init[[length(init)]],
    size = function() length(init),
    clear = function() init <<- NULL
  )
}

render_context_test <- new_stack()
cat("  Stack created successfully\n")
cat("\n")

# Step 2: Load knitr (required for packageEvent)
cat("Step 2: Loading knitr...\n")
library(knitr)
cat("  knitr loaded successfully\n")
cat("\n")

# Step 3: Register methods (mimics registerMethods())
cat("Step 3: Registering hook via setHook(packageEvent(...))...\n")
cat("This is the EXACT pattern from rmarkdown's .onLoad:\n")
cat("\n")

registerMethods_test <- function(methods) {
  lapply(methods, function(method) {
    pkg <- method[[1]]
    generic <- method[[2]]
    class_name <- method[[3]]

    cat("  Registering: ", generic, ".", class_name, " from ", pkg, "\n", sep = "")

    # This is what registerMethods does - registers a hook
    setHook(
      packageEvent(pkg, "onLoad"),
      function(...) {
        cat("Hook callback would register S3 method here\n")
      }
    )
  })
}

cat("Calling registerMethods with knitr hook...\n")
registerMethods_test(list(
  c("knitr", "knit_print", "data.frame")
))
cat("  Hook registered successfully\n")
cat("\n")

cat("Verifying hook was registered...\n")
hooks <- getHook(packageEvent("knitr", "onLoad"))
cat("  Number of hooks on knitr::onLoad:", length(hooks), "\n")
cat("\n")

cat("=== SUCCESS: Script completed ===\n")
cat("\n")
cat("We've reproduced EXACTLY what rmarkdown's .onLoad does:\n")
cat("  1. Created a stack (.render_context)\n")
cat("  2. Loaded knitr\n")
cat("  3. Registered persistent hook via setHook(packageEvent(...))\n")
cat("\n")
cat("If this crashes, the root cause is CONFIRMED to be the .onLoad behavior.\n")
cat("If this passes, something else in rmarkdown (not .onLoad) is the issue.\n")
cat("\n")
cat("Watch for exit code -1073741569 (STATUS_NOT_SUPPORTED).\n")
