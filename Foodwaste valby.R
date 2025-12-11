library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(stringr)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  zip <- "2500"   # default hvis ingen argument gives
} else {
  zip <- args[1]  # brug argumentet
}



updateFoodWasteDatabase <- function(zip = zip) {
  
  # ---- API CALL ----
  baseurl <- "https://api.sallinggroup.com/v1/food-waste/?zip="
  fullurl <- paste0(baseurl, zip)
  mytoken <- 'SG_APIM_76MCVAWZZSB0423GN2FE25FWNMYAXV4JB5AMTQD6EJERP8XD4E20'
  
  res <- GET(fullurl, add_headers(Authorization = paste("Bearer", mytoken)))
  resraw <- content(res, as = "text")
  resraw2 <- fromJSON(resraw, flatten = TRUE)
  
  
  # ---- CLEAN MAIN_DF ----
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
  
  
  # ---- CLEAN CLEARANCES ----
  all_clearances <- lapply(seq_along(resraw2$store.id), function(i) {
    
    df <- resraw2$clearances[[i]]
    
    # Tilføj store-id og store-name
    df$store.id   <- resraw2$store.id[i]
    df$store.name <- resraw2$store.name[i]
    
    # Konverter tidsfelter
    datetime_cols <- c("offer.endTime", "offer.lastUpdate", "offer.startTime")
    for (col in datetime_cols) {
      if (col %in% names(df)) {
        df[[col]] <- format(
          as.POSIXct(df[[col]], format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"),
          "%Y-%m-%d %H:%M:%S"
        )
      }
    }
    
    # 👉 Sæt store.id og store.name først i rækkefølgen
    df <- df %>%
      select(
        store.id,
        store.name,
        everything()
      )
    
    df
  })
  
  
  all_clearances_df <- bind_rows(all_clearances)
  
  all_clearances_sql <- all_clearances_df %>%
    rename_with(~ gsub("\\.", "_", .x))
  
  # Returnér DF’er så du kan arbejde med dem
  return(list(
    main_df = main_df_clean,
    clearances_df = all_clearances_sql
  ))
}

# ---- RUN ----
result <- updateFoodWasteDatabase()

# Dine 2 dataframes:
main_df <- result$main_df
clearance_df <- result$clearances_df

View(clearance_df)


con <- dbConnect(
  RMariaDB::MariaDB(),
  dbname   = "SallingValby",
  host     = "localhost",
  user     = "root",
  password = "bondo123",
  port     = 3306
)

dbWriteTable(con, "main_df", main_df, append = TRUE, row.names = FALSE)
dbWriteTable(con, "clearance_df", clearance_df, append = TRUE, row.names = FALSE)

write_xlsx(føtex_df, "Føtex_df.xlsx")

