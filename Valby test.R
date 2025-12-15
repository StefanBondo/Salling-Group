# --------------------------------------------------
# COMMAND LINE ARGUMENT (ELLER LOKAL DEFAULT)
# --------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  zip <- "2500"
} else {
  zip <- args[1]
}

cat("➡️ Bruger postnummer:", zip, "\n")

# --------------------------------------------------
# PAKKER
# --------------------------------------------------
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(DBI)
library(RMariaDB)

# --------------------------------------------------
# API CALL
# --------------------------------------------------
baseurl <- "https://api.sallinggroup.com/v1/food-waste/?zip="
fullurl <- paste0(baseurl, zip)

token <- "SG_APIM_76MCVAWZZSB0423GN2FE25FWNMYAXV4JB5AMTQD6EJERP8XD4E20"

res <- GET(
  fullurl,
  add_headers(Authorization = paste("Bearer", token))
)

cat("HTTP status:", status_code(res), "\n")

resraw  <- content(res, as = "text")
resraw2 <- fromJSON(resraw, flatten = TRUE)

# --------------------------------------------------
# CLEARANCES (NESTED)
# --------------------------------------------------
resraw2$clearances <- map2(
  resraw2$clearances,
  resraw2$store.id,
  ~{
    df <- .x
    
    if (is.null(df) || nrow(df) == 0) {
      return(data.frame())
    }
    
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

# --------------------------------------------------
# MAIN_DF (MED NESTED CLEARANCES)
# --------------------------------------------------
main_df <- resraw2 %>%
  as.data.frame() %>%
  select(
    -store.hours,
    -store.type,
    -store.coordinates,
    -store.address.country,
    -store.address.extra
  )

# --------------------------------------------------
# CLEARANCE_DF (FLAD)
# --------------------------------------------------
clearance_df <- bind_rows(resraw2$clearances)

# --------------------------------------------------
# DATETIME → SQL FORMAT
# --------------------------------------------------
clearance_df <- clearance_df %>%
  mutate(
    offer.endTime = as.POSIXct(offer.endTime, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"),
    offer.lastUpdate = as.POSIXct(offer.lastUpdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"),
    offer.startTime = as.POSIXct(offer.startTime, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  ) %>%
  mutate(
    offer.endTime = format(offer.endTime, "%Y-%m-%d %H:%M:%S"),
    offer.lastUpdate = format(offer.lastUpdate, "%Y-%m-%d %H:%M:%S"),
    offer.startTime = format(offer.startTime, "%Y-%m-%d %H:%M:%S")
  )

# --------------------------------------------------
# SQL-KOMPATIBLE KOLONNENAVNE
# --------------------------------------------------
main_df_sql <- main_df %>%
  select(-clearances) %>%
  rename_with(~ gsub("\\.", "_", .x))

clearance_df_sql <- clearance_df %>%
  rename_with(~ gsub("\\.", "_", .x))

# --------------------------------------------------
# DATABASE CONNECTION
# --------------------------------------------------
con <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "localhost",
  dbname   = "SallingValby",
  user     = "root",
  password = "bondo123",
  port     = 3306
)

# --------------------------------------------------
# DBWRITE (MANUELT – INGEN LOOP)
# --------------------------------------------------
dbWriteTable(
  con,
  name = "main_df",
  value = main_df_sql,
  append = TRUE,
  row.names = FALSE
)

dbWriteTable(
  con,
  name = "clearance_df",
  value = clearance_df_sql,
  append = TRUE,
  row.names = FALSE
)

dbDisconnect(con)

# --------------------------------------------------
# VIS LOKALT
# --------------------------------------------------
View(main_df)
View(clearance_df)
