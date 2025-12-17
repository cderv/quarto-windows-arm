# Phase 9: Test if loading many packages (not rmarkdown deps) crashes
#
# HYPOTHESIS: If the crash is just about "loading many namespaces,"
# then loading many OTHER packages should also crash.
#
# If this test PASSES, it proves the crash is specific to rmarkdown's
# dependency combination, not just namespace count.

cat("\n=== Phase 9: Testing Many Packages (Not rmarkdown deps) ===\n\n")

# Load packages that are NOT in rmarkdown's dependency tree
# Try to match the same count (~25-30 namespaces)
packages <- c(
  # Base packages that load quickly
  "tools", "utils", "stats", "methods", "grDevices", "graphics",
  # Common packages not used by rmarkdown
  "lattice", "Matrix", "survival", "MASS",
  "nlme", "boot", "cluster", "foreign", "mgcv",
  "rpart", "spatial", "nnet", "KernSmooth"
)

cat(sprintf("Loading %d packages...\n", length(packages)))

for (pkg in packages) {
  tryCatch({
    library(pkg, character.only = TRUE)
    cat(sprintf("✓ %s\n", pkg))
  }, error = function(e) {
    cat(sprintf("✗ %s: %s\n", pkg, conditionMessage(e)))
  })
}

cat("\n=== All packages loaded ===\n")
cat(sprintf("Total namespaces loaded: %d\n", length(loadedNamespaces())))
cat("\nIf this exits cleanly (exit 0), the crash is NOT just about\n")
cat("loading many packages, but specific to rmarkdown's dependency tree.\n")
