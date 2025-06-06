library(later)
library(glue)
library(here)

# Load function to build the context for report rendering
source("modules/quartoReport/buildContext.R")

# === Function to actually render the report =========
actualRenderReport <- function(
    contextRDSPath, inputCode, output, qmd_path, reportHTMLPath, reportPDFPath, reportQMDPath, id
){
  print("rendering....")
  print(glue("inputCode: {inputCode}"))
  
  # Save the context built using the input code
  contextRDSPath(buildContext(inputCode, output))
  
  # Copy the QMD file to be used in the report
  file.copy(qmd_path, reportQMDPath, overwrite = TRUE)
  print(glue("context: {contextRDSPath()}"))
  tryCatch({
    #==== Render HTML report ===========================
    output_message <- system2(
      command = "quarto",
      args = c("render", qmd_path, "--execute-params", contextRDSPath()),
      stdout = TRUE, stderr = TRUE,
      wait = TRUE
    )
    
    # Check the exit status of the command
    exit_status <- attr(output_message, "status")
    
    # If the exit status is non-zero, treat it as an error
    if (!is.null(exit_status) && exit_status != 0) {
      stop(paste(
        "Command failed with status", exit_status, ":",
        paste(output_message, collapse = "\n")
      ))
    }
    
    # === Render PDF report ============================
    pdf_output_message <- system2(
      command = "quarto",
      args = c("render", qmd_path, "--to", "pdf", "--execute-params", contextRDSPath(), 
               "--output-dir", "download_reports"),
      stdout = TRUE, stderr = TRUE,
      wait = TRUE
    )
    
    # Copy the QMD file for download
    file.copy(qmd_path, reportQMDPath, overwrite = TRUE)
    
    # Copy the PDF to the desired location
    pdf_file <- sub("\\.qmd$", ".pdf", basename(qmd_path))
    if(file.exists(pdf_file)) {
      file.copy(pdf_file, reportPDFPath, overwrite = TRUE)
      file.remove(pdf_file)
    }
    
    # Display the rendered HTML inside an iframe
    output$output <- renderUI({
      tags$iframe(src = reportHTMLPath, width = "100%", height = "800px")
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
    contextRDSPath, setupInputCode, output, qmd_path, reportHTMLPath, id, reportPDFPath, reportQMDPath
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
    qmd_path, reportHTMLPath,
    reportPDFPath,
    reportQMDPath,
    id
  )
}

# === UI Module: Defines report UI (generate/configure/download) ===============
quartoReportUI <- function(id, defaultSetupCode = "x <- 1"){
  ns <- NS(id)
  return(tagList(tabsetPanel(type = "tabs",
                             
    # --- Tab for generating report ---
    tabPanel("generate report",
    verbatimTextOutput(ns("execParamsDisplay")),
    tags$br(),
    actionButton(ns("generateButton"), "generate report"),
    markdown(c(
      "NOTE: please be patient after clicking this button. ",
      "Rendering can take multiple minutes depending on settings."
      )),
    htmlOutput(ns("output"))
    ),
    
    # --- Tab for advanced customization of report parameters ---
    tabPanel("advanced configuration",
      # fileInput(ns("inputFile"), "upload file here OR define configuration below.",
      #   width = "100%",
      #   accept = ".rds",
      #   buttonLabel = "input file",
      #   placeholder = glue("{id}_input.rds")
      # ),
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
   
    # --- Tab for downloading report files ---
    tabPanel("download results",
      # TODO:
      markdown("Use the buttons below to download results from the report."),
      # actionButton(ns("downloadRDSButton"), "download .rds"),
      downloadButton(ns("downloadPDFButton"), "Download PDF"),
      downloadButton(ns("downloadQMDButton"), "Download QMD")
    )
  )))
}


# === Server Logic for Quarto Report Module ==================================
quartoReportServer <- function(id){
  # Paths to report files
  qmd_path <- glue("www/{id}.qmd")
  reportHTMLPath <- glue("{id}.html")
  
  #Creating a directory to store the reports
  dir.create("www/download_reports", showWarnings = FALSE)
  reportPDFPath <- glue("www/download_reports/{id}.pdf") 
  reportQMDPath <- glue("www/download_reports/{id}-report.qmd")
  
  moduleServer(id, function(input, output, session){
    # Reactive object to store path to execution context
    contextRDSPath <- reactiveVal("www/context.yaml")
    
    # Flag to track if report has been generated
    reportGenerated <- reactiveVal(FALSE)

    # === generate the quarto report =========================================
    observeEvent(input$generateButton, {
      output$output = renderUI(renderText("generating report..."))
      renderReport(
        contextRDSPath,
        input$setupInputCode,
        output,
        qmd_path, 
        reportHTMLPath, 
        id,
        reportPDFPath, 
        reportQMDPath
      )
      reportGenerated(TRUE)
    })
    
    # === Download Handler for PDF report ===================================
    output$downloadPDFButton <- downloadHandler(
      filename = function() {
        paste0(id, "-report-", Sys.Date(), ".pdf")
      },
      content = function(file) {
        req(reportGenerated())
        if(file.exists(reportPDFPath)) {
          file.copy(reportPDFPath, file)
        } else {
          showNotification("PDF not found. Generate report first.", type = "error")
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
    
    
    # === environment upload ================================================
    # TODO: upload context.rds

    # TODO: download output button controller
    # TODO: download report button controller
  })
}

