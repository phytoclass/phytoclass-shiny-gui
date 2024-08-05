library(later)
library(glue)

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

    # Display the current values of exec_params in monospace
    output$execParamsDisplay <- renderPrint({
      execParams()
    })

    # === generate the quarto report =========================================
    observeEvent(input$generateButton, {
      print(glue("generating report '{id}'..."))
      output$output = renderUI(renderText("generating report..."))
      exec_params = execParams()  # do this now, use it later
      later::later(function(){
        tryCatch({
          quarto::quarto_render(
            input = qmd_path,
            execute_params = exec_params
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
    })

    # TODO: download output button controller
    # TODO: download report button controller
  })
}

