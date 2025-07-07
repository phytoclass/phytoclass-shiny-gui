# Define UI for CHEMTAX app ----
library(glue)
library(logger)
library(digest)
library(rhandsontable)

log_threshold(TRACE)

# Helper functions ----
source("R/get_df_from_file.R")
source("modules/quartoReport/quartoReport.R")

# Define server logic for app ----
server <- function(input, output, session) {
  
  # Create unique session directory for each user session
  session_dir <- file.path("www", paste0("session-", session$token))
  if (!dir.exists(session_dir)) dir.create(session_dir)
  
  # Save default pigment and taxa files in session directory
  saveRDS(get_df_from_file("sample_data/sm.csv"), file.path(session_dir, "pigments.rds"))
  saveRDS(get_df_from_file("sample_data/taxa.csv"), file.path(session_dir, "taxa.rds"))
  
  # Reactive value to store selected cluster
  selected_cluster <- reactiveVal(1)
  
  # Observe changes from inspectCluster module
  observe({
    # This assumes your quartoReport module updates input$inspectCluster-selected_cluster
    if (!is.null(input[["inspectCluster-selected_cluster"]])) {
      selected_cluster(input[["inspectCluster-selected_cluster"]])
    }
  })
  
  
  # === pigments DF setup ============================================
  # Holds the uploaded pigment data in reactive memory
  pigments_data <- reactiveVal(NULL)
  
  # When the pigment file is uploaded, read it, store it, and save to session directory
  observeEvent(input$pigments_file, {
    log_trace("pigment file changed")
    # Load your data into the 'data' reactive value
    # For example, reading a CSV file:
    pigment_df <- get_df_from_file(input$pigments_file$datapath)
    pigments_data(pigment_df)
    # TODO: validate
    
    # TODO: generate more clever filepath
    saveRDS(pigment_df, file.path(session_dir, "pigments.rds"))
  })
  
  # UI output: Render pigment table and save button (only when file is uploaded)
  output$pigments_table_ui <- renderUI({
    req(pigments_data())
    tagList(
      h5("Pigment matrix loaded and editable below:"),
      rHandsontableOutput("pigments_table"),
      actionButton("save_pigments_edits", "Save Edits")
    )
  })
  
  # Render the editable handsontable for pigments
  output$pigments_table <- renderRHandsontable({
    req(pigments_data())
    rhandsontable(pigments_data(), useTypes = TRUE, stretchH = "all")
  })
  
  # When the save button is clicked, capture the edited table and save to session
  observeEvent(input$save_pigments_edits, {
    updated <- hot_to_r(input$pigments_table)
    pigments_data(updated)
    saveRDS(updated, file.path(session_dir, "pigments.rds"))
    log_trace("Pigment edits saved.")
  })
  
  # === taxa list DF setup ===========================================
  # Holds the uploaded taxa list data in reactive memory
  taxalist_data <- reactiveVal(NULL)
  output$taxalistFileStatusText <- renderText({taxalistFileStatus()})
  
  # When the taxa file is uploaded, read it and store it
  observeEvent(input$taxalist_file, {
    taxalist_df <- get_df_from_file(input$taxalist_file$datapath)
     taxalist_data(taxalist_df)
    # TODO: validate
    
    # TODO: generate more clever filepath
    saveRDS(taxalist_df, file.path(session_dir, "taxa.rds"))
  })
  
  # UI output: Render taxa table and save button (only when file is uploaded)
  output$taxa_table_ui <- renderUI({
    req(taxalist_data())
    tagList(
      h5("Taxa list loaded and editable below:"),
      rHandsontableOutput("taxa_table"),
      actionButton("save_taxa_edits", "Save Edits")
    )
  })
  
  # Render the editable handsontable for taxa list
  output$taxa_table <- renderRHandsontable({
    req(taxalist_data())
    rhandsontable(taxalist_data(), useTypes = TRUE, stretchH = "all")
  })
  
  # Save edited taxa data to session when user clicks "Save Edits"
  observeEvent(input$save_taxa_edits, {
    updated <- hot_to_r(input$taxa_table)
    taxalist_data(updated)
    saveRDS(updated, file.path(session_dir, "taxa.rds"))
    log_trace("Taxa list edits saved.")
  })
  
  # === MinMax table setup ===========================================
  
  # Holds the uploaded min-max table in reactive memory
  minmax_data <- reactiveVal(NULL)
  # When the min-max file is uploaded, read and store it
  observeEvent(input$minmax_file, {
    minmax_df <- get_df_from_file(input$minmax_file$datapath)
    minmax_data(minmax_df)
    # TODO: validate the structure matches expected min-max format
    saveRDS(minmax_df, file.path(session_dir, "minmax.rds"))
  })
  
  # UI output: Render min-max table and save button (only when file is uploaded)
  output$minmax_table_ui <- renderUI({
    req(minmax_data())
    tagList(
      h5("Min-Max table loaded and editable below:"),
      rHandsontableOutput("minmax_table"),
      actionButton("save_minmax_edits", "Save Edits")
    )
  })
  
  # Render the editable handsontable for min-max table
  output$minmax_table <- renderRHandsontable({
    req(minmax_data())
    rhandsontable(minmax_data(), useTypes = TRUE, stretchH = "all")
  })
  
  # Save edited min-max data to session when user clicks "Save Edits"
  observeEvent(input$save_minmax_edits, {
    updated <- hot_to_r(input$minmax_table)
    minmax_data(updated)
    saveRDS(updated, file.path(session_dir, "minmax.rds"))
    log_trace("Min-Max edits saved.")
  })
  
  # === quarto reports ========================================================
  # cluster selection
  quartoReportServer("cluster", session_dir = session_dir)
  
  # cluster inspector
  quartoReportServer("inspectCluster", session_dir = session_dir) 
  
  # annealing report
  quartoReportServer("anneal", session_dir = session_dir)

  
  # === cluster download =================================
  output$downloadCluster <- downloadHandler(
    filename = function() {
      paste0("cluster.csv")
    },
    content = function(file) {
      cluster_path <- file.path(session_dir, "clusters.rds")
      req(file.exists(cluster_path))
      cluster_df <- readRDS(cluster_path)
      
      # Validate cluster exists
      req(length(cluster_df$cluster.list) >= selected_cluster())
      
      selected_cluster_data <- cluster_df$cluster.list[[selected_cluster()]]
      
      # Remove cluster column if exists
      if ("Clust" %in% colnames(selected_cluster_data)) {
        selected_cluster_data$Clust <- NULL
      }
      
      # Round off numeric values to 4 decimal places
      is_numeric_col <- sapply(selected_cluster_data, is.numeric)
      selected_cluster_data[is_numeric_col] <- lapply(selected_cluster_data[is_numeric_col], round, digits = 4)
      
      write.csv(selected_cluster_data, file, row.names = TRUE)
    }
  )
  
  # ---- Session Cleanup ----
  # Deletes session folders older than 1 hour (3600 seconds)
  clean_old_sessions <- function(path = "www", cutoff_seconds = 3600) {
    now <- Sys.time()
    folders <- list.dirs(path, full.names = TRUE, recursive = FALSE)
    for (folder in folders) {
      if (grepl("session-", folder)) {
        info <- file.info(folder)
        age_seconds <- as.numeric(difftime(now, info$mtime, units = "secs"))
        if (age_seconds > cutoff_seconds) {
          unlink(folder, recursive = TRUE, force = TRUE)
          log_trace("Deleted session folder: ", folder)
        }
      }
    }
  }
  
  # Run cleanup once when app starts
  clean_old_sessions()

}


