# Phase 8: Test loadNamespace() vs library()
#
# CRITICAL INSIGHT: R uses loadNamespace() for imports, not library()
#
# loadNamespace() vs library():
# - loadNamespace(): Loads package namespace, runs .onLoad, does NOT attach
# - library(): Calls loadNamespace() THEN attaches package to search path
#
# Phase 1 tested library() but rmarkdown import resolution uses loadNamespace()!
#
# This test mirrors what R actually does when loading rmarkdown

cat("\n=== Phase 8: Testing loadNamespace() Import Resolution ===\n\n")

# Start with the working set from Phase 5
cat("Loading Phase 5 working set using loadNamespace():\n")
loadNamespace("evaluate")
cat("✓ evaluate namespace loaded\n")
loadNamespace("htmltools")  # This loads: base64enc, digest, fastmap, rlang
cat("✓ htmltools namespace loaded (+ base64enc, digest, fastmap, rlang)\n")
loadNamespace("knitr")  # This loads: xfun, highr
cat("✓ knitr namespace loaded (+ xfun, highr)\n")

cat("\nPhase 5 working set established.\n")
cat("Now testing rmarkdown's additional imports in load order:\n\n")

# Test imports that load between the working set and bslib
# Based on dependency analysis:

# 1. Simple packages with no/few dependencies
cat("Test 1: jsonlite (no dependencies)\n")
loadNamespace("jsonlite")
cat("✓ jsonlite loaded\n\n")

cat("Test 2: yaml (no dependencies)\n")
loadNamespace("yaml")
cat("✓ yaml loaded\n\n")

cat("Test 3: tinytex (depends on xfun, already loaded)\n")
loadNamespace("tinytex")
cat("✓ tinytex loaded\n\n")

# 2. Packages that depend on htmltools
cat("Test 4: jquerylib (depends on htmltools)\n")
loadNamespace("jquerylib")
cat("✓ jquerylib loaded\n\n")

cat("Test 5: fontawesome (depends on htmltools + rlang)\n")
loadNamespace("fontawesome")
cat("✓ fontawesome loaded\n\n")

# 3. bslib dependencies not yet loaded
cat("Test 6: cachem (bslib dependency)\n")
loadNamespace("cachem")
cat("✓ cachem loaded\n\n")

cat("Test 7: lifecycle (bslib dependency)\n")
loadNamespace("lifecycle")
cat("✓ lifecycle loaded\n\n")

cat("Test 8: memoise (bslib dependency)\n")
loadNamespace("memoise")
cat("✓ memoise loaded\n\n")

cat("Test 9: mime (bslib dependency)\n")
loadNamespace("mime")
cat("✓ mime loaded\n\n")

cat("Test 10: sass (bslib dependency, has compiled code)\n")
loadNamespace("sass")
cat("✓ sass loaded\n\n")

# 4. Finally load bslib
cat("Test 11: bslib (the package that wasn't loaded in Phase 5)\n")
loadNamespace("bslib")
cat("✓ bslib namespace loaded\n\n")

cat("\n=== All Namespaces Loaded Successfully ===\n")
cat("If crash occurs, it's during R termination (cleanup phase).\n")
cat("\nLoaded namespaces:\n")
print(loadedNamespaces())
