# chemtax-shiny-gui
GUI built using R.shiny for CHEMTAX

# TODO:
* focus on taxa upload/selection

# Setup
## ubuntu
```bash
sudo apt install libfribidi-dev libfontconfig1-dev libfontconfig1-dev
```

## all
```R
if (!require('devtools')) install.packages("devtools")
devtools::install_local()
```


global.R: data prep and library loading
ui.R: user interface
server.R: server functions


# quartoReport module 
The quartoReport module provides a shiny setup for rendering quarto documents within a shiny server using configurable inputs and downloadable outputs.

```mermaid
graph TD

fileUpload{{File Upload}}

subgraph user files
  pigmentsUserFile[["pigments.csv"]]
  taxaUserFile[["taxa.csv"]]
end

subgraph R environment
  initRDS["inital env RDS"]
  clusterRDSPath["cluster RDS path"]
end

subgraph server files
  pigmentsFile["pigments_{hash}.csv"]
  taxaFile["taxa_{hash}.csv"]
  clusterRDS[["cluster.rds"]]
  annealRDS[["anneal.rds"]]
end

pigmentsUserFile --> fileUpload 
    fileUpload --> pigmentsFile
    fileUpload --> initRDS
taxaUserFile --> fileUpload 
    fileUpload --> taxaFile


pigmentsFile --> cluster{{cluster}} --> clusterRDS

anneal{{anneal}}

clusterRDSPath --> anneal
clusterRDS --> anneal --> annealRDS
```

## .qmd reports
`.qmd` reports used are stored in `./app/www/`. 

## functional overview
1. define input
  * upload .rds
  * (NYI) html to set up the input
  * (NYI)R code to set up variables
2. generate the report with given input
3. download
  * (NYI) .rds of the final environment
  * (NYI) .qmd of the report (including variable setup at beggining)
  * (NYI) .pdf of the report

## reports info flow
Theoretical info flow:

```mermaid
graph TD

fileUpload{{File Upload}}

subgraph user files
  pigmentsUserFile[["pigments.csv"]]
  taxaUserFile[["taxa.csv"]]
end

subgraph R environment
  initRDS["inital env RDS"]
  clusterRDSPath["cluster RDS path"]
end

subgraph server files
  pigmentsFile["pigments_{hash}.csv"]
  taxaFile["taxa_{hash}.csv"]
  clusterRDS[["cluster.rds"]]
  annealRDS[["anneal.rds"]]
end

pigmentsUserFile --> fileUpload 
    fileUpload --> pigmentsFile
    fileUpload --> initRDS
taxaUserFile --> fileUpload 
    fileUpload --> taxaFile


pigmentsFile --> cluster{{cluster}} --> clusterRDS

anneal{{anneal}}

clusterRDSPath --> anneal
clusterRDS --> anneal --> annealRDS
```
