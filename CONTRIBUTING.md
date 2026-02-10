# Pushing a Release
## Versioning
Version numbers are manually managed.
Semantic versioning is used.

When a new release is ready:
* set new version number in
  * DESCRIPTION
  * app/ui.R

## Shinyapps.io
1. Update packages : in an R console run `devtools::install()`, update all.
2. Deploy to shinyapps.io : Use the RStudio "Publish Document" button on app.R, ui.R, or server.R to push as `phytoclass-app`.
