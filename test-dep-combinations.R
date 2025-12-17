#!/usr/bin/env Rscript
# Test: Combination of rmarkdown dependencies
# Expected: UNKNOWN on R x64 Windows ARM
#
# Purpose: Test if multiple dependencies that work individually might fail together.
# Only run this if individual dependency tests show some packages work but others fail.
#
# Usage: Manually edit this file to test specific combinations based on individual test results.

cat("=== Testing dependency combinations ===\n")
cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("\n")

# Example combinations to test (uncomment as needed based on individual test results):

# Combination 1: High suspects together
cat("Testing combination: tinytex + htmltools\n")
library(tinytex)
cat("  tinytex loaded: ", as.character(packageVersion("tinytex")), "\n", sep = "")
library(htmltools)
cat("  htmltools loaded: ", as.character(packageVersion("htmltools")), "\n", sep = "")

# Combination 2: High suspects with bslib
# cat("\nTesting combination: htmltools + bslib\n")
# library(htmltools)
# cat("  htmltools loaded: ", as.character(packageVersion("htmltools")), "\n", sep = "")
# library(bslib)
# cat("  bslib loaded: ", as.character(packageVersion("bslib")), "\n", sep = "")

# Combination 3: All high suspects
# cat("\nTesting combination: tinytex + htmltools + bslib\n")
# library(tinytex)
# library(htmltools)
# library(bslib)

cat("\nTest: test-dep-combinations\n")
cat("Result: SUCCESS (if you see this, the combination loads without crashing)\n")
