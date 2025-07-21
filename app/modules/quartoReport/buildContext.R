library(yaml)
library(digest)
library(glue)

buildContext <- function(inputCode, bypass_clustering, output, session_id, session_dir){
  # create context file from inputs
  print("reloading environment...")

  # Get the code from the text area input
  print(glue("inputCode: {inputCode}"))
  code <- inputCode

  # Split the code into individual expressions
  expressions <- strsplit(code, "\n")[[1]]

  # Initialize an empty list to store variable declarations
  var_declarations <- list()

  execParams <- list()
  execParams$session_dir <- session_dir

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
      execParams[[var_name]] <- var_value
    } else {
      print(glue("error in param expression: '{expr}'"))
    }
  }

  if (isTRUE(bypass_clustering)) {
    execParams$inputFile <- "pigments.rds"
  } else if (is.null(execParams$inputFile)) {
    execParams$inputFile <- "clusters.rds"
  }

  contextParams <- execParams

  # Generate hash of parameter set
  paramString <- paste0(capture.output(str(contextParams)), collapse = "")

  contextPath <- file.path(session_dir, "context.yaml")
  write_yaml(contextParams, contextPath)

  return(contextPath)
}
