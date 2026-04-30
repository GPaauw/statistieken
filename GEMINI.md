# Project Analyse: Statistieken (Korfbal Tracking App)

Dit bestand wordt door Gemini Code Assist bijgehouden om de voortgang en structuur van het project te monitoren.

## 1. Projectoverzicht
**Naam:** Statistieken
**Type:** Flutter Web Applicatie
**Doel:** Het bijhouden van wedstrijdstatistieken voor korfbalwedstrijden (gebaseerd op termen als "Strafworp" en "KV Flamingo's").

## 2. Kernfunctionaliteiten
- **Wedstrijdregistratie:**
  - Bijhouden van score via `GoalSide` (home/away).
  - Registreren van acties per speler: Doelpunt, Rebound, Assist, Onderschepping.
  - Gedetailleerde schot-types via `GoalType`: *Klein kansje (2m), Mid range (5m), Afstander (7m), Omdraaibal, Doorloopbal, Vrije bal, Strafworp*.
  - Live spelerstatistieken op het dashboard onder de tijdlijn.
- **Spelerbeheer:** Toevoegen en beheren van spelers (bijv. "Speler 1" t/m "Speler 8").
- **Rapportage:** Exporteren van een "Wedstrijdverslag" naar PDF-formaat met datumstempel.
- **Databeheer:** Gebruik van `shared_preferences` voor persistentie en `ThemeService` voor UI-instellingen.

## 3. Technische Stack
- **Framework:** Flutter SDK ^3.10.7 (Web focused)
- **Exporteren:** `pdf` en `printing` pakketten voor cross-platform PDF generatie.
- **Internationalisatie:** `intl` voor lokalisatie en datumformaten.
- **Styling:** Material Design met ondersteuning voor Cupertino iconen.

## 4. Project Structuur & Status
- De web-build is geconfigureerd om te draaien vanuit de `docs/` map (geschikt voor GitHub Pages).
- Bevat lints voor codekwaliteit via `flutter_lints`.
- **Modellen:** `Goal` model aanwezig met tijdstempel (`secondStamp`) en speler-koppeling.
- **Thema:** Gecentraliseerd beheer via `ThemeService` (Singleton) en `ValueListenableBuilder`.
- **Status:** `lib/` map geanalyseerd. Broncode is modulair opgezet met scheiding tussen pagina's, modellen en services.

## 5. Onderhoud Log (Gemini)
- **2026-04-30:** Initiële project-audit uitgevoerd op basis van bouwbestanden en configuratie. `GEMINI.md` aangemaakt.
- **2026-04-30:** Bronbestanden (`lib/`) geanalyseerd. Logica voor `GoalType` en thema-beheer vastgelegd in documentatie.
- **2026-04-30:** Implementatie van live spelerskaarten op het dashboard onder de tijdlijn, gesorteerd op spelersnummer.