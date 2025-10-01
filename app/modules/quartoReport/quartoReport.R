library(later)
library(glue)
library(here)
library(digest)
library(withr)


# Load function to build the context for report rendering
source("modules/quartoReport/buildContext.R")

# === Function to actually render the report =========
actualRenderReport <- function(
    contextRDSPath, inputCode, output, qmd_path, reportHTMLPath,
    reportQMDPath, id, session_id, session_dir, bypass_clustering
){
  print("rendering....")
  print(glue("inputCode: {inputCode}"))

  # Save the context built using the input code
  contextRDSPath(buildContext(inputCode, bypass_clustering, output, session_id, session_dir))
  print(glue("context: {contextRDSPath()}"))

  tryCatch({
    # Create a session-specific QMD
    qmd_filename <- glue("{id}.qmd")
    session_qmd_path <- file.path(session_dir, qmd_filename)
    file.copy(qmd_path, session_qmd_path, overwrite = TRUE)

    # Update HTML output path (guaranteed in session dir)
    output_filename <- basename(reportHTMLPath)  # this is good
    reportHTMLPath <- file.path(session_dir, output_filename)

    #==== Render HTML report ===========================
    withr::with_dir(session_dir, {
      output_message <- system2(
        command = "quarto",
        args = c(
          "render",
          basename(session_qmd_path),
          "--output", output_filename,
          "--execute-params", basename(contextRDSPath()),
          "-P", "session_dir:.",
          "--execute-dir", "."
        ),
        stdout = TRUE,
        stderr = TRUE,
        wait = TRUE
      )
    })

    # Check for rendering failure
    exit_status <- attr(output_message, "status")
    if (!is.null(exit_status) && exit_status != 0) {
      stop(paste(
        "Command failed with status", exit_status, ":",
        paste(output_message, collapse = "\n")
      ))
    }

    # Copy the QMD file for download
    file.copy(qmd_path, reportQMDPath, overwrite = TRUE)

    # === Render report inline in app (HTML iframe) ===
    output$output <- renderUI({
      # Use relative path from www directory
      relative_path <- sub("^www/", "", session_dir)
      tags$iframe(
        src = file.path(relative_path, output_filename),
        width = "100%",
        height = "800px"
      )
    })

  }, error = function(e) {
    # Show error message in UI if rendering fails
    output$output <- renderUI({
      HTML(paste0(
        "<div class='alert alert-danger'>",
        "<strong>ERROR while rendering!</strong> Please check your inputs.<br>",
        'For help please ',
        '<a href="https://github.com/USF-IMARS/chemtax-shiny-gui/issues/new">',
        'open an issue on the project github</a> and include the error below.',
        "<pre>", conditionMessage(e), "</pre>",
        "</div>"
      ))
    })
  })
}

# === Schedules and triggers the report rendering =================================
renderReport <- function(
    contextRDSPath, setupInputCode, output, qmd_path, reportHTMLPath, id,
    reportQMDPath, session_id, session_dir, bypass_clustering
){
  # renderReport schedules the render for later so that the "generating report..." text shows immediately
  print(glue("generating report '{id}'..."))

  # TODO: get this working again:
  output$output = renderUI(renderText("generating report...."))
  # later::later(function(){
  #   actualRenderReport(
  #     contextRDSPath,
  #     setupInputCode,
  #     output,
  #     qmd_path, reportHTMLPath
  #   )
  # }, 0.1) # Schedule this to run immediately after the initial output

  # Call actual rendering function
  actualRenderReport(
    contextRDSPath,
    setupInputCode,
    output,
    qmd_path,
    reportHTMLPath,
    reportQMDPath,
    id,
    session_id,
    session_dir,
    bypass_clustering
  )
}

# === UI Module: Defines report UI (generate/configure/download) ===============
quartoReportUI <- function(id, defaultSetupCode = "x <- 1"){
  ns <- NS(id)
  return(tagList(tabsetPanel(type = "tabs",

    # --- Tab for advanced customization of report parameters ---
    tabPanel("configuration",
      markdown(paste(
        "## (optional) report customization",
        sep=""
      )),
      textAreaInput(ns("setupInputCode"),
        label = markdown(paste(
          "(optional) Change these default values for advanced usage.",
          " For details see [phytoclass docs](https://cran.r-project.org/web/packages/phytoclass/vignettes/phytoclass-vignette.html)."
        )),
        value = defaultSetupCode,
        width = "100%",
        height = "15em",
        resize = "both"
      )
    ),

    # --- Tab for generating report ---
    tabPanel("generate report",
      verbatimTextOutput(ns("execParamsDisplay")),
      tags$br(),
      if (id == "anneal") tagList(
        checkboxInput(ns("bypass_clustering"),
          label = "Skip Clustering",
          value = FALSE
        )
      ),
      actionButton(ns("generateButton"), "generate report"),

      # Add a loading spinner while output is rendering
      shinycssloaders::withSpinner(uiOutput(ns("spinnerOutput"))),

      markdown(c(
        "NOTE: please be patient after clicking this button. ",
        "Rendering can take multiple minutes depending on settings."
        )),
      htmlOutput(ns("output"))
    ),

    # --- Tab for downloading report files ---
    tabPanel("download results",
      markdown("Use the buttons below to download results from the report."),
      # actionButton(ns("downloadRDSButton"), "download .rds"),
      downloadButton(ns("downloadHTMLButton"), "Download HTML"),
      downloadButton(ns("downloadQMDButton"), "Download QMD"),
      if (id == "anneal") {
        tagList(
          tags$hr(),
          downloadButton(ns("downloadTaxaCSVButton"), "Download Taxa Estimates (.csv)"),
          downloadButton(ns("downloadFMatrixCSVButton"), "Download F Matrix (.csv)"),
          downloadButton(ns("downloadMAECSVButton"), "Download MAE (.csv)")
        )
      },
      if (id == "inspectCluster") {
        tagList(
          tags$hr(),
          downloadButton("downloadCluster", "Download Inspected Cluster CSV")
        )
      }
    )
  )))
}

