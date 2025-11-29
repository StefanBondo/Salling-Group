updateFoodWasteDatabase <- function(zip = "3450",
                                    sql_user = "ruser",
                                    sql_pass = "bondo123",
                                    sql_db   = "SallingGroupFoodWaste",
                                    sql_host = "localhost",
                                    sql_port = 3306) {
  
  library(httr)
  library(jsonlite)
  library(dplyr)
  library(purrr)
  library(RMariaDB)
  library(stringr)
  
  message("🔄 Henter data fra Salling Group API...")
  
  # ---- API CALL ----
  baseurl <- "https://api.sallinggroup.com/v1/food-waste/?zip="
  fullurl <- paste0(baseurl, zip)
  
  mytoken <- 'SG_APIM_76MCVAWZZSB0423GN2FE25FWNMYAXV4JB5AMTQD6EJERP8XD4E20'
  
  res <- GET(fullurl, add_headers(Authorization = paste("Bearer", mytoken)))
  resraw <- content(res, as = "text")
  resraw2 <- fromJSON(resraw, flatten = TRUE)
  
  message("✅ API data hentet")
  
  
  # ---- CLEAN MAIN_DF ----
  message("🔄 Renser main_df...")
  
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
  
  message("✅ main_df klar")
  
  
  # ---- CLEAN CLEARANCES ----
  message("🔄 Renser og samler alle clearances...")
  
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
  
  all_clearances_df <- bind_rows(all_clearances)
  
  all_clearances_sql <- all_clearances_df %>%
    rename_with(~ gsub("\\.", "_", .x))
  
  message("✅ Clearances samlet")
  
  
  # ---- SQL CONNECT ----
  message("🔄 Forbinder til MariaDB...")
  
  con <- dbConnect(
    RMariaDB::MariaDB(),
    user = sql_user,
    password = sql_pass,
    host = sql_host,
    port = sql_port,
    dbname = sql_db
  )
  
  message("✅ Forbundet til MariaDB")
  
  
  # ---- SKRIV main_df ----
  message("🔄 Skriver til main_df...")
  dbWriteTable(con, "main_df", main_df_clean, append = TRUE, row.names = FALSE)
  message("✅ main_df opdateret")
  
  
  # ---- SKRIV CLEARANCES ----
  message("🔄 Skriver til store_clearances...")
  dbWriteTable(con, "store_clearances", all_clearances_sql, append = TRUE, row.names = FALSE)
  message("✅ store_clearances opdateret")
  
  
  # ---- SLUT ----
  dbDisconnect(con)
  message("🎉 Database opdatering FÆRDIG! Alt kører nu.")
}

# ---------------------------------------------------------
# KØR FUNKTIONEN (DENNE LINJE ER DET DER MANGLEDE)
# ---------------------------------------------------------

updateFoodWasteDatabase()
