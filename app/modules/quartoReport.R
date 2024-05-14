library(later)

quartoReportUI <- function(id){
  ns <- NS(id)
  return(tagList(
    actionButton(ns("button"), "generate report"),
    htmlOutput(ns("output"))
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
          output$output = renderPrint(e)
          # TODO: print quarto error? how?
        })
      }, 0.1) # Schedule this to run almost immediately after the initial output
    })
  })
}
