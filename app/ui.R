ui <- fluidPage(
  # App title ----
  titlePanel(
    markdown("
# Phytoplankton-From-Pigments GUI v0.1.0
This tool uses the [phytoclass R library](https://cran.r-project.org/web/packages/phytoclass/index.html) to estimate phytoplankton community composition from pigment data.

## How to Cite
TODO

## Feedback
Share your thoughts and report bugs by creating a new issue in the [issue tracker](https://github.com/USF-IMARS/chemtax-shiny-gui/issues).
Questions about phytoclass can also be directed to `phytoclass@outlook.com`.
  ")
  ),
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    # Sidebar panel for inputs ----
    sidebarPanel(
      tabsetPanel(type = "tabs",
        tabPanel("code",
          markdown("
 The code below is used to generate the \"render\" view.
 Limited manual editing can be done.
 The editing widgets will modify this code and change the report.
          "),
          # TODO: quarto text here
          textAreaInput("configText", "configuration text"),
        ),
        tabPanel("render",
          # TODO: quarto render output here
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
          Select a pigment concentrations file.
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
          # TODO: OPTIONAL section
          # csv upload to customize ratios and|or add rows to userMinMax
          #       allow download the default table, allow edits
          tags$hr(),  # Horizontal line ------------------------------------
        ),
        tabPanel(
          "Clustering",
          plotOutput("clusterDendrogram"),

          # TODO: get these working
          markdown("**clusterSize**"), textOutput("clusterSize", inline=TRUE),
          markdown("**nClusters**"), textOutput("nClusters", inline=TRUE),

          # TODO: dropdown instead of textInput
          textInput("clusterSelector", "selected cluster", 1),

          # TODO: download button for the cluster info
        ),
        tabPanel(
          "Simulated Annealing",
          plotOutput("annealingPlot"),
          verbatimTextOutput("annealingSummary"),

          # TODO: print the F matrix
          # & table for group and ratios

          # TODO: download button
        ),
      )
    )
  )
)
