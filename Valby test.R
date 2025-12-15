# --------------------------------------------------
# DEAKTIVER View() PÅ SERVER
# --------------------------------------------------
if (!interactive()) {
  View <- function(...) NULL
}

options(warn = -1)

# --------------------------------------------------
# COMMAND LINE ARGUMENT
# --------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  zip <- "3450"
} else {
  zip <- args[1]
}

# --------------------------------------------------
# TIMESTAMP START
# --------------------------------------------------
start_time <- Sys.time()

cat("\n===========================\n")
cat("🚀 Kørsel startet:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("===========================\n\n")

cat("➡️  Bruger postnummer:", zip, "\n\n")

# --------------------------------------------------
# PAKKER
# --------------------------------------------------
suppressMessages({
  library(httr)
  library(jsonlite)
  library(dplyr)
  library(purrr)
  library(DBI)
  library(RMariaDB)
})

# --------------------------------------------------
# API CALL
# --------------------------------------------------
cat("Henter API data for", zip, "... ")

baseurl <- "https://api.sallinggroup.com/v1/food-waste/?zip="
fullurl <- paste0(baseurl, zip)

token <- "SG_APIM_76MCVAWZZSB0423GN2FE25FWNMYAXV4JB5AMTQD6EJERP8XD4E20"

res <- GET(
  fullurl,
  add_headers(Authorization = paste("Bearer", token))
)

if (status_code(res) != 200) {
  stop("API-kald fejlede")
}

cat("OK\n")

resraw  <- content(res, as = "text")
resraw2 <- fromJSON(resraw, flatten = TRUE)

# --------------------------------------------------
# MAIN_DF
# --------------------------------------------------
cat("Renser main_df... ")

resraw2$clearances <- map2(
  resraw2$clearances,
  resraw2$store.id,
  ~{
    df <- .x
    if (is.null(df) || nrow(df) == 0) return(data.frame())
    df$store.id <- .y
    df <- df %>% select(store.id, everything())
    df <- df %>% select(
      -offer.currency,
      -offer.stockUnit,
      -offer.ean,
      -product.categories.da
    )
    df
  }
)

main_df <- resraw2 %>%
  as.data.frame() %>%
  select(
    -store.hours,
    -store.type,
    -store.coordinates,
    -store.address.country,
    -store.address.extra
  )

cat("OK\n")

# --------------------------------------------------
# CLEARANCE_DF
# --------------------------------------------------
cat("Renser clearances... ")

clearance_df <- bind_rows(resraw2$clearances)

clearance_df <- clearance_df %>%
  mutate(
    offer.endTime = format(as.POSIXct(offer.endTime, tz = "UTC"), "%Y-%m-%d %H:%M:%S"),
    offer.lastUpdate = format(as.POSIXct(offer.lastUpdate, tz = "UTC"), "%Y-%m-%d %H:%M:%S"),
    offer.startTime = format(as.POSIXct(offer.startTime, tz = "UTC"), "%Y-%m-%d %H:%M:%S")
  )

cat("OK\n")

# --------------------------------------------------
# SQL-KOMPATIBLE KOLONNENAVNE
# --------------------------------------------------
main_df_sql <- main_df %>%
  select(-clearances) %>%
  rename_with(~ gsub("\\.", "_", .x))

clearance_df_sql <- clearance_df %>%
  rename_with(~ gsub("\\.", "_", .x))

# --------------------------------------------------
# DATABASE
# --------------------------------------------------
cat("Forbinder til MariaDB... ")

con <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "localhost",
  dbname   = "SallingValby",
  user     = "root",
  password = Sys.getenv("localpw"),
  port     = 3306
)

cat("OK\n")

# --------------------------------------------------
# WRITE TABLES
# --------------------------------------------------
cat("Skriver main_df... ")
dbWriteTable(con, "main_df", main_df_sql, append = TRUE, row.names = FALSE)
cat("OK\n")

cat("Skriver clearance_df... ")
dbWriteTable(con, "clearance_df", clearance_df_sql, append = TRUE, row.names = FALSE)
cat("OK\n")

dbDisconnect(con)

# --------------------------------------------------
# TIMESTAMP SLUT
# --------------------------------------------------
end_time <- Sys.time()

cat("\n🎉 Kørsel færdig:", format(end_time, "%Y-%m-%d %H:%M:%S"), "\n")
cat("===========================\n\n")

# --------------------------------------------------
# VIS LOKALT
# --------------------------------------------------
View(main_df)
View(clearance_df)
