#!/usr/bin/env Rscript

if (!interactive()) {
  View <- function(...) NULL  # Disable View() in non-interactive mode
}


options(warn = -1)

# ---- COMMAND LINE ARGUMENT ----
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  zip <- "2500"  # default hvis ikke man giver et argument
} else {
  zip <- args[1]
}

cat("➡️  Bruger postnummer:", zip, "\n\n")


updateFoodWasteDatabase <- function(zip,
                                    sql_user = "salling",
                                    sql_pass = "ValbyStrongPassword123!",
                                    sql_db   = "SallingValby",
                                    sql_host = "localhost",
                                    sql_port = 3306) {
  
  # ---- TIMESTAMP ----
  start_time <- Sys.time()
  cat("\n===========================\n")
  cat("🚀 Kørsel startet:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n")
  cat("===========================\n\n")
  
  # ---- LOAD PACKAGES ----
  suppressMessages({
    library(httr)
    library(jsonlite)
    library(dplyr)
    library(purrr)
    library(RMariaDB)
  })
  
  # ---- API CALL ----
  cat("Henter API data for", zip, "... ")
  
  baseurl <- "https://api.sallinggroup.com/v1/food-waste/?zip="
  fullurl <- paste0(baseurl, zip)
  token <- 'SG_APIM_76MCVAWZZSB0423GN2FE25FWNMYAXV4JB5AMTQD6EJERP8XD4E20'
  
  res <- GET(fullurl, add_headers(Authorization = paste("Bearer", token)))
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

    # 🚨 FIX: Skip stores with no clearances
    if (is.null(df) || nrow(df) == 0) {
        return(NULL)
    }

    df$store.id   <- resraw2$store.id[i]
    df$store.name <- resraw2$store.name[i]

    datetime_cols <- c("offer.endTime", "offer.lastUpdate", "offer.startTime")
    for (col in datetime_cols) {
        if (col %in% names(df)) {
            df[[col]] <- format(
                as.POSIXct(df[[col]], format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"),
                "%Y-%m-%d %H:%M:%S"
            )
        }
    }

    df <- df %>% select(store.id, store.name, everything())

    return(df)
})

clearance_df <- bind_rows(all_clearances)
clearance_df <- clearance_df %>% rename_with(~ gsub("\\.", "_", .x))

cat("OK\n")

  
  # ---- WRITE TO DATABASE ----
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
  
  cat("Skriver main_df... ")
  dbWriteTable(con, "main_df", main_df_clean, append = TRUE, row.names = FALSE)
  cat("OK\n")
  
  cat("Skriver clearance_df... ")
  dbWriteTable(con, "clearance_df", clearance_df, append = TRUE, row.names = FALSE)
  cat("OK\n")
  
  dbDisconnect(con)
  
  end_time <- Sys.time()
  cat("\n🎉 Kørsel færdig:", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")
  cat("===========================\n\n")
}

# ---- RUN FUNCTION ----
updateFoodWasteDatabase(zip)
