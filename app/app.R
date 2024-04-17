# app.R
library(shiny)
source("ui.R")
source("server.R")

# modules
# TODO: load modules here

shinyApp(ui = ui, server = server)
