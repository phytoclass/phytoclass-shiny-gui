# Define UI for CHEMTAX app ----
library("glue")
library("logger")
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

  observeEvent(input$pigments_file, {
    # Load your data into the 'data' reactive value
    # For example, reading a CSV file:
    pigment_df <- get_df_from_file(input$pigments_file$datapath)
   # TODO: validate
    pigmentsDF(pigment_df)

    # Update the status based on the length of the data frame
    if (nrow(pigment_df) > 0) {
      pigmentsFileStatus(paste("Data loaded, length:", nrow(pigment_df)))
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
  selectedCluster <- reactiveVal(1)
  clusterSelectStatus <- reactiveVal("using cluster 0")
  output$clusterSelectStatusText <- renderText({clusterSelectStatus()})
  observeEvent(input$clusterSelector, {
    selectedValue <- input$clusterSelector
    # validate

    if(!is.null(clusterResult()) && clusterResult()$cluster.list < 1){
      clusterSelectStatus("clustering not yet applied")
    } else {
      log_info(glue(
        "selected cluster {clusterResult()$cluster.list}"
      ))
      if(selectedValue < 1){  # TODO: also check upper bound
        clusterSelectStatus("bad cluster selection value")
      } else {
        selectedCluster(selectedValue)
        clusterSelectStatus(glue("selected cluster {selectedCluster()}"))
      }
    }
  })

  clusterResult <- reactiveVal()
  # clusterResult()$cluster.list

  output$clusterDendrogram <- renderPlot({
    # req(input$pigments_file)
    if(!is.null(pigmentsDF())){
      result <- phytoclass::Cluster(pigmentsDF(), 14)
      result$cluster.list
      # plot of clusters
      clusterResult(result)
      return(plot(result$cluster.plot))
    }  # TODO: else show not yet loaded
  })


  # === annealing run =========================================================
    annealingStatus <- reactiveVal("Not Started")


  output$annealingSummary <- renderText({
    # TODO: pick cluster from
    # pigmentsDFClusters$cluster.list[[1]]
  })
}


