library(later)
library(glue)

quartoReportUI <- function(id){
  ns <- NS(id)
  return(tagList(
    fileInput("inputFile", "output from previous step will be used, else upload file here",
      width = "100%",
      accept = ".rds",
      buttonLabel = "input file",
      placeholder = glue("{id}_input.rds")
    ),
    actionButton(ns("button"), "generate report"),
    htmlOutput(ns("output"))
    # TODO: download output button
    # TODO: download report button
  ))
}

quartoReportServer <- function(id, exec_params){
  qmd_path <- glue("www/{id}.qmd")
  reportHTMLPath <- glue("{id}.html")
  moduleServer(id, function(input, output, session){
    observeEvent(input$button, {
      output$output = renderUI(renderText("generating report..."))
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
      }, 0.1) # Schedule this to run almost immediately after the initial output
    })
  })
}
