# chemtax-shiny-gui
GUI built using R.shiny for CHEMTAX

# TODO:
* create DESCRIPTION file (`devtools::create("chemtax-shiny-gui")`?)
* add [file upload](https://shiny.rstudio.com/gallery/file-upload.html)s

# ===

```R
if (!require('shiny')) install.packages("shiny")
shiny::runApp("app")
```