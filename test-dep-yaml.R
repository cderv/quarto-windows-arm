#!/usr/bin/env Rscript
# Test: rmarkdown dependency - yaml
# Expected: SUCCESS on R x64 Windows ARM (low suspect - YAML parsing only)

cat("Loading yaml package...\n")
library(yaml)

cat("Platform: ", R.version[['platform']], "\n", sep = "")
cat("R Version: ", R.version[['version.string']], "\n", sep = "")
cat("yaml version: ", as.character(packageVersion("yaml")), "\n", sep = "")

cat("Test: test-dep-yaml\n")
cat("Result: SUCCESS (if you see this, yaml loads without crashing)\n")