# === Server Logic for Quarto Report Module ==================================
quartoReportServer <- function(id, session_dir = NULL){
  session_dir <- basename(session_dir)
  session_path <- file.path("www", session_dir)

  # Paths
  qmd_path <- file.path("www", glue("{id}.qmd"))
  reportHTMLPath <- file.path(session_path, glue("{id}.html"))

  #path to taxa csv
  taxaCSVPath <- file.path(session_path, "taxa_estimates.csv")

  #path to Fmatrix csv
  fmatrixCSVPath <- file.path(session_path, "fmatrix.csv")

  #path to MAE csv
  MAECSVPath <- file.path(session_path, "MAE.csv")

  # Ensure download_reports folder exists
  download_reports_dir <- file.path(session_path, "download_reports")
  dir.create(download_reports_dir, showWarnings = FALSE, recursive = TRUE)

  reportQMDPath <- file.path(download_reports_dir, glue("{id}-report.qmd"))

  moduleServer(id, function(input, output, session){
    # Generate session ID if not provided
    session_id <- paste0("session_", digest(Sys.time(), algo = "md5"))

   # Reactive object to store path to execution context
    contextRDSPath <- reactiveVal(file.path(session_path, "context.yaml"))

    # Flag to track if report has been generated
    reportGenerated <- reactiveVal(FALSE)

    # Conditionally show a message while the report is being generated, otherwise show nothing
    output$spinnerOutput <- renderUI({
      if (is.null(input$generateButton) || input$generateButton == 0) {
        return(NULL)
      } else if (!reportGenerated()) {
        return(tags$div(
          style = "text-align: center;",
          tags$p("Generating report...")
        ))
      } else {
        return(NULL)
      }
    })

    # === generate the quarto report =========================================
    observeEvent(input$generateButton, {
      reportGenerated(FALSE)
      output$output = renderUI(renderText("generating report..."))
      renderReport(
        contextRDSPath,
        input$setupInputCode,
        output,
        qmd_path,
        reportHTMLPath,
        id,
        reportQMDPath,
        session_id,
        session_path,
        input$bypass_clustering
      )
      reportGenerated(TRUE)
    })

    # === Download Handler for HTML Report ===============================
    output$downloadHTMLButton <- downloadHandler(
      filename = function() {
        paste0(id, "-report-", Sys.Date(), ".html")
      },
      content = function(file) {
        req(reportGenerated())
        if (file.exists(reportHTMLPath)) {
          file.copy(reportHTMLPath, file)
        } else {
          showNotification("HTML not found. Generate report first.", type = "error")
        }
      }
    )

    # === Download Handler for QMD source file ===============================
    output$downloadQMDButton <- downloadHandler(
      filename = function() {
        paste0(id, "-report-", Sys.Date(), ".qmd")
      },
      content = function(file) {
        req(reportGenerated())
        if (file.exists(reportQMDPath)) {
          file.copy(reportQMDPath, file)
        } else {
          showNotification("QMD not found. Generate report first.", type = "error")
        }
      }
    )

    # === Download Handler for TAXA Result ===============================
    output$downloadTaxaCSVButton <- downloadHandler(
      filename = function() {
        paste0(id, "_taxa_estimates_", Sys.Date(), ".csv")
      },
      content = function(file) {
        req(reportGenerated())
        if (file.exists(taxaCSVPath)) {
          taxa_df <- read.csv(taxaCSVPath, row.names = 1)
          is_num <- sapply(taxa_df, is.numeric)
          taxa_df[is_num] <- lapply(taxa_df[is_num], function(x) round(x, 4))
          write.csv(taxa_df, file)
        } else {
          showNotification("Taxa estimates file not found. Please generate the report first.", type = "error")
        }
      }
    )

    # === Download Handler for F Matrix Result ===============================
    output$downloadFMatrixCSVButton <- downloadHandler(
      filename = function() {
        paste0(id, "_fmatrix_", Sys.Date(), ".csv")
      },
      content = function(file) {
        req(reportGenerated())
        if (file.exists(fmatrixCSVPath)) {
          file.copy(fmatrixCSVPath, file)
        } else {
          showNotification("F matrix file not found. Please generate the report first.", type = "error")
        }
      }
    )

    # === Download Handler for MAE Result ===============================
    output$downloadMAECSVButton <- downloadHandler(
      filename = function() {
        paste0(id, "_MAE_", Sys.Date(), ".csv")
      },
      content = function(file) {
        req(reportGenerated())
        if (file.exists(MAECSVPath)) {
          file.copy(MAECSVPath, file)
        } else {
          showNotification("MAE file not found. Please generate the report first.", type = "error")
        }
      }
    )


    # === environment upload ================================================
    # TODO: upload context.rds

    # TODO: download output button controller
    # TODO: download report button controller
  })
}
