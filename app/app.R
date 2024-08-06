# app.R
library(shiny)
source("ui.R")
source("server.R")

# modules
source("modules/quartoReport/quartoReport.R")

shinyApp(ui = ui, server = server)
