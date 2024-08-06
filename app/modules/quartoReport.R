library(later)
library(glue)

buildContext <- function(input, output, execParams){
  # create context .rds from inputs
  print("reloading environment...")

  # Get the code from the text area input
  code <- input$setupInputCode

  # Split the code into individual expressions
  expressions <- strsplit(code, "\n")[[1]]

  # Initialize an empty list to store variable declarations
  var_declarations <- list()

  # Evaluate each expression and store variable declarations
  for (expr in expressions) {
    # Parse the expression
    parsed_expr <- tryCatch(parse(text = expr),
                            error = function(e) glue("# invalid code '{expr}'")
    )

    # Check if the parsed expression is an assignment
    if (
      !is.null(parsed_expr) &&
      is.call(parsed_expr[[1]]) &&
      parsed_expr[[1]][[1]] == as.symbol("<-")
    ) {
      eval(parsed_expr, envir = .GlobalEnv)
      var_name <- as.character(parsed_expr[[1]][[2]])
      var_value <- get(var_name, envir = .GlobalEnv)
      print(glue("execParam set {var_name}<-{var_value}"))
      tempList <- execParams()
      tempList[[var_name]] <- var_value
      execParams(tempList)
    } else {
      print(glue("error in param expression: '{expr}'"))
    }
  }
  contextParams <- execParams()
  # Display the current values of exec_params in monospace
  output$execParamsDisplay <- renderPrint({
    contextParams
  })

  contextRDSPath <- "context.rds"  # TODO: generate better filename (with hash?)

  saveRDS(contextParams, file = contextRDSPath)
  return(contextRDSPath)
}

actualRenderReport <- function(
    contextRDS, output, qmd_path, exec_params, reportHTMLPath
){
  # render quarto report immediately using given context
  # should be used in a callback (later) to avoid UI lockup
  tryCatch({
    # Run the command and capture output and error messages
    output_message <- system2(
      command = "quarto",
      args = c("render", qmd_path, "--execute-params", exec_params),
      stdout = TRUE, stderr = TRUE,
      wait = TRUE
    )

    # Check the exit status of the command
    exit_status <- attr(output_message, "status")

    # If the exit status is non-zero, treat it as an error
    if (!is.null(exit_status) && exit_status != 0) {
      stop(paste("Command failed with status", exit_status, ":", paste(output_message, collapse = "\n")))
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
    contextRDS, output, qmd_path, execParams, reportHTMLPath, id
){
  # renderReport schedules the render for later so that the "generating report..." text shows immediately
  print(glue("generating report '{id}'..."))
  output$output = renderUI(renderText("generating report..."))
  exec_params = execParams()  # do this now, use it later
  later::later(function(){
    actualRenderReport(
      contextRDS,
      output,
      qmd_path, exec_params, reportHTMLPath
    )
  }, 0.1) # Schedule this to run immediately after the initial output
}
quartoReportUI <- function(id, defaultSetupCode = "x <- 1"){
  ns <- NS(id)
  return(tagList(tabsetPanel(type = "tabs",
    tabPanel("input setup",
      fileInput(ns("inputFile"), "upload file here OR define configuration below.",
        width = "100%",
        accept = ".rds",
        buttonLabel = "input file",
        placeholder = glue("{id}_input.rds")
      ),
      textAreaInput(ns("setupInputCode"),
        label = "define setup variables here OR use .rds upload above OR leave defaults.",  # TODO: add link to help docs for paramters
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
    execParams <- reactiveVal(list())
    # TODO: replace execParams with contextRDSPath
    contextRDSPath <- reactiveVal(NULL)

    # === generate the quarto report =========================================
    observeEvent(input$generateButton, {
      renderReport(
        contextRDSPath(),    # TODO: use real context.rds path
        output,
        qmd_path, execParams, reportHTMLPath, id
      )
    })

    # === environment upload ================================================
    # TODO:

    # === environment reload button =========================================
    observeEvent(input$reloadEnvButton, {
      contextRDSPath(buildContext(input, output, execParams))
    })

    # TODO: download output button controller
    # TODO: download report button controller
  })
}

