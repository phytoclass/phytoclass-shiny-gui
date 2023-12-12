ui <- fluidPage(
  # App title ----
  titlePanel("Phytoplankton-From-Pigments GUI"),
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    # Sidebar panel for inputs ----
    sidebarPanel(
      tabsetPanel(type = "tabs",
        tabPanel("about",
          markdown("
            This tool uses the [phytoclass R library](https://cran.r-project.org/web/packages/phytoclass/index.html) to estimate phytoplankton community composition from pigment data.

            ## How to Cite
            TODO

            ## Feedback
            Share your thoughts and report bugs by creating a new issue in the [issue tracker](https://github.com/USF-IMARS/chemtax-shiny-gui/issues).
            Questions about phytoclass can also be directed to `phytoclass@outlook.com`.
          ")
        ),
        tabPanel("config",
          markdown("Configuration text `key=value` lines here. One per line. Use `#` for comments."),
          textAreaInput("configText", "configuration text"),
        ),
        tabPanel("status",
        tags$hr(),  # Horizontal line ------------------------------------
          markdown("**pigments**"), textOutput("pigmentsFileStatusText"),
        tags$hr(),  # Horizontal line ------------------------------------
          markdown("**taxa list**"), textOutput("taxalistFileStatusText"),
        tags$hr(),  # Horizontal line ------------------------------------
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
          [See here for details](https://github.com/USF-IMARS/chemtax-shiny-gui/blob/main/rmd/pigment_matrix.Rmd)
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
          markdown("**clusterSize**"), textOutput("clusterSize", inline=TRUE),
          markdown("**nClusters**"), textOutput("nClusters", inline=TRUE),
          textInput("clusterSelector", "selected cluster", 1),
        ),
        tabPanel(
          "Simulated Annealing",
          plotOutput("annealingPlot"),
          verbatimTextOutput("annealingSummary")
        ),
      )
    )
  )
)
