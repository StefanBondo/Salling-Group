####################################################
# Salling Group - Anti Food Waste
# Hent data lokalt for flere postnumre
# HVER linje forklaret
####################################################

# Indlæser pakker der bruges til API-kald, JSON parsing og datahåndtering
library(httr)      # bruges til GET requests
library(jsonlite)  # bruges til at konvertere JSON → R
library(dplyr)     # bruges til at samle dataframes

# Gemmer din Salling Group API token i en variabel
sg_token <- "SG_APIM_20CPK3Z2MYB14BXJT7AA343HJM8H0E1EA3RDC6ACJFDM4Z2RAKE0"

# Liste over de postnumre du vil hente data for
zips <- c("3450", "4600", "3600", "3400")

####################################################
# Funktion der henter data for ét postnummer
####################################################
get_foodwaste_zip <- function(zip) {
  
  # Bygger URL med det aktuelle postnummer
  url <- paste0("https://api.sallinggroup.com/v1/food-waste/?zip=", zip)
  
  # Sender GET-request med din token i Authorization-header
  res <- GET(
    url,
    add_headers(Authorization = paste("Bearer", sg_token))
  )
  
  # Hvis API’et returnerer fejl (404, 500 osv.) stopper vi denne iteration
  if (http_error(res)) {
    warning("Fejl for postnr ", zip,
            " - status: ", status_code(res))
    return(NULL)
  }
  
  # Henter API-svaret som tekst
  raw_txt <- content(res, as = "text", encoding = "UTF-8")
  
  # Konverterer JSON-teksten til en R-liste
  stores_list <- fromJSON(raw_txt, simplifyVector = FALSE)
  
  # Hvis der ingen butikker er i området → returnér NULL
  if (length(stores_list) == 0) return(NULL)
  
  # En tom liste der skal fyldes med hver clearance
  rows <- list()
  i <- 1  # tæller placering
  
  # Loop gennem alle butikker i API-svaret
  for (store in stores_list) {
    
    # Hvis butikken ikke har clearances springes den over
    if (length(store$clearances) == 0) next
    
    # Loop gennem alle tilbud i butikken
    for (cl in store$clearances) {
      
      # Funktion der laver NULL → NA, så data.frame ikke fejler
      safe <- function(x) if (is.null(x)) NA else x
      
      # Laver én række i data.frame for hvert tilbud
      rows[[i]] <- data.frame(
        zip          = safe(store$store$address$zip),
        city         = safe(store$store$address$city),
        brand        = safe(store$store$brand),
        store_name   = safe(store$store$name),
        
        product_ean  = safe(cl$product$ean),
        product_desc = safe(cl$product$description),
        product_img  = safe(cl$product$image),
        
        original_price   = safe(cl$offer$originalPrice),
        new_price        = safe(cl$offer$newPrice),
        discount_dkk     = safe(cl$offer$discount),
        discount_percent = safe(cl$offer$percentDiscount),
        stock            = safe(cl$offer$stock),
        stock_unit       = safe(cl$offer$stockUnit),
        start_time       = safe(cl$offer$startTime),
        end_time         = safe(cl$offer$endTime),
        last_update      = safe(cl$offer$lastUpdate),
        
        stringsAsFactors = FALSE
      )
      
      # Øger tælleren så næste række placeres det rigtige sted
      i <- i + 1
    }
  }
  
  # Samler alle rækker i én data.frame
  bind_rows(rows)
}

####################################################
# Hent data for ALLE postnumre
####################################################

all_data_list <- list()   # liste der skal indeholde data for hvert postnummer
j <- 1                    # tæller index i listen

# Loop gennem alle postnumre
for (z in zips) {
  
  message("Henter data for: ", z)  # viser status i konsollen
  
  tmp <- get_foodwaste_zip(z)     # kalder funktionen for dette postnummer
  
  if (!is.null(tmp)) {            # hvis der er data, så gem det
    all_data_list[[j]] <- tmp
    j <- j + 1                    # flyt til næste plads i listen
  }
}

####################################################
# Saml alt til én samlet tabel
####################################################

foodwaste_data <- bind_rows(all_data_list)   # binder alle postnumre sammen

####################################################
# Undersøg data
####################################################

head(foodwaste_data)    # viser de første 6 rækker i konsollen

####################################################
# Gem resultat som CSV-fil i din projektmappe
####################################################

write.csv(foodwaste_data,
          "salling_foodwaste_4_postnumre.csv",
          row.names = FALSE)


