Min-Max Matrix
The Min-Max Matrix is used to define upper and lower bounds for pigment-to-Chl a ratios for each phytoplankton group and pigment. This helps constrain the simulated annealing process and prevents biologically unrealistic solutions.

An example min-max matrix can be found at vignettes/custom-example-min-max.csv.

This file is optional. If no matrix is uploaded, default bounds provided by the phytoclass package will be used.

The file must contain three columns:
    1. Class – the phytoplankton group name (must match the rows of the F matrix).
    2. Pig_Abbrev/ Pigments – the pigment abbreviation (must match the columns of the S and F matrices).
    3. min and max – numeric lower and upper bounds for each pigment-class pair.

Multiple rows may refer to the same class or pigment.

Values will only be applied if both the class and pigment are present in the simulation.

If min or max is missing for a given pair, the default value will be used instead.

For more details on how to construct a min-max matrix or modify the default one, refer to the [phytoclass documentation]( https://cran.r-project.org/web/packages/phytoclass/vignettes/phytoclass-vignette.html).