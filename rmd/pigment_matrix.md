The pigment matrix files should include one sample per row and one pigment per column.

An example pigment matrix file can be found in [sample_data/sm.csv](https://github.com/USF-IMARS/chemtax-shiny-gui/blob/main/app/sample_data/sm.csv).

* The order of the pigment columns does not matter but Chlorophyll-a **must** be the last column.
* Blank or zero values can be used.
* A mapping of the pigment abbreviations to proper pigment names will soon be published by the phytoclass package.

Detailed information on the creation of a pigment matrix can be found in the [phytoclass documentation]( https://cran.r-project.org/web/packages/phytoclass/vignettes/phytoclass-vignette.html)

