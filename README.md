# Ignition Mobile Tracker

A comprehensive iOS productivity tracking application built with SwiftUI and Core Data, designed to help users capture, organize, and gamify their personal growth journey through "Sparks" of inspiration, action, and achievement.

## Overview

Ignition Mobile Tracker transforms daily productivity into an engaging experience by combining task tracking with gaming elements. Users record "Sparks" (moments of insight, decision, energy, experimentation, or challenge), complete missions, collect cards, and progress through a leveling system.

## Core Features

### 1. **Spark System**
The heart of the app - a flexible system for capturing moments of action and insight.

- **Five Spark Categories:**
  - **Decision**: Recording important choices and their rationale
  - **Energy**: Capturing bursts of motivation or physical activity
  - **Idea**: Logging creative thoughts and innovations
  - **Experiment**: Tracking trials, tests, and learning experiences
  - **Challenge**: Documenting obstacles overcome

- **Intensity Levels**: Each spark can be rated from Low to Extreme, affecting point calculations
- **Rich Metadata**: Add notes, tags, and timestamps to each spark
- **Real-time Tracking**: Instant save to Core Data with immediate UI updates
- **Smart Search**: Filter by category, date range, intensity, or search text
- **Points System**: Earn points based on category and intensity (e.g., Energy spark at extreme intensity = more points than an Idea spark at low intensity)

### 2. **Mission System**
41 permanent, fixed missions that reset daily, weekly, or remain as lifetime achievements.

- **Mission Types:**
  - **Daily Missions (15)**: Reset every day at midnight
  - **Weekly Missions (15)**: Reset every Monday
  - **Achievement Missions (11)**: Lifetime goals related to card collection

- **Difficulty Tiers:**
  - **Easy**: Quick wins for building momentum (50-100 points)
  - **Medium**: Regular engagement (75-300 points)
  - **Hard**: Sustained effort (200-750 points)
  - **Expert**: Maximum commitment (500-5000 points)

- **Example Missions:**
  - **Daily**: "Morning Spark" - Create 1 spark before 12:00 PM (50 points)
  - **Weekly**: "Weekly Warrior" - Complete 20 sparks this week (500 points)
  - **Achievement**: "First Card" - Collect your first Spark Card (100 points)
  - **Achievement**: "Master of Decision" - Complete the Decision category (10 cards, 750 points)
  - **Achievement**: "Legendary Collector" - Collect all 3 Legendary cards (2000 points)
  - **Achievement**: "Completionist" - Collect all 50 Spark Cards (5000 points)

- **Card Collection Achievements:**
  - First Card (1 card): 100 points
  - Rare Collector (5 Rare cards): 300 points
  - Epic Hunter (1 Epic card): 500 points
  - Legendary Status (1 Legendary card): 1000 points
  - Master of [Category] (10 cards per category): 750 points each
  - Legendary Collector (3 Legendary cards): 2000 points
  - Completionist (all 50 cards): 5000 points

- **Features:**
  - Auto-reset mechanism using UserDefaults and Timer for daily/weekly missions
  - Progress tracking per mission with real-time updates
  - Visual completion feedback with animations
  - Multiple view modes: Grid, List, Board (Kanban-style)
  - Filter by type (All/Daily/Weekly/Achievement), difficulty, status, and timeframe
  - Sort by progress, points, or deadline
  - Unique SF Symbol icon per mission

### 3. **Spark Cards Collection**
A collectible card game system integrated into spark creation.

- **50 Unique Cards**:
  - 10 cards per spark category (Decision, Energy, Idea, Experiment, Challenge)
  - 4 rarity tiers: Common (25 cards), Rare (15 cards), Epic (7 cards), Legendary (3 cards)

- **Drop Mechanism**:
  - Automatic card drop on every spark completion
  - Drop rates aligned with rarity:
    - Common: 60% chance
    - Rare: 30% chance
    - Epic: 8% chance
    - Legendary: 2% chance
  - Guaranteed category match (Decision spark → Decision card)

- **Duplicate System**:
  - Duplicates convert to bonus points:
    - Common: +10 points
    - Rare: +25 points
    - Epic: +50 points
    - Legendary: +100 points
  - Duplicate count tracked per card

- **Card Reveal Animation**:
  - "Flame Burst" effect with particles
  - 3D flip animation from card back to front
  - Rarity-specific glow effects (gold for legendary, orange for epic, etc.)
  - Haptic and audio feedback on card reveal

- **Collection View**:
  - 3-column grid layout displaying all 50 cards
  - Simple, clean filtering by category and "Owned Only" toggle
  - Progress tracking (X/50 cards unlocked) with circular and linear progress indicators
  - Rarity breakdown showing completion per tier (e.g., 15/25 Common, 5/15 Rare)
  - Category progress chips showing cards collected per category
  - Detailed card view (sheet) showing:
    - Large card artwork
    - Rarity and category badges
    - Duplicate count (×N)
    - First obtained date
    - Duplicate value in points
  - Search functionality by card name or category

