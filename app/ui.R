ui <- fluidPage(
  # App title ----
  titlePanel(markdown("
# Phytoplankton-From-Pigments GUI v0.0.5
This tool uses the [phytoclass R library](https://cran.r-project.org/web/packages/phytoclass/index.html) to estimate phytoplankton community composition from pigment data.

## How to Cite
TODO

## Feedback
Share your thoughts and report bugs by creating a new issue in the [issue tracker](https://github.com/USF-IMARS/chemtax-shiny-gui/issues).
Questions about phytoclass can also be directed to `phytoclass@outlook.com`.

  ")),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    # Sidebar panel for inputs ----

    sidebarPanel(
      img(src='vertical_collage.jpg', width="100%%"),  # TODO: dynamic sizing, smaller?
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      # Output: Tabset  ----
      tabsetPanel(type = "tabs",
        tabPanel("1 Inputs",
          markdown("
          # Pigment Sample Matrix
          Select a pigment concentrations file to supply the `Sample Matrix` (aka `S matrix`) of pigment samples.
          [See here for details](https://github.com/USF-IMARS/chemtax-shiny-gui/blob/main/rmd/pigment_matrix.md)
          "), # TODO: check these links work
          fileInput("pigments_file", "Pigments .csv file.",
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
          # `Ratio Matrix` (aka `F matrix`) is the ratio of pigments relative to chlorophyll a.
          tags$hr(),  # Horizontal line ------------------------------------
        ),
        tabPanel(
          "2 Cluster",
          actionButton("cluster", "generate report"),
          htmlOutput("cluster_output")
        ),
        # TODO: save clusters .csv
        tabPanel(
          "3 Anneal",
          # TODO: tabPanel with single-cluster & all clusters
          # TODO: add cluster selector
          actionButton("anneal", "generate report"),
          htmlOutput("anneal_output")
        ),
          # TODO: download button
      )
    )
  )
)
