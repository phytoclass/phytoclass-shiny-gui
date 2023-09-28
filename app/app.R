library(shiny)

# Define UI for CHEMTAX app ----
ui <- fluidPage(
  # App title ----
  titlePanel("CHEMTAX-R Shiny GUI"),
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    # Sidebar panel for inputs ----
    sidebarPanel(
      tabsetPanel(type = "tabs",
        tabPanel("Input Files",
          markdown("
           # Pigment Sample Matrix
           Select a pigment ratios file.
           One sample per row, one pigment per column.
           **NOTE: Not Yet Implemented.**
           "
          ),
          fileInput("pigments_file", "Pigments .csv file",
                    multiple = FALSE,
                    accept = c("text/csv",
                               "text/comma-separated-values,text/plain",
                               ".csv")),
          textOutput("pigmentsFileStatusText"),
          tags$hr(),  # Horizontal line ------------------------------------
          markdown("
            # Taxa list
            List of taxa expected in the sample.
            **NOTE: Not Yet Implemented.**
          "),
          fileInput("taxalist_file", "List of taxa .csv file.",
            multiple = FALSE,
            accept = c("text/csv",
                       "text/comma-separated-values,text/plain",
                       ".csv")
          ),
          textOutput("taxalistFileStatusText"),
          tags$hr(),  # Horizontal line ------------------------------------
        )
      ),
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      # Output: Tabset  ----
      tabsetPanel(type = "tabs",
        tabPanel(
          "Clustering",
          markdown("NOTE: clustering output is not yet implemented"),
          plotOutput("clusterDendrogram")
        ),
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
  pigmentsDF <- reactiveVal(NULL)

  output$pigmentsFileStatusText <- renderText({
    req(input$pigments_file)
    pigment_df <- get_df_from_file(input$pigments_file$datapath)
   # TODO: validate
    pigmentsDF(pigment_df)
    return("File loaded.")
  })

  output$taxalistFileStatusText <- renderText({
    req(input$taxalist_file)
    taxalist_df <- get_df_from_file(input$taxalist_file$datapath)
    # TODO: validate
    return("File loaded.")
  })

  output$clusterDendrogram <- renderPlot({
    # req(input$pigments_file)
    if(!is.null(pigmentsDF())){
      Cluster.result <- phytoclass::Cluster(pigmentsDF(), 14)
      Cluster.result$cluster.list
      # plot of clusters
      return(plot(Cluster.result$cluster.plot))
    }  # TODO: else show not yet loaded
  })
}

# Create Shiny app ----
shinyApp(ui, server)

