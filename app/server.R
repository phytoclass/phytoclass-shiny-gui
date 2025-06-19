# Define UI for CHEMTAX app ----
library(glue)
library(logger)
library(digest)

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
  observeEvent(input$pigments_file, {
    log_trace("pigment file changed")
    # Load your data into the 'data' reactive value
    # For example, reading a CSV file:
    pigment_df <- get_df_from_file(input$pigments_file$datapath)
    # TODO: validate
    
    # TODO: generate more clever filepath
    saveRDS(pigment_df, file.path(session_dir, "pigments.rds"))
  })
  
  # === taxa list DF setup ===========================================
  output$taxalistFileStatusText <- renderText({taxalistFileStatus()})
  observeEvent(input$taxalist_file, {
    taxalist_df <- get_df_from_file(input$taxalist_file$datapath)
    # TODO: validate
    
    # TODO: generate more clever filepath
    saveRDS(taxalist_df, file.path(session_dir, "taxa.rds"))
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


