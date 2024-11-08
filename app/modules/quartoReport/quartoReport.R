library(later)
library(glue)
library(here)

source("modules/quartoReport/buildContext.R")

actualRenderReport <- function(
    contextRDS, output, qmd_path, reportHTMLPath
){
  # render quarto report immediately using given context
  # should be used in a callback (later) to avoid UI lockup
  print("rendering....")
  print(glue("context: {contextRDS}"))

  tryCatch({
    # Run the command and capture output and error messages
    output_message <- system2(
      command = "quarto",
      args = c("render", qmd_path, "--execute-params", contextRDS),
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

    # If the command is successful, render the iframe with the report
    output$output <- renderUI({
      tags$iframe(src = reportHTMLPath, width = "100%", height = "800px")
    })
  }, error = function(e) {
    # If there is an error, render the captured output as HTML
    output$output <- renderUI({
      HTML(paste0(
        "ERROR while rendering! Please check your inputs.\n",
        'For help please ',
        '<a href="https://github.com/USF-IMARS/chemtax-shiny-gui/issues/new">',
        'open an issue on the project github</a> and include the text below.',
        "<pre>", paste(output_message, collapse = "\n"), "</pre>"
      ))
    })
  })
}

renderReport <- function(
    contextRDS, output, qmd_path, reportHTMLPath, id
){
  # renderReport schedules the render for later so that the "generating report..." text shows immediately
  print(glue("generating report '{id}'..."))
  print(glue("context: {contextRDS}"))

  output$output = renderUI(renderText("generating report..."))
  later::later(function(){
    actualRenderReport(
      contextRDS,
      output,
      qmd_path, reportHTMLPath
    )
  }, 0.1) # Schedule this to run immediately after the initial output
}
quartoReportUI <- function(id, defaultSetupCode = "x <- 1"){
  ns <- NS(id)
  return(tagList(tabsetPanel(type = "tabs",
    tabPanel("input setup",
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
      ),
      actionButton(ns("reloadEnvButton"), "load variables from text input")
    ), tabPanel("generate report",
      verbatimTextOutput(ns("execParamsDisplay")),
      actionButton(ns("generateButton"), "generate report"),
      htmlOutput(ns("output"))
    )
    # TODO:
    # tabPanel("download results",
    #   # TODO:
    #   markdown("Use the buttons below to download results from the report."),
    #   actionButton(ns("downloadRDSButton"), "download .rds"),
    #   actionButton(ns("downloadPDFButton"), "download .pdf"),
    #   actionButton(ns("downloadQMDButton"), "download .qmd")
    # )
  )))
}

quartoReportServer <- function(id){
  qmd_path <- glue("www/{id}.qmd")
  reportHTMLPath <- glue("{id}.html")
  moduleServer(id, function(input, output, session){
    # Create an object for the exec_params
    contextRDSPath <- reactiveVal("www/context.yaml")

    # === generate the quarto report =========================================
    observeEvent(input$generateButton, {
      renderReport(
        contextRDSPath(),    # TODO: use real context.rds path
        output,
        qmd_path, reportHTMLPath, id
      )
    })

    # === environment upload ================================================
    # TODO: upload context.rds

    # === environment reload button =========================================
    observeEvent(input$reloadEnvButton, {
      contextRDSPath(buildContext(input, output))
    })

    # TODO: download output button controller
    # TODO: download report button controller
  })
}

