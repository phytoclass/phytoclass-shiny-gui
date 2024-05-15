# load modules
source("modules/quartoReport.R")

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
        tabPanel("1 Upload Pigment Data",
          markdown("
          # Pigment Sample Matrix
          Select a pigment concentrations file to supply the `Sample Matrix` (aka `S matrix`) of pigment samples.
          [See here for details](https://github.com/USF-IMARS/chemtax-shiny-gui/blob/main/rmd/pigment_matrix.md)
          "),
          fileInput("pigments_file", "Pigments .csv file.",
                    multiple = FALSE,
                    accept = c("text/csv",
                               "text/comma-separated-values,text/plain",
                               ".csv")),
          # TODO: add report?
          # TODO: toggle pigments on/off
        ),
        tabPanel("2 Select Taxa",
                           markdown("
            # Taxa list
            List of taxa expected in the sample.
            **NOTE: Not Yet Implemented.**
          "),
          # TODO: OPTIONAL section
          # csv upload to customize ratios and|or add rows to userMinMax
          #       allow download the default table, allow edits
          # `Ratio Matrix` (aka `F matrix`) is the ratio of pigments relative to chlorophyll a.
          # TODO: select preset dropdown (region)
          selectInput("taxaPreset", "Taxa Preset", list("all", "antarctic")),
          # TODO: or custom preset upload
          fileInput("taxalist_file", "List of taxa .csv file.",
            multiple = FALSE,
            accept = c("text/csv",
                       "text/comma-separated-values,text/plain",
                       ".csv")
          ),
          # TODO: ability to customize - uncheck groups in the preset
          #       example removal:
          #       Sm2 <- Sm[, -4]
        ),
        tabPanel("3 Cluster",
          quartoReportUI("cluster")
          # TODO: save clusters .csv
        ),
        tabPanel("4 Inspect Cluster",
          numericInput("selectedCluster", "selected cluster", 1),
          quartoReportUI("inspectCluster")  # TODO
        ),
        tabPanel("5 Anneal",
          # TODO: seed input & explanation
          numericInput("selectedCluster", "selected cluster", 1),
          quartoReportUI("anneal")
        ),
      )
    )
  )
)
