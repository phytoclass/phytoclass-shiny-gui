# Define UI for CHEMTAX app ----
library("glue")
library("logger")

log_threshold(TRACE)

# Helper functions ----
source("R/get_df_from_file.R")
source("modules/quartoReport/quartoReport.R")

# Define server logic for app ----
server <- function(input, output) {
  # set up default files on app open
  saveRDS(get_df_from_file("sample_data/sm.csv"), "www/pigments.rds")
  saveRDS(get_df_from_file("sample_data/taxa.csv"), "www/taxa.rds")


  # === pigments DF setup ============================================
  observeEvent(input$pigments_file, {
    log_trace("pigment file changed")
    # Load your data into the 'data' reactive value
    # For example, reading a CSV file:
    pigment_df <- get_df_from_file(input$pigments_file$datapath)
    # TODO: validate

    # TODO: generate more clever filepath
    saveRDS(pigment_df, "www/pigments.rds")
  })

  # === taxa list DF setup ===========================================
  output$taxalistFileStatusText <- renderText({taxalistFileStatus()})
  observeEvent(input$taxalist_file, {
    taxalist_df <- get_df_from_file(input$taxalist_file$datapath)
    # TODO: validate

    # TODO: generate more clever filepath
    saveRDS(taxalist_df, "www/taxa.rds")
  })

  # === quarto reports ========================================================
  # cluster selection
  quartoReportServer("cluster")

  # cluster inspector
  quartoReportServer("inspectCluster")

  # annealing report
  quartoReportServer("anneal")
}


