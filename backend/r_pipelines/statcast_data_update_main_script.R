
scripts_to_run <- list(
  "Statcast Data Update"  = "backend/r_pipelines/statcast_data/pipelines/update_statcast_data/script/update_statcast_data_script.R"
)

run_step <- function(step_name, script_path) {
  start_time <- Sys.time()
  message(sprintf("[%s] STARTING: %s", format(start_time, "%Y-%m-%d %H:%M:%S"), step_name))
  
  status <- tryCatch({
    # local = new.env() keeps objects from leaking between pipelines
    source(script_path, local = new.env())
    
    elapsed <- round(difftime(Sys.time(), start_time, units = "secs"), 1)
    message(sprintf("[%s] FINISHED: %s (%s sec)", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), step_name, elapsed))
    "SUCCESS"
    
  }, error = function(e) {
    message(sprintf("[%s] FAILED: %s -> %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), step_name, e$message))
    "FAILED"
  })
  
  return(status)
}

# 3. Run sequentially and print a summary
message("=== Starting Statcast Data Update ===")
results <- mapply(run_step, names(scripts_to_run), scripts_to_run)

message("=== Summary ===")
for (name in names(results)) {
  message(sprintf("  %-20s : %s", name, results[[name]]))
}
