# Check dependency chains for rmarkdown imports

packages <- c("htmltools", "jquerylib", "fontawesome", "bslib", "tinytex", "jsonlite", "yaml")

for (pkg in packages) {
  cat(sprintf("\n=== %s ===\n", pkg))
  desc <- packageDescription(pkg)
  cat("Imports:", desc$Imports %||% "none", "\n")
  cat("Depends:", desc$Depends %||% "none", "\n")
}
