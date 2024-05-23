# chemtax-shiny-gui
GUI built using R.shiny for CHEMTAX

# TODO:
* focus on taxa upload/selection

# ===

```R
if (!require('shiny')) install.packages("shiny")
shiny::runApp("app")
```


global.R: data prep and library loading
ui.R: user interface
server.R: server functions



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
