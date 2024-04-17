get_df_from_file <- function(filepath){
  # function to read the taxalist & pigment csv files.
  tryCatch({
    # when reading semicolon separated files,
    # having a comma separator causes `read.csv` to error
      df <- read.csv(filepath,
                     header = TRUE,
                     sep = ',',
                     quote = '"')
    },
    error = function(e) {
      # return a safeError if a parsing error occurs
      stop(safeError(e))
    }
  )
  return(df)
}
