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

    # Set first column as row names if it contains character data
    if (is.character(pigment_df[[1]])) {
      rownames(pigment_df) <- pigment_df[[1]]
      pigment_df <- pigment_df[, -1, drop = FALSE]
    }

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
      div(
        style = "margin-top: 15px; margin-bottom: 15px;",
        actionButton(
          "save_pigments_edits",
          label = HTML("<b>Save Edits</b>"),
          class = "btn btn-primary",
          style = "font-size: 16px; padding: 10px 20px;"
        )
      ),
      rHandsontableOutput("pigments_table")
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
  # Initialize with default taxa list
  taxalist_data <- reactiveVal(phytoclass::Fm)
  output$taxalistFileStatusText <- renderText({taxalistFileStatus()})

  # When the taxa file is uploaded, read it and store it
  observeEvent(input$taxalist_file, {
    taxalist_df <- get_df_from_file(input$taxalist_file$datapath)

    # Set first column as row names if it contains character data
    if (is.character(taxalist_df[[1]])) {
      rownames(taxalist_df) <- taxalist_df[[1]]
      taxalist_df <- taxalist_df[, -1, drop = FALSE]
    }

    taxalist_data(taxalist_df)

    # TODO: generate more clever filepath
    saveRDS(taxalist_df, file.path(session_dir, "taxa.rds"))
  })

  # UI output: Always render taxa table and save button
  output$taxa_table_ui <- renderUI({
    tagList(
      h5("Taxa list (editable):"),
      rHandsontableOutput("taxa_table"),
      div(
        style = "margin-top: 15px; margin-bottom: 15px;",
        actionButton(
          "save_taxa_edits",
          label = HTML("<b>Save Edits</b>"),
          class = "btn btn-primary",
          style = "font-size: 16px; padding: 10px 20px;"
        )
      )
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

  # Initialize with default min-max table
  minmax_data <- reactiveVal(phytoclass::min_max)
  
  # When the min-max file is uploaded, read and store it
  observeEvent(input$minmax_file, {
    minmax_df <- get_df_from_file(input$minmax_file$datapath)
    minmax_data(minmax_df)
    # TODO: validate the structure matches expected min-max format
    saveRDS(minmax_df, file.path(session_dir, "minmax.rds"))
  })

  # Always render the UI (default or uploaded)
  output$minmax_table_ui <- renderUI({
    tagList(
      h5("Min-Max table (editable):"),
      rHandsontableOutput("minmax_table"),
      div(
        style = "margin-top: 15px; margin-bottom: 15px;",
        actionButton(
          "save_minmax_edits",
          label = HTML("<b>Save Edits</b>"),
          class = "btn btn-primary",
          style = "font-size: 16px; padding: 10px 20px;"
        )
      )
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

  # === Matrix Check setup ===========================================
  run_matrix_check <- function(S_path, F_path, output_id) {
    # If either matrix file is missing, inform the user
    if (!file.exists(S_path)) {
      output[[output_id]] <- renderText("Cannot check. S matrix missing.")
      return()
    }

    #Load file
    S <- readRDS(S_path)
    # Load F matrix (can be object or path)
    Fmat <- if (is.character(F_path)) {
      if (!file.exists(F_path)) {
        output[[output_id]] <- renderText("Cannot check. F matrix missing.")
        return()
      }
      readRDS(F_path)
    } else {
      F_path
    }

    tryCatch({
      #Perform matrix check function on files
      result <- phytoclass::Matrix_checks(S, Fmat)

      # Identify removed and retained columns
      removed_S <- setdiff(colnames(S), colnames(result$Snew))
      removed_F <- setdiff(colnames(Fmat), colnames(result$Fnew))
      common_cols <- intersect(colnames(result$Snew), colnames(result$Fnew))
      missing_in_S <- setdiff(colnames(result$Fnew), colnames(result$Snew))
      missing_in_F <- setdiff(colnames(result$Snew), colnames(result$Fnew))

      # Show detailed report
      output[[output_id]] <- renderText({
        paste0(
          "Matrix Check Completed\n\n",
          "Columns that would be removed due to low values:\n",
          "- From S matrix: ", if (length(removed_S)) paste(removed_S, collapse = ", ") else "None", "\n",
          "- From F matrix: ", if (length(removed_F)) paste(removed_F, collapse = ", ") else "None", "\n\n",
          "Column name alignment:\n",
          "- Shared columns (S ∩ F): ", if (length(common_cols)) paste(common_cols, collapse = ", ") else "None", "\n",
          "- In F but missing in S: ", if (length(missing_in_S)) paste(missing_in_S, collapse = ", ") else "None", "\n",
          "- In S but missing in F: ", if (length(missing_in_F)) paste(missing_in_F, collapse = ", ") else "None"
        )
      })
    }, error = function(e) {
      output[[output_id]] <- renderText({
        paste0("Matrix Check Failed:\n", e$message)
      })
    })
  }

  # Pigments tab
  observeEvent(input$run_matrix_check_S, {
    run_matrix_check(
      S_path = file.path(session_dir, "pigments.rds"),
      F_path = phytoclass::Fm,
      output_id = "matrix_check_output_S"
    )
  })

  # Taxa tab
  observeEvent(input$run_matrix_check_F, {
    run_matrix_check(
      S_path = file.path(session_dir, "pigments.rds"),
      F_path = file.path(session_dir, "taxa.rds"),
      output_id = "matrix_check_output_F"
    )
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


