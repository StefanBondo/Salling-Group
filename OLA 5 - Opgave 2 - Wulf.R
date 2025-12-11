#get data
baseurl="https://api.sallinggroup.com/v1/food-waste/?zip="
zip="3450"
fullurl=paste0(baseurl,zip)
mytoken='SG_APIM_76MCVAWZZSB0423GN2FE25FWNMYAXV4JB5AMTQD6EJERP8XD4E20'

res=GET(url=fullurl, add_headers(
  Authorization = paste('Bearer',mytoken)
)
)

res$status_code
resraw=content(res, as='text')
resraw2=fromJSON(resraw, flatten = T)


testclearens=resraw2$clearances[[1]]

#Vores egen
# Indlæs nødvendige pakker ---------------------------------------------
library(httr)       # bruges til API-kald (GET)
library(jsonlite)   # bruges til at konvertere JSON-data til R-objekter
library(dplyr)      # bruges til datamanipulation
library(purrr)      # bruges til funktionel looping (map/map2)

# Definér API-url ------------------------------------------------------
baseurl <- "https://api.sallinggroup.com/v1/food-waste/?zip="  # basis-URL til FoodWaste API
zip <- "3450"                                                  # ønsket postnummer
fullurl <- paste0(baseurl, zip)                                # samler URL + zip

# Salling Group token -------------------------------------------------
mytoken <- 'SG_APIM_20CPK3Z2MYB14BXJT7AA343HJM8H0E1EA3RDC6ACJFDM4Z2RAKE0'

# API-kald -------------------------------------------------------------
res <- GET(
  url = fullurl, 
  add_headers(Authorization = paste('Bearer', mytoken))           # tilføjer token til header
)

# Konverter API-responsen til tekst -----------------------------------
resraw <- content(res, as = "text")        # trækker JSON ud som tekst

# Parse JSON til R-objekt og flader det ud til dataframe-format -------
resraw2 <- fromJSON(resraw, flatten = TRUE)

# ---------------------------------------------------------------------
# Tilføj store.id til hver clearance-tabel og fjern uønskede kolonner
# ---------------------------------------------------------------------
resraw2$clearances <- map2(                # map2 løber gennem to vektorer/lister parallelt:
  resraw2$clearances,                      # 1) hver clearance-liste
  resraw2$store.id,                        # 2) tilhørende store.id
  ~{
    df <- .x                               # .x = den enkelte clearance-dataframe
    
    df$store.id <- .y                      # .y = store.id → tilføjes som kolonne
    df <- df %>% select(store.id, everything())   # gør store.id til første kolonne
    
    # Fjern de uønskede kolonner
    df <- df %>% select(
      -offer.currency,
      -offer.stockUnit,
      -offer.ean,
      -product.categories.da
    )
    
    return(df)                             # returnér det rensede clearance-df
  }
)

# ---------------------------------------------------------------------
# Konverter resraw2 til main_df og fjern uønskede butikskolonner
# ---------------------------------------------------------------------
main_df <- resraw2 %>% 
  as.data.frame() %>%                      # konverterer den nested struktur til dataframe
  select(
    -store.hours,                          # fjern åbningstider
    -store.type,                           #fjern type (Point)
    -store.coordinates,                    #fjern koordinator            
    -store.address.country,                # fjern land
    -store.address.extra                   # fjern ekstra adresseinfo
  )

# Udskriv main_df ------------------------------------------------------
main_df


library(DBI)
library(RMariaDB)

con <- dbConnect(
  RMariaDB::MariaDB(),
  dbname   = "SallingGroupFoodWaste",
  host     = "localhost",
  user     = "root",
  password = "bondo123",
  port     = 3306
)

library(dplyr)

# Liste med alle clearances
all_clearances <- lapply(seq_along(resraw2$store.id), function(i) {
  
  df <- resraw2$clearances[[i]]
  
  # Tilføj store.id som kolonne
  df$store.id <- resraw2$store.id[i]
  
  # Konverter datoformat til SQL format
  datetime_cols <- c("offer.endTime", "offer.lastUpdate", "offer.startTime")
  
  for (col in datetime_cols) {
    if (col %in% names(df)) {
      df[[col]] <- format(
        as.POSIXct(df[[col]], format = "%Y-%m-%dT%H:%M:%OSZ", tz="UTC"),
        "%Y-%m-%d %H:%M:%S"
      )
    }
  }
  
  df
})

# Rbind alle dataframes til én stor tabel
all_clearances_df <- bind_rows(all_clearances)

# Lav SQL-kompatible kolonnenavne (punktummer → underscore)
all_clearances_sql <- all_clearances_df %>%
  rename_with(~ gsub("\\.", "_", .x))

# all_clearances_sql er det samlede df med _ i kolonnenavne
dbWriteTable(
  con,
  "store_clearances",
  all_clearances_sql,
  append = TRUE,
  row.names = FALSE
)