- **Home Integration**:
  - Dedicated "Spark Cards" section replaces "Recent Activity"
  - Displays 3 rarest cards owned (or empty placeholders if none)
  - Shows completion percentage with circular progress indicator
  - Shows total cards collected (X/50)
  - "View Collection" button to open full collection view

- **Card-Related Achievements** (integrated into Mission System):
  - Tracked as Achievement-type missions
  - Award bonus points upon completion
  - Progress automatically updated when cards are obtained
  - Examples:
    - "First Card": Collect your first Spark Card (100 points)
    - "Master of Decision": Complete the Decision category (750 points)
    - "Legendary Collector": Collect all 3 Legendary cards (2000 points)
    - "Completionist": Collect all 50 Spark Cards (5000 points)

### 4. **Library / Tables System**
Organize repeated activities or data tracking in custom tables.

- **Flexible Table Creation**:
  - Name, description, and category
  - Optional target goals
  - Custom fields for specialized tracking

- **Table Categories**: Personal, Work, Health, Finance, Learning, Hobbies, Projects

- **Entry Types**:
  - Session (time-based)
  - Measurement (numeric values)
  - Log (text-based)
  - Checklist (binary completion)
  - Rating (1-5 stars)

- **Features**:
  - Add entries with timestamps, tags, notes, duration, and custom data
  - Track total entries, hours logged, and streaks
  - Swipe to delete (List view) or context menu (Grid view)
  - View/Edit modes for each table
  - Statistics per table (total entries, active days, best streak)

### 5. **User Profile & Progression**
Unified profile tracking overall progress and achievements.

- **Core Stats**:
  - Total Sparks created
  - Total Points earned
  - Current Streak (consecutive days with sparks)
  - Longest Streak
  - Spark breakdown by category

- **Level System (10 Levels)**:
  - **Novice Igniter** (Level 1): 0-1,000 points
  - **Apprentice Igniter** (Level 2): 1,000-2,000 points
  - **Practitioner Igniter** (Level 3): 2,000-3,000 points
  - **Adept Igniter** (Level 4): 3,000-4,000 points
  - **Expert Igniter** (Level 5): 4,000-5,000 points
  - **Master Igniter** (Level 6): 5,000-6,000 points
  - **Grand Master** (Level 7): 6,000-7,000 points
  - **Legendary Igniter** (Level 8): 7,000-8,000 points
  - **Titan of Ignition** (Level 9): 8,000-9,000 points
  - **Mythical Flame** (Level 10): 9,000-10,000 points

- **Visual Representation**:
  - Level badge with custom color per tier (gray → gold → red → purple → cyan)
  - Progress bar showing advancement toward next level
  - Points required displayed prominently

### 6. **Statistics & Analytics**
Comprehensive data visualization and insights.

- **Overview**:
  - Total sparks, points, and streaks
  - Category distribution (pie chart or bar chart)
  - Time-based trends (daily, weekly, monthly views)

- **Advanced Filters**:
  - Date range selection (Today, Week, Month, Year, All Time, Custom)
  - Category-specific breakdowns
  - Intensity analysis

- **Export**: Future support for CSV export of sparks and tables

### 7. **Settings & Customization**
Personalize the app experience.

- **Notifications**:
  - Daily spark reminders (customizable time)
  - Weekly reports
  - Mission deadlines
  - Achievement notifications

