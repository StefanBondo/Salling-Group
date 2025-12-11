library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(RMariaDB)
library(stringr)

con <- dbConnect(
  RMariaDB::MariaDB(),
  dbname   = "SallingGroupFoodWaste",
  host     = "localhost",
  user     = "root",
  password = "bondo123",
  port     = 3306
)

old_clearances <- dbGetQuery(con,
                             "SELECT * FROM store_clearances 
   WHERE DATE(offer_startTime) = CURDATE() - INTERVAL 1 DAY"
)

new_clearances <- dbGetQuery(con,
                             "SELECT * FROM store_clearances 
   WHERE DATE(offer_startTime) = CURDATE()"
)

forsvundet <- anti_join(old_clearances, new_clearances,
                        by = c("id"))
)
