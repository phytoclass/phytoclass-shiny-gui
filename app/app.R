library(shiny)
 
# Define UI for CHEMTAX app ----
ui <- fluidPage(
  # App title ----
  titlePanel("CHEMTAX-R Shiny GUI"),
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    # Sidebar panel for inputs ----
    sidebarPanel(
      # one sample per row, one pigment per column
      fileInput("pigments_file", "samples pigment data table",
                multiple = FALSE,
                accept = c("text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv")),
      # Horizontal line ----
      tags$hr(),
      fileInput("taxalist_file", "list of taxa present",
                multiple = FALSE,
                accept = c("text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv")),
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      # Output: Tabset  ----
      tabsetPanel(type = "tabs",
        tabPanel(
          "Load Files",
          tableOutput("pigments_table"),
          tableOutput("taxalist_table")),
        tabPanel(
          "Perform RMS (TODO)", 
          verbatimTextOutput("summary")),
        tabPanel(
          "Result (TODO)", 
          tableOutput("table"))
      )
    )
  )
)

# Helper functions ----
get_df_from_file <- function(filepath){
  # function to read the taxalist & pigment csv files.
  tryCatch({
    # when reading semicolon separated files,
    # having a comma separator causes `read.csv` to error
      df <- read.csv(filepath,
                     header = TRUE,
                     sep = ',',
                     quote = '"')
    },
    error = function(e) {
      # return a safeError if a parsing error occurs
      stop(safeError(e))
    }
  )
  return(df)
}

# Define server logic for app ----
server <- function(input, output) {
  output$pigments_table <- renderTable({
    req(input$pigments_file)

    pigment_df <- get_df_from_file(input$pigments_file$datapath)

    return(head(pigment_df))
  })
  output$taxalist_table <- renderTable({
    req(input$taxalist_file)
    
    taxalist_df <- get_df_from_file(input$taxalist_file$datapath)
    
    return(head(taxalist_df))
  })
}

# Create Shiny app ----
shinyApp(ui, server)