- **Theme** (Fixed: Ignition Casino Dark Theme):
  - Deep black background (#1A1A1A)
  - Dark gray cards (#2A2A2A)
  - Ignition orange (#FF6B35) and fire red (#FF4444) accents
  - Gold highlights (#FFB800) for rewards
  - Gradient buttons and glow effects

- **Display**:
  - Grid vs. List view toggles (Missions, Library)
  - Sort options (Date, Points, Name, Progress)

## Technical Architecture

### Technologies
- **Language**: Swift 5
- **Framework**: SwiftUI (iOS 17.0+)
- **Persistence**: Core Data
- **Notifications**: UserNotifications framework
- **Animations**: SwiftUI animations, haptic feedback

### Core Data Entities
1. **CDSpark**: Stores individual sparks with category, intensity, notes, tags, and timestamps
2. **CDMission**: Manages mission state, progress, and metadata
3. **CDUserProfile**: Tracks user stats, streaks, and points
4. **CDTable**: Represents custom tracking tables
5. **CDEntry**: Individual table entries with flexible data structure
6. **CDSparkCard**: Card collection data (owned status, rarity, obtain date, duplicate count)

### Architecture Patterns
- **MVVM**: Separation of views and business logic
- **ObservableObject Managers**: Singletons for SparkManager, MissionManager, CardManager, LibraryManager, UserProfileManager
- **NotificationCenter**: Inter-manager communication for events (spark added, mission completed, card obtained)
- **PersistenceController**: Centralized Core Data operations (CRUD)
- **Core Data Extensions**: Convert between Core Data entities and SwiftUI models

### Key Managers
- **SparkManager**: CRUD for sparks, triggers card drops
- **MissionManager**: Mission initialization, progress tracking, auto-reset logic
- **CardManager**: Card collection, drop logic, rarity determination, achievement checks
- **LibraryManager**: Table and entry management
- **UserProfileManager**: Profile updates, point/streak calculations
- **AudioHapticsManager**: Sound effects and haptic feedback for user interactions
- **IgnitionNotificationManager**: Schedule and manage local notifications
- **PushNotificationService**: Handle remote notifications (future)

## User Interface

### Main Navigation (Bottom Tab Bar)
1. **Home**: Dashboard with quick stats, Ignition Core, and Spark Cards section
2. **Tracker**: All sparks with advanced search and filtering
3. **Library**: Custom tables for repeated tracking
4. **Missions**: All missions with filters and view modes
5. **Stats**: Analytics and charts

### Custom Header (All Views)
- App logo (or "IGNITION" text gradient)
- Pill-shaped buttons: "STATS" and "SETTINGS"
- Consistent across all tabs for unified navigation

### Home View Highlights
- **Ignition Core Card**: Level, points, fuel gauge (visual metaphor for progress)
- **Quick Actions**: Navigate to Tracker, Library, Missions, Stats (with background images)
- **Spark Cards Section**: 3 rarest cards, completion stats, "View Collection" button

### Theming & Aesthetics
- Inspired by modern dark-themed casino UIs
- Heavy use of fire/flame imagery
- Gradient buttons with glow effects
- Deep shadows and subtle borders on cards
- Bold, impactful typography (rounded system font, heavy weights)
- Iconography with rarity-specific colors (gray, blue, purple, gold)

## Data Flow

### Adding a Spark
1. User taps "Add Spark" in Tracker or Quick Action
2. Fills form (title, category, intensity, notes, tags)
3. On save:
   - Spark saved to Core Data via PersistenceController
   - SparkManager updates in-memory array
   - CardManager triggers card drop based on category
   - If card obtained, CardRevealView displays with animation
   - If duplicate, bonus points awarded and notification sent
   - UserProfileManager updates points, streak, category counters
   - MissionManager checks for progress updates (e.g., "Create 5 sparks today")
4. UI refreshes automatically via @Published properties

### Mission Reset
1. App initializes 30 fixed missions on first launch (via `initializeFixedMissions()`)
2. Timer runs every minute checking current time
3. At midnight:
   - Daily missions reset progress to 0, status to available
   - `lastDailyReset` updated in UserDefaults
4. On Monday:
   - Weekly missions reset progress to 0, status to available
   - `lastWeeklyReset` updated in UserDefaults
5. User progress persists until next reset cycle

### Card Drop Logic
1. Spark created and saved
2. `CardManager.triggerCardDrop(for: category)` called
3. Rarity determined by weighted random roll (cumulative probability)
4. Eligible cards filtered by category and rarity
5. Random card selected from eligible pool
6. `PersistenceController.obtainSparkCard(cardId)` updates Core Data:
   - If new: `isOwned = true`, `obtainedAt = Date()`, `ownedCount = 1`
   - If duplicate: `ownedCount += 1`, return bonus points
7. CardRevealView presented with full-screen animation
8. User dismisses, returns to app flow

## Installation & Setup

### Prerequisites
- macOS with Xcode 16.0+ (for iOS 17.0+ deployment)
- iOS Simulator or physical device running iOS 17.0+

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/danbeta2/ignition-mobile-tracker.git
   cd ignition-mobile-tracker
   ```

2. Open the Xcode project:
   ```bash
   open "Ignition Mobile Tracker.xcodeproj"
   ```

3. Select a simulator or connected device as the build target.

4. Build and run (⌘R).

5. On first launch:
   - App initializes user profile
   - Creates 30 fixed missions
   - Initializes 50 spark cards in Core Data
   - Requests notification permissions

### Adding Card Artwork (Optional)
- Card artwork files are located in `Assets.xcassets/Cards/`
- Naming convention: `spark-card-[category]-[name]-[rarity]`
- Example: `spark-card-energy-phoenix-epic`
- Accepted formats: JPEG (recommended), PNG
- Resolution: @1x, @2x, @3x (e.g., 250x350, 500x700, 750x1050)

## Future Enhancements

- **Social Features**: Share achievements, compare collections with friends
- **Cloud Sync**: iCloud integration for multi-device persistence
- **Widget Support**: Home screen widgets showing today's missions or card collection progress
- **Export/Import**: Backup user data, export CSV reports
- **Advanced Analytics**: Machine learning insights, predictive streak alerts
- **Custom Missions**: User-created missions beyond the fixed set
- **Seasonal Events**: Limited-time cards or missions
- **Trading/Gifting**: Exchange duplicate cards (if multiplayer is added)

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Acknowledgments

- Inspired by productivity tracking apps like Habitica, Streaks, and Things
- UI design influenced by modern casino themes (while avoiding actual gambling mechanics)
- Built with SwiftUI and Core Data best practices

---

**Disclaimer**: This app is for personal productivity tracking only. No real-world gambling, betting, or financial transactions are involved. The "casino" theme is purely aesthetic.
