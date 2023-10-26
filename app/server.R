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
  clusterResult <- reactiveVal()

  output$pigmentsFileStatusText <- renderText({pigmentsFileStatus()})

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
    # result$cluster.list
    # plot of clusters
    log_trace("cluster result len: {nrow(result)}")
    clusterResult(result)
    log_trace("cluster result len: {nrow(clusterResult())}")
    clusterSelectStatus("clustering complete")
  }

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
    # log_info(glue(
    #   "selected cluster of size {nrow(clusterResult()$cluster.list[[selectedValue]])}"
    # ))
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

  output$nClusters <- renderText({
    req(selectedCluster())
    req(clusterResult())
    return(nrow(clusterResult()$cluster.list))
  })
  output$clusterSize <- renderText({
    req(selectedCluster())
    req(clusterResult())
    return(nrow(clusterResult()$cluster.list[[selectedCluster()]]))
  })

  # === annealing run =========================================================
  annealingStatus <- reactiveVal("Not Started")
  annealingResult <- reactiveVal()
  output$annealingStatusText <- renderText({annealingStatus()})
  # observeEvent(input$taxalist_file, {
  #   # pigmentsDFClusters$cluster.list[[1]]
  #
  # })

  observe({
    annealingStatus("awaiting cluster input")
    req(clusterResult())
    req(selectedCluster())
    annealingStatus(glue("extracting cluster #{selectedCluster()}"))
    Clust1 <- clusterResult()$cluster.list[[
      as.numeric(selectedCluster())
    ]]
    log_trace(glue("cluster # {selectedCluster()}:"))
    # log_trace(Clust1)
    log_trace("Remove cluster column/label")
    Clust1$Clust <- NULL
    log_trace("selected cluster:")
    log_trace(nrow(Clust1))

    req(Clust1)
    annealingStatus("running...")
    log_trace("annealing...")
    set.seed("7683")  # TODO: set set in UI
    # TODO: can we print temp to the UI from the console
    Results <- phytoclass::simulated_annealing(
      Clust1,
      niter = 1
    )

    annealingStatus(glue("
     completed w/ RMSE {Results$RMSE}
   "))
    annealingResult(Results)
    log_trace("annealing complete")
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


