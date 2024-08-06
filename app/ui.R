ui <- fluidPage(
  # App title ----
  titlePanel(markdown(paste0(
    "# Phytoplankton-From-Pigments GUI v0.0.5 \n",
    "This tool uses the [phytoclass R library](",
    "https://cran.r-project.org/web/packages/phytoclass/index.html",
    ") to estimate phytoplankton community composition from pigment data. \n",
    "\n",
    "## How to Cite \n",
    "TODO \n",
    "\n",
    "## Feedback \n",
    "Share your thoughts and report bugs by creating a new issue in the ",
    "[issue tracker](https://github.com/USF-IMARS/chemtax-shiny-gui/issues). \n",
    "Questions about phytoclass can also be directed to `phytoclass@outlook.com`."
  ))),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    # Sidebar panel for inputs ----

    sidebarPanel(
      img(src='vertical_collage.jpg', width="100%%"),
      width = 2
    ),
    # Main panel for displaying outputs ----
    mainPanel(
      # Output: Tabset  ----
      tabsetPanel(type = "tabs",
        tabPanel("Upload Data Files",
          markdown(paste0(
            "# Pigment Sample Matrix \n",
            "Select a pigment concentrations file to supply the ",
            "`Sample Matrix` (aka `S matrix`) of pigment samples. \n",
            "[See here for details]",
            "(https://github.com/USF-IMARS/chemtax-shiny-gui/blob/main/rmd/pigment_matrix.md)"
          )),
          fileInput("pigments_file", "Pigments .csv file.",
            multiple = FALSE,
            accept = c("text/csv",
              "text/comma-separated-values,text/plain",
              ".csv"
            )
          ),
          # TODO: add report?
          # TODO: toggle pigments on/off
           markdown("
            # Taxa list
            List of taxa expected in the sample.
            **NOTE: Not Yet Implemented.**
          "),
          # TODO: OPTIONAL section
          # csv upload to customize ratios and|or add rows to userMinMax
          #       allow download the default table, allow edits
          # `Ratio Matrix` (aka `F matrix`) is the ratio of pigments
          #       relative to chlorophyll a.
          # TODO: select preset dropdown (region)
          selectInput("taxaPreset", "Taxa Preset", list("all", "antarctic")),
          # TODO: or custom preset upload
          fileInput("taxalist_file", "List of taxa .csv file.",
            multiple = FALSE,
            accept = c("text/csv",
                       "text/comma-separated-values,text/plain",
                       ".csv"
            )
          )
          # TODO: ability to customize - uncheck groups in the preset
          #       example removal:
          #       Sm2 <- Sm[, -4]
        ),
        tabPanel("Run Clustering",
          quartoReportUI("cluster",
            defaultSetupCode = paste(
              "inputFile <- 'pigments.rds'",
              "outputFile <- 'clusters.rds'",
              sep="\n"
            )
          )
          # TODO: save clusters .csv
        ),
        tabPanel("Inspect a Cluster",
          quartoReportUI("inspectCluster",
            defaultSetupCode = "selectedCluster <- 1"
          )
        ),
        tabPanel("Run Annealing on a Cluster",
          # TODO: seed input & explanation
          quartoReportUI("anneal",
            # TODO: fill these to match .qmd
            defaultSetupCode = paste(
              "inputFile <- 'clusters.rds'",
              "outputFile <- 'annealing.rds'",
              "seed <- 0",
              "selected_cluster <- 1",
              "niter <- 10",
              sep="\n"
            )
          )
        ),
      ),
    width = 10
    )
  )
)
