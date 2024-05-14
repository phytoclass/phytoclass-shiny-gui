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

  observeEvent(input$cluster, {
    print('cluster')
    output$cluster_output = renderText("generating report...")
    tryCatch({
      quarto::quarto_render(
        input='www/cluster.qmd',
        execute_params=list(pigments_df_file = "pigments.rds")
      )
      output$cluster_output = renderUI({
        tags$iframe(src="cluster.html", width="100%", height="800px")

        # includeHTML("cluster.html")  # expects fragment, not full document
      })
    }, error = function(e) {
      output$cluster_output = renderPrint(e)
      # TODO: print quarto error? how?
    })
  })


  selectedCluster <- reactiveVal(1)
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

  # === annealing report =========================================================

  observeEvent(input$anneal, {
    print('anneal')
    output$anneal_output = renderText("generating report...")
    # TODO: trigger re-render
    quarto::quarto_render(
      input='www/anneal.qmd',
      execute_params=list(
        cluster_rds="clusters.rds"  # TODO: fill these to match .qmd
      )
    )
    output$anneal_output = renderUI({
      tags$iframe(src="anneal.html", width="100%", height="800px")
      # includeHTML("cluster.html")  # expects fragment, not full document
    })
  })

  # === (OLD) annealing run =========================================================
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
      niter = 300  # number of iterations
      # user_defined_min_max = minMaxTable
      # TODO: place to upload table to replace
      #       phytoclass::min_max table
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


