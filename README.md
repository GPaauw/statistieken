# Statistieken

Een Flutter Web applicatie specifiek ontworpen voor het bijhouden van gedetailleerde wedstrijdstatistieken tijdens korfbalwedstrijden (geoptimaliseerd voor verenigingen zoals KV Flamingo's).

## 🚀 Functionaliteiten

De app stelt coaches en analisten in staat om real-time de prestaties van een team te monitoren:

- **Wedstrijdregistratie:**
  - Bijhouden van de score voor zowel het thuis- als uitteam.
  - Registreren van specifieke acties per speler: **Doelpunten**, **Rebounds**, **Assists** en **Onderscheppingen**.
  - Gedetailleerde categorisering van schoten via `GoalType` (o.a. Klein kansje, Afstander, Strafworp, Doorloopbal).
  - **Real-time spelerstatistieken:** Bekijk direct de prestaties van individuele spelers op het dashboard, inclusief schot-accuraatheid en rebound-verhoudingen.
- **Spelerbeheer:** 
  - Beheer een team van maximaal 8 spelers.
  - Eenvoudig spelers toevoegen of namen aanpassen.
- **Rapportage:** 
  - Genereer direct een professioneel PDF-wedstrijdverslag.
  - Bevat tijdstempels en een chronologisch overzicht van alle doelpunten.
- **Gebruiksgemak:**
  - Donker en licht thema ondersteuning via de UI instellingen.
  - Gegevens blijven bewaard in de browser via `shared_preferences`.

## 📖 Hoe gebruik je de app?

### 1. Spelers instellen
Ga naar het spelersbeheer gedeelte om de namen van je teamleden in te voeren. Standaard staan er 8 spelers klaar die je kunt personaliseren.

### 2. Tijdens de wedstrijd
Wanneer er een actie plaatsvindt op het veld, klik je op de bijbehorende knop bij de speler:
- **Doelpunt:** Kies het type schot (bijv. "Afstander 7m") en geef aan of het voor het thuisteam of uitteam was.
- **Rebound/Assist/Onderschepping:** Klik op de specifieke actieknop om de statistiek direct aan de speler toe te wijzen.

De app houdt automatisch de `secondStamp` (tijdstip in de wedstrijd) bij voor elk doelpunt.

### 3. Exporteren
Aan het einde van de wedstrijd kun je op de export-knop drukken. Er wordt een PDF gegenereerd met de naam `wedstrijdverslag_DD-MM-YYYY.pdf` waarin alle statistieken overzichtelijk zijn samengevat.

## 🛠 Technische Details

- **Framework:** Flutter Web
- **PDF Generatie:** Gebruik van de `pdf` en `printing` packages.
- **Persistentie:** Instellingen en namen worden lokaal opgeslagen.
- **Build:** De web-build is geconfigureerd om te draaien vanuit de `docs/` map voor eenvoudige hosting via GitHub Pages.

---
*Ontwikkeld voor korfbalstatistieken.*
