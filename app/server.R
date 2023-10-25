# Define UI for CHEMTAX app ----
library("glue")
library("logger")

log_threshold(TRACE)

# Helper functions ----
get_df_from_file <- function(filepath){
  # function to read the taxalist & pigment csv files.
  tryCatch({
    # when reading semicolon separated files,
    # having a comma separator causes `read.csv` to error
      df <- read.csv(filepath,
                     header = TRUE,
                     sep = ',',
                     quote = '"')
    },
    error = function(e) {
      # return a safeError if a parsing error occurs
      stop(safeError(e))
    }
  )
  return(df)
}

# Define server logic for app ----
server <- function(input, output) {
  # === pigments DF setup & status ============================================
  pigmentsDF <- reactiveVal(NULL)

  pigmentsFileStatus <- reactiveVal("pigments csv needed")
  output$pigmentsFileStatusText <- renderText({pigmentsFileStatus()})

  observe({
    log_trace(glue("n_pigment_samples:{nrow(pigmentsDF())}"))
  })

  observeEvent(input$pigments_file, {
    log_trace("pigment file changed")
    # Load your data into the 'data' reactive value
    # For example, reading a CSV file:
    pigment_df <- get_df_from_file(input$pigments_file$datapath)
   # TODO: validate
    pigmentsDF(pigment_df)

    # Update the status based on the length of the data frame
    if (nrow(pigment_df) > 0) {
      pigmentsFileStatus(paste("Data loaded, length:", nrow(pigment_df)))
      log_trace("pigment file load success")
    } else {
      pigmentsFileStatus("Data loaded, but the data frame is empty")
    }
  })

  runClustering <- function(pigments_df){
    req(pigments_df)
    log_trace("running clustering")
    clusterSelectStatus("running clustering...")
    result <- phytoclass::Cluster(pigments_df, 14)
    result$cluster.list
    # plot of clusters
    clusterResult(result)
    clusterSelectStatus("clustering complete")
  }

  clusterResult <- reactiveVal()
  observe({runClustering(pigmentsDF())})


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
  selectedCluster <- reactiveVal(1)
  clusterSelectStatus <- reactiveVal("not yet clustered")
  output$clusterSelectStatusText <- renderText({clusterSelectStatus()})
  observeEvent(input$clusterSelector, {
    selectedValue <- input$clusterSelector
    # validate
    log_info(glue(
      "selected cluster {clusterResult()$cluster.list}"
    ))
    if(selectedValue < 1){  # TODO: also check upper bound
      clusterSelectStatus("bad cluster selection value")
    } else {
    clusterSelectStatus(glue("selected cluster {selectedCluster()}"))
      selectedCluster(selectedValue)
    }
  })

  output$clusterDendrogram <- renderPlot({
    req(clusterResult())
    return(plot(clusterResult()$cluster.plot))
  })


  # === annealing run =========================================================
  annealingStatus <- reactiveVal("Not Started")
  annealingResult <- reactiveVal()
  output$annealingStatusText <- renderText({annealingStatus()})
  # observeEvent(input$taxalist_file, {
  #   # pigmentsDFClusters$cluster.list[[1]]
  #
  # })

  observeEvent(clusterResult, {
    annealingStatus("awaiting cluster input")
    req(pigmentsDF())
    #req(taxalistDF())
    req(clusterResult())
    req(selectedCluster())
    annealingStatus("running...")

    Clust1 <- clusterResult()$cluster.list[[selectedCluster()]]
    # Remove the cluster column/label
    Clust1$Clust <- NULL

    set.seed("7683")  # TODO: set seet in UI
    Results <- simulated_annealing(Clust1, niter = 1)
    annealingStatus(glue("
     completed w/ RMSE {Results$RMSE}
   "))
    annealingResult(Results)
  })

  output$annealingSummary <- renderText({
    req(annealingResult())
    return(annealingResult()$`Class abundances`)
  })

  output$annealingPlot <- renderPlot({
    req(annealingResult())
    return(annealingResult()$Figure)
  })
}


