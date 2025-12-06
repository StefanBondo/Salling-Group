✅ README.md til dit repo
# Salling Group – Anti Food Waste Datapipeline (AWS EC2)

Dette projekt indsamler data fra Salling Groups *Anti Food Waste API* og gemmer dem i en MySQL-database på en AWS EC2 Ubuntu-instans. Projektet består af et automatiseret R-script, database-struktur samt logging, som dokumenterer at systemet kører uden brugerinteraktion.

---

## 1. Arkitektur (Overblik)

- **AWS EC2 (Ubuntu 22.04)**  
  Kører alle scripts, MySQL og cron.

- **MySQL Database (MariaDB)**  
  Indeholder to tabeller:
  - `main_df` (stamdata om butikker)
  - `store_clearances` (variable data om nedsatte varer)

- **R + Rscript**  
  Henter API-data, renser data og skriver til databasen.

- **Cron job**  
  Kører scriptet automatisk hver time.

- **Logging**  
  Alt output fra cron gemmes i:  
  `/var/log/foodwaste/update.log`

---

## 2. Filstruktur (i dette repo)



/Salling-Group
│
├── update_foodwaste.R # R-script der henter og gemmer data
├── run_update.sh # Shell-script kaldt af cron
├── update.log (valgfrit) # Lokal log (cron bruger ikke denne)
└── README.md # Dokumentation (denne fil)


---

## 3. R-script (update_foodwaste.R)

R-scriptet gør følgende:

1. Kalder API’et for et valgt postnummer  
2. Rydder og strukturerer data  
3. Konverterer tidspunkter  
4. Danner to datasæt:
   - `main_df` (butiksinfo)
   - `store_clearances` (varer og tilbud)
5. Renamer kolonner (`.` → `_`)
6. Skriver begge datasæt til MySQL  
7. Logger succes/fejl til terminal (som cron fanger)

---

## 4. run_update.sh

Dette script køres af cron hvert 60. minut:

```bash
#!/bin/bash

cd /home/ubuntu/git/Salling-Group
git pull

/usr/bin/Rscript --vanilla /home/ubuntu/git/Salling-Group/update_foodwaste.R

5. Cron opsætning

Cron-linjen for EC2 Ubuntu-brugeren:

0 * * * * bash /home/ubuntu/git/Salling-Group/run_update.sh >> /var/log/foodwaste/update.log 2>&1


Dette sikrer:

Automatisk kørsel én gang i timen

Logging til /var/log/foodwaste/update.log

At scriptet kører selv hvis serveren genstartes

6. Database Struktur
main_df (stamdata)
kolonne	type
store_id	VARCHAR
brand	VARCHAR
name	VARCHAR
city	VARCHAR
street	VARCHAR
zip	INT
store_clearances (variable data)
kolonne	type
id	INT AUTO_INCREMENT
store_id	VARCHAR
offer_*	datetime/double/int
product_description	TEXT
product_ean	VARCHAR(50)
product_image	TEXT
product_categories_en	MEDIUMTEXT
product_categories_da	MEDIUMTEXT

Begge kategori-felter blev opgraderet til MEDIUMTEXT, da API’et begyndte at sende meget store tekstfelter.

7. Eksempel på SQL INSERT (bruges til dokumentation)
INSERT INTO store_clearances (
  store_id, offer_discount, offer_endTime, offer_lastUpdate,
  offer_newPrice, offer_originalPrice, offer_percentDiscount,
  offer_startTime, offer_stock, product_description,
  product_ean, product_image, product_categories_en, product_categories_da
) VALUES (
  '1234', 20.0, '2025-12-02 15:00:00', '2025-12-02 14:00:00',
  10.00, 12.50, 20.0, '2025-12-02 10:00:00', 5, 'Testprodukt',
  '1234567890123', 'https://example.com/img.jpg',
  'Dairy > Milk > Organic', 'Mejeri > Mælk > Økologisk'
);

8. Dokumentation (bruges i opgaven)

I rapporten skal inkluderes:

Screenshot af AWS EC2 instance

Inbound rules (port 22 + port 3306 for MySQL hvis nødvendigt)

Screenshot af crontab -l

Screenshot af MySQL SELECT hvor timestamps viser flere kørsler

Logfil med mindst to succesfulde kørsler

GitHub repo med R-script, sh-script og README

9. Kontakt

Projektet er udviklet til undervisningsbrug i forbindelse med dataindsamling via cloud-baserede løsninger.


---
