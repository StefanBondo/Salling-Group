#!/usr/bin/env Rscript

options(warn = -1)   # Fjern unødige warnings i cron

updateFoodWasteDatabase <- function(zip = "2500",
                                    sql_user = "ruser",
                                    sql_pass = "bondo123",
                                    sql_db   = "SallingGroupFoodWaste",
                                    sql_host = "localhost",
                                    sql_port = 3306) {
  
  # ---- TIMESTAMP START (CLEAN LOG) ----
  start_time <- Sys.time()
  cat("\n===========================\n")
  cat("🚀 Kørsel startet: ", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n")
  cat("===========================\n\n")
  
  
  # ---- LOAD PACKAGES ----
  suppressMessages({
    library(httr)
    library(jsonlite)
    library(dplyr)
    library(purrr)
    library(RMariaDB)
    library(stringr)
  })
  
  
  # ---- API CALL ----
  cat("Henter API data... ")
  
  baseurl <- "https://api.sallinggroup.com/v1/food-waste/?zip="
  fullurl <- paste0(baseurl, zip)
  mytoken <- 'SG_APIM_76MCVAWZZSB0423GN2FE25FWNMYAXV4JB5AMTQD6EJERP8XD4E20'
  
  res <- GET(fullurl, add_headers(Authorization = paste("Bearer", mytoken)))
  resraw <- content(res, as = "text")
  resraw2 <- fromJSON(resraw, flatten = TRUE)
  
  cat("OK\n")
  
  
  # ---- CLEAN MAIN_DF ----
  cat("Renser main_df... ")
  
  main_df <- resraw2 %>% as.data.frame()
  main_df_clean <- main_df %>%
    select(
      store.id,
      store.brand,
      store.name,
      store.address.city,
      store.address.street,
      store.address.zip
    ) %>%
    rename_with(~ gsub("\\.", "_", .x))
  
  cat("OK\n")
  
  
  # ---- CLEAN CLEARANCES ----
  cat("Renser clearances... ")
  
  all_clearances <- lapply(seq_along(resraw2$store.id), function(i) {
    df <- resraw2$clearances[[i]]
    
    df$store.id <- resraw2$store.id[i]
    
    datetime_cols <- c("offer.endTime", "offer.lastUpdate", "offer.startTime")
    for (col in datetime_cols) {
      if (col %in% names(df)) {
        df[[col]] <- format(
          as.POSIXct(df[[col]], format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"),
          "%Y-%m-%d %H:%M:%S"
        )
      }
    }
    
    df
  })
  
  # <-- DEN VIGTIGE DEL, DER MANGLEDE
  all_clearances_df <- bind_rows(all_clearances)
  
  all_clearances_sql <- all_clearances_df %>%
    rename_with(~ gsub("\\.", "_", .x))
  
  cat("OK\n")
  
  
  # ---- SQL CONNECT ----
  cat("Forbinder til MariaDB... ")
  
  con <- dbConnect(
    RMariaDB::MariaDB(),
    user = sql_user,
    password = sql_pass,
    host = sql_host,
    port = sql_port,
    dbname = sql_db
  )
  
  cat("OK\n")
  
  
  # ---- WRITE main_df ----
  cat("Skriver main_df... ")
  dbWriteTable(con, "main_df", main_df_clean, append = TRUE, row.names = FALSE)
  cat("OK\n")
  
  
  # ---- WRITE CLEARANCES ----
  cat("Skriver store_clearances... ")
  dbWriteTable(con, "store_clearances", all_clearances_sql, append = TRUE, row.names = FALSE)
  cat("OK\n")
  
  
  # ---- CLOSE ----
  dbDisconnect(con)
  
  end_time <- Sys.time()
  
  cat("\n🎉 Kørsel færdig: ", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")
  cat("===========================\n\n")
}

# ---- RUN AUTOMATICALLY ----
updateFoodWasteDatabase()

