

###################### GET DATA FROM DATABASE ############################################################

get_data_from_database <- function(table_name) {

  con <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("DB_HOST"),
    dbname = Sys.getenv("DB_NAME"),
    user = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASSWORD"),
    port = as.integer(Sys.getenv("DB_PORT")),
    sslmode = Sys.getenv("DB_SSLMODE")
  )

  query <- paste0('SELECT
    *
  FROM ', table_name)
  
  df <- dbGetQuery(con, query)                    
  
  dbDisconnect(con)
  
  return(df)
}

