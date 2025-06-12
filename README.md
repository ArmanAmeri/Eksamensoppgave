# 🎮 Multiplayer-komponent for eksamensprosjekt (Godot 4)

## 🧾 Innledning
Dette prosjektet er en enkel multiplayer-komponent bygd i Godot 4.  
Spillere kan velge å være **Host** eller **Client**, og kommunikasjon skjer via RPC.  
Host-en lagrer spillernes `Unique ID` og `Username` i en lokal SQLite-database.

---

## 🚀 Komme i gang

### Host
1. Åpne prosjektet i **Godot 4**.
2. Skriv inn ønsket brukernavn i **Username**-feltet.
3. Klikk på **Host**-knappen.
   - Starter server-host og åpner nettverkstjener.
   - SQLite-databasen opprettes hvis den ikke eksisterer.

### Client
1. Åpne prosjektet i **Godot 4**.
2. Skriv inn ønsket brukernavn i **Username**-feltet.
3. Klikk på **Join**-knappen.
   - Kobler til host.
   - Sender RPC-kall for registrering.

---

## ⚙️ Teknisk forklaring

### 1. RPC-kommunikasjon
- Bruker Godot 4 sin innebygde RPC-funksjonalitet.
- **Host**-instansen åpner en nettverkstjener.
- **Client** kobler til via socket og sender/mottar RPC-kall.

### 2. Host-logikk
- Host-er kun den som klikker **Host** først.
- Ingen ekstra koordinering kreves — kun direkte RPC-basert oppsett.

### 3. SQLite-database
- Host-en åpner/initialiserer en lokal SQLite-fil.
- Tabellstruktur:
  - `id`: auto-inkrement (eller UUID)
  - `username`: tekst
- Registrering ved tilkobling:
  1. Klient sender `rpc("registrer_spiller", username)`
  2. Host skriver til `spiller`-tabellen.
  3. (Valgfritt) Host bekrefter registrering via RPC tilbake til klienten.

---

## 📦 Avhengigheter
- Godot Engine **v4.x**
- `SQLite`-modul for Godot
