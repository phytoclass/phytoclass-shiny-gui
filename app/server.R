# Define UI for CHEMTAX app ----
library("glue")
library("logger")

log_threshold(TRACE)

# Helper functions ----
source("R/get_df_from_file.R")

# Define server logic for app ----
server <- function(input, output) {
  # TODO: set up tabset disabling for user steps
  # ref https://chat.openai.com/c/c26c74dc-2038-47fd-87e6-0f8015110215

  # === pigments DF setup & status ============================================
  pigmentsDF <- reactiveVal(NULL)
  pigmentsFileStatus <- reactiveVal("pigments csv needed")
  clusterResult <- reactiveVal()

  output$pigmentsFileStatusText <- renderText({pigmentsFileStatus()})

  observeEvent(input$pigments_file, {
    log_trace("pigment file changed")
    # Load your data into the 'data' reactive value
    # For example, reading a CSV file:
    pigment_df <- get_df_from_file(input$pigments_file$datapath)
   # TODO: validate
    pigmentsDF(pigment_df)
    saveRDS(pigment_df, "www/pigments.rds")

    # Update the status based on the length of the data frame
    if (nrow(pigment_df) > 0) {
      pigmentsFileStatus(paste("Data loaded, length:", nrow(pigment_df)))
      log_trace("pigment file load success")
    } else {
      pigmentsFileStatus("Data loaded, but the data frame is empty")
    }
  })

  # === taxa list DF setup & status ===========================================
  taxalistDF <- reactiveVal(NULL)
  taxalistFileStatus <- reactiveVal("taxalist csv needed")
  output$taxalistFileStatusText <- renderText({taxalistFileStatus()})
  observeEvent(input$taxalist_file, {
    taxalist_df <- get_df_from_file(input$taxalist_file$datapath)
   # TODO: validate
    taxalistDF(taxalist_df)

    # Update the status based on the length of the data frame
    if (nrow(taxalist_df) > 0) {
      taxalistFileStatus(paste("Data loaded, length:", nrow(taxalist_df)))
    } else {
      taxalistFileStatus("Data loaded, but the data frame is empty")
    }
  })

  # === cluster selection =====================================================
  quartoReportServer(
    "cluster",
    list(
      inputFile = "pigments.rds",
      outputFile = "clusters.rds"
    )
  )

  # === annealing report =========================================================
  quartoReportServer(
    "anneal",
    list(
      inputFile = "clusters.rds",
      outputFile = "annealing.rds"
      # TODO: fill these to match .qmd
    )
  )
}


