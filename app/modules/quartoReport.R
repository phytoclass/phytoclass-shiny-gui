library(later)
library(glue)

quartoReportUI <- function(id, defaultSetupCode = "x <- 1"){
  ns <- NS(id)
  return(tagList(tabsetPanel(type = "tabs",
    tabPanel("input setup",
      fileInput("inputFile", "upload file here OR define configuration below.",
        width = "100%",
        accept = ".rds",
        buttonLabel = "input file",
        placeholder = glue("{id}_input.rds")
      ),
      textAreaInput("setupInputCode",
        label = "define setup variables here OR use .rds upload above.",
        value = defaultSetupCode,
        width = "100%",
        height = "15em",
        resize = "both"
      ),
      actionButton("reloadEnvButton", "load variables")
    ), tabPanel("generate report",
      actionButton("generateButton", "generate report"),
      htmlOutput("output")
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

quartoReportServer <- function(id, exec_params){
  # Create an object for the exec_params
  execParams <- reactiveValues(exec_params = exec_params)

  qmd_path <- glue("www/{id}.qmd")
  reportHTMLPath <- glue("{id}.html")
  moduleServer(id, function(input, output, session){
    # === generate the quarto report =========================================
    observeEvent(input$generateButton, {
      output$output = renderUI(renderText("generating report..."))
      later::later(function(){
        tryCatch({
          quarto::quarto_render(
            input = qmd_path,
            execute_params = execParams
          )
          output$output <- renderUI({
            tags$iframe(src=reportHTMLPath, width="100%", height="800px")
            # includeHTML("cluster.html")  # expects fragment, not full document
          })
        }, error = function(e) {
          output$output <- renderUI({
            HTML(paste0("<pre>", e, "</pre>"))
          })
          # output$output <- renderPrint(e)
          # TODO: print quarto error? how?
        })
      }, 0.1) # Schedule this to run immediately after the initial output
    })

    # === environment upload ================================================
    # TODO:

    # === environment reload button =========================================
    observeEvent(input$reloadEnvButton, {
      # Get the code from the text area input
      code <- input$setupInputCode

      # Split the code into individual expressions
      expressions <- strsplit(code, "\n")[[1]]

      # Initialize an empty list to store variable declarations
      var_declarations <- list()

      # Evaluate each expression and store variable declarations
      for (expr in expressions) {
        # Parse the expression
        parsed_expr <- tryCatch(parse(text = expr), error = function(e) NULL)

        # Check if the parsed expression is an assignment
        if (!is.null(parsed_expr) && is.call(parsed_expr[[1]]) && parsed_expr[[1]][[1]] == as.symbol("<-")) {
          eval(parsed_expr, envir = .GlobalEnv)
          var_name <- as.character(parsed_expr[[1]][[2]])
          var_value <- get(var_name, envir = .GlobalEnv)
          execParams(execParams()[[var_name]] <- var_value)
        } # TODO: else print error
      }
    })

        # TODO: download output button controller
    # TODO: download report button controller

  })
}
