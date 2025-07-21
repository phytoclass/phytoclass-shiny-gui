Taxa Matrix (F Matrix)

The taxa matrix (also called the F matrix) defines the expected contribution of each pigment to chlorophyll-a for different phytoplankton groups.

An example F matrix file can be found at [sample_data/taxa.csv](https://github.com/USF-IMARS/chemtax-shiny-gui/blob/main/app/sample_data/taxa.csv)..

If no taxa matrix is uploaded, default values will be used.

The order of pigment columns must match the pigment matrix (S matrix).

Column names in the F matrix must exactly match those in the S matrix (case-sensitive).

Each row represents a taxonomic group (e.g., Diatoms, Dinoflagellates, etc.), and each value represents the expected pigment:Chl a ratio for that group.

Zero or blank values are allowed for unavailable data.

For more details on how to construct and interpret an F matrix, see the [phytoclass documentation]( https://cran.r-project.org/web/packages/phytoclass/vignettes/phytoclass-vignette.html)