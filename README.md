# Ignition Mobile Tracker

**iOS App - Swift/SwiftUI - Offline Only - iPhone**

## 🎯 Missione & Metodo di Lavoro

Ignition Mobile Tracker è un tracker gamificato che trasforma i progressi dell'utente in energia visiva attraverso scintille, "Fuel Gauge" e Overload Mode.

### Design & UI
- **Stile**: Dark moderno con accenti arancio/bianco/grigi
- **Tipografia**: Sans leggibile e moderna
- **Componenti**: Card minimal con immagini forti
- **Navigazione**: Tab bar in basso con 4 sezioni principali

### Principi Tecnici
- **Offline Only**: Nessun network call, nessun link esterno
- **Trunk-First**: Prima architettura, dati, manager, tema; poi singole schermate
- **Zero Mock/Placeholder**: Ogni feature completa, profonda e rigiocabile
- **Stabilità**: Riferimenti coerenti in tutto il progetto
- **Conformità Apple**: HIG, niente gambling, accessibilità base

## 🏗️ Architettura (TRONCO)

### Core Systems
- **Theming**: Sistema colori/palette coerente (nero, arancio ignition, bianco, grigio scuro)
- **Routing**: TabView con 4 tab principali + navigazione secondaria
- **Data Layer**: Core Data per persistenza offline
- **Gamification**: Spark Points, Fuel Gauge, Overload Mode

### Managers
- **SparkManager**: Gestione CRUD per log di spark (5 categorie)
- **MissionManager**: Pool locale missioni giornaliere/settimanali
- **StatsManager**: Streak, trend, categorie, analytics
- **AchievementManager**: Badge e collezioni
- **AudioHapticsManager**: Suoni e feedback tattile
- **ThemeManager**: Colori e asset condivisi

### Asset Pipeline
- Convenzioni naming strutturate
- Cartelle organizzate (backgrounds, icons, sfx, sprites/glow)
- Enum centralizzati per riferimenti

## 📱 Schermate Principali

### 1. Home (Ignition Lobby) - Tab 1
**Hub energetico centrale**
- Ignition Core (nucleo visivo)
- Fuel Gauge con riempimento real-time
- Accessi rapidi (Add Spark, Missione del Giorno)
- Banner grafico in stile moderno
- Overload Mode con effetti particelle

### 2. Tracker (Add/Review Spark) - Tab 2
**Registrazione spark in 5 categorie**
- **Categorie**: Decisione, Energia, Idea, Esperimento, Sfida
- Campi: titolo, note, tag, intensità, tempo
- Animazioni e suoni all'invio
- Storico con filtri avanzati

### 3. Missions - Tab 3
**Sfide giornaliere/settimanali offline**
- Pool ampia (60-100 missioni distinte)
- Card con immagine, categoria, reward
- Sistema progressione e completamento
- Ricompense in Spark Points/collezionabili

### 4. Stats - Tab 4
**Visual analytics energetici**
- Timeline luminosa degli spark
- Streak e trend energia
- Categorie più usate
- Insight personalizzati (orari picco, record)

### Flussi Secondari
- **Achievements & Collectibles**: Bacheca badge e oggetti simbolici
- **Profile**: Identità utente e progressi globali
- **Settings**: Controlli app, accessibilità, preferenze

## 🎮 Gameloop & Progressione

### Sistema Energetico
- **Spark Points**: Valuta base del gioco
- **Fuel Gauge**: Riempimento visivo dei progressi
- **Overload Mode**: Modalità speciale a soglia raggiunta

### Progressione
- Missioni alimentano progressi e sblocchi
- Achievement per obiettivi lungo periodo
- Collezioni estetiche e personalizzazione
- Sistema completamente offline e rigiocabile

## 🔧 Requisiti Tecnici

### Performance
- Animazioni fluide su device entry-level
- Calcoli stats off-thread
- Sistema caching efficiente

### Accessibilità
- Font scaling
- Contrasti ottimizzati
- Color-blind safe per grafici

### Audio/Haptics
- Manager centralizzato
- Rispetto toggle utente
- Feedback coerente

### Quality Assurance
- Crash-safety su ogni feature
- Navigazione back coerente
- Nessun riferimento rotto
- Test manuali sistematici

## 📋 Workflow di Sviluppo

### Per Ogni Step:
1. **Pre-implementazione**: Proposta asset necessari (nomi, cartelle, dimensioni, formati)
2. **Attesa conferma**: "NEXT" per procedere
3. **Implementazione**: Codice completo e verticale
4. **Build & Test**: Checklist locale (accessibilità, performance, coerenza)
5. **Descrizione**: Cosa fatto + test manuali da eseguire
6. **Attesa conferma**: "NEXT" per step successivo

### Asset Requirements
- Naming convention strutturata
- Cartelle organizzate per tipologia
- Enum centralizzati per riferimenti
- Nessun hardcoding di nomi asset

## 🍎 Conformità Apple

- **Offline Only**: Nessuna connessione richiesta
- **No Gambling**: Nessun contenuto d'azzardo
- **No External Links**: App completamente self-contained
- **Age Rating**: Appropriato e onesto
- **HIG Compliance**: Rispetto Human Interface Guidelines
- **Accessibility**: Supporto base per utenti con disabilità

---

**Status**: In sviluppo - Fase implementazione Core Data e sistema persistenza
