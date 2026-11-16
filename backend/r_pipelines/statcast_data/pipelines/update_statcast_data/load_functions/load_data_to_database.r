write_df_to_sql_replace <- function(df, table_name) {
    con <- dbConnect(
        RPostgres::Postgres(),
        host = Sys.getenv("DB_HOST"),
        dbname = Sys.getenv("DB_NAME"),
        user = Sys.getenv("DB_USER"),
        password = Sys.getenv("DB_PASSWORD"),
        port = as.integer(Sys.getenv("DB_PORT")),
        sslmode = Sys.getenv("DB_SSLMODE")
      )

    dbWriteTable(
        conn = con,
        name = table_name,
        value = df,
        overwrite = TRUE,   # ⭐ THIS REPLACES THE TABLE
        row.names = FALSE
      )
    rows <- nrow(df)
    print(paste("Successfully replaced", rows, "to the ", table_name, "."))
    dbDisconnect(con)
}

write_df_to_sql_append <- function(df, table_name) {
  df <- as.data.frame(df)
  con <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("DB_HOST"),
    dbname = Sys.getenv("DB_NAME"),
    user = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASSWORD"),
    port = as.integer(Sys.getenv("DB_PORT")),
    sslmode = Sys.getenv("DB_SSLMODE")
  )
  
  dbWriteTable(
    conn = con,
    name = table_name,
    value = df,
    append = TRUE,
    row.names = FALSE
  )
  
  rows <- nrow(df)
  print(paste("Successfully appended", rows, "to the ", table_name, "."))
  
  dbDisconnect(con)
}

delete_pitcher_stats_from_df <- function(table_name, pitcher_ids) {
  con <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("DB_HOST"),
    dbname = Sys.getenv("DB_NAME"),
    user = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASSWORD"),
    port = as.integer(Sys.getenv("DB_PORT")),
    sslmode = Sys.getenv("DB_SSLMODE")
  )
  
  quoted_pitcher_ids <- sprintf("'%s'", pitcher_ids)
  pitcher_id_string <- paste(quoted_pitcher_ids, collapse = ",")
  
  query <- sprintf('DELETE FROM %s WHERE "xMLBAMID" IN (%s)', table_name, pitcher_id_string)
  
  rows_affected <- dbExecute(con, query)
  print(paste("Successfully deleted", rows_affected, "pitcher record rows from database."))
  
  # 4. Clean up connection channel
  dbDisconnect(con)
}

delete_statcast_rows_from_df <- function(table_name, date_range) {
  
  if (length(date_range) == 0) {
    message("Empty date_range provided. Skipping delete.")
    return(invisible(0))
  }
  
  con <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("DB_HOST"),
    dbname = Sys.getenv("DB_NAME"),
    user = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASSWORD"),
    port = as.integer(Sys.getenv("DB_PORT")),
    sslmode = Sys.getenv("DB_SSLMODE")
  )
  
  on.exit(dbDisconnect(con), add = TRUE)
  
  formatted_dates <- paste0("'", as.character(date_range), "'", collapse = ", ")
  
  query <- sprintf('DELETE FROM %s WHERE "game_date" IN (%s);', table_name, formatted_dates)
  
  rows_affected <- dbExecute(con, query)
  print(paste("Successfully deleted", rows_affected, "statcast record rows from database."))
  
  return(invisible(rows_affected))
}