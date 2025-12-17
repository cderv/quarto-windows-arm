# Test: bslib Dependencies in Isolation
#
# Purpose: Load bslib's direct dependencies individually to verify they work
#
# Expected result:
#   - All dependencies load successfully
#   - Script completes successfully
#   - Process exits cleanly with exit code 0
#
# This test verifies that the issue is in bslib itself, not its dependencies.
# Phase 1 testing already proved all dependencies work individually, but this
# test specifically focuses on bslib's dependency chain.

cat("=== bslib Dependencies Test ===\n")
cat("\n")

cat("Loading bslib dependencies individually...\n")
cat("\n")

cat("1. Loading sass...\n")
library(sass)
cat("   sass loaded successfully\n")
cat("\n")

cat("2. Loading jquerylib...\n")
library(jquerylib)
cat("   jquerylib loaded successfully\n")
cat("\n")

cat("3. Loading htmltools...\n")
library(htmltools)
cat("   htmltools loaded successfully\n")
cat("\n")

cat("4. Loading rlang...\n")
library(rlang)
cat("   rlang loaded successfully\n")
cat("\n")

cat("5. Loading fastmap...\n")
library(fastmap)
cat("   fastmap loaded successfully\n")
cat("\n")

cat("6. Loading cachem...\n")
library(cachem)
cat("   cachem loaded successfully\n")
cat("\n")

cat("7. Loading memoise...\n")
library(memoise)
cat("   memoise loaded successfully\n")
cat("\n")

cat("=== SUCCESS: All bslib dependencies loaded ===\n")
cat("\n")
cat("Summary:\n")
cat("  - sass:      ✓\n")
cat("  - jquerylib: ✓\n")
cat("  - htmltools: ✓\n")
cat("  - rlang:     ✓\n")
cat("  - fastmap:   ✓\n")
cat("  - cachem:    ✓\n")
cat("  - memoise:   ✓\n")
cat("\n")
cat("This confirms bslib's dependencies work individually.\n")
cat("If bslib itself crashes, the issue is in bslib's own code.\n")
