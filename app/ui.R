ui <- fluidPage(
  # App title ----
  titlePanel("CHEMTAX-R Shiny GUI"),
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    # Sidebar panel for inputs ----
    sidebarPanel(
      tabsetPanel(type = "tabs",
        tabPanel("checklist",
        tags$hr(),  # Horizontal line ------------------------------------
          markdown("**pigments**"), textOutput("pigmentsFileStatusText"),
        tags$hr(),  # Horizontal line ------------------------------------
          markdown("**taxa list**"), textOutput("taxalistFileStatusText"),
        tags$hr(),  # Horizontal line ------------------------------------
          # TODO:
          markdown("**cluster**"), textOutput("clusterSelectStatusText"),
          tags$hr(),  # Horizontal line ------------------------------------
          markdown("**annealing**"), textOutput("annealingStatusText"),
          tags$hr(),  # Horizontal line ------------------------------------
        ),
      ),
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      # Output: Tabset  ----
      tabsetPanel(type = "tabs",
        tabPanel("Input Files",
          markdown("
          # Pigment Sample Matrix
          Select a pigment ratios file.
          One sample per row, one pigment per column.
          **NOTE: Not Yet Implemented.**
          "),
          fileInput("pigments_file", "Pigments .csv file",
                    multiple = FALSE,
                    accept = c("text/csv",
                               "text/comma-separated-values,text/plain",
                               ".csv")),
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
          tags$hr(),  # Horizontal line ------------------------------------
        ),
        tabPanel(
          "Clustering",
          plotOutput("clusterDendrogram"),
          textInput("clusterSelector", "selected cluster", 1),
        ),
        tabPanel(
          "Simulated Annealing",
          verbatimTextOutput("summary")),
        tabPanel(
          "Result (TODO)",
          tableOutput("table")),
      )
    )
  )
)
