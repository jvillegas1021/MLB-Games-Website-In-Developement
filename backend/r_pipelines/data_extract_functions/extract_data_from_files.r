load_csv <- function(name, folder = "data") {
  file_path <- file.path(folder, paste0(name, ".csv"))
  
  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }
  
  read.csv(file_path, stringsAsFactors = FALSE)
}

load_rds <- function(name, folder = "data") {
  file_path <- file.path(folder, paste0(name, ".rds"))
  
  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }
  
  readRDS(file_path)
}
