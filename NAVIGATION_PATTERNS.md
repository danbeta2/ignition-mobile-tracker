# Navigation Patterns - Ignition Mobile Tracker

**Last Updated**: October 5, 2025  
**Version**: 1.0.0

---

## 🎯 Navigation Architecture

This document defines the **standardized navigation patterns** used throughout the app to ensure consistency and maintainability.

---

## 📱 Primary Navigation: TabBar

The app uses a **fixed 4-tab navigation** at the bottom:

| Tab | Route | Purpose |
|-----|-------|---------|
| 🏠 Home | `.home` | Dashboard, quick actions, spark cards |
| ⚡ Tracker | `.tracker` | Spark creation and management |
| 📚 Library | `.library` | Tables and custom data tracking |
| 🎯 Missions | `.missions` | Daily/weekly challenges and achievements |

**Implementation**: `TabRouter.swift` → `TabRoute` enum

---

## 🎭 Secondary Navigation: Sheets (Modal)

The following views are **ALWAYS presented as sheets** (not navigation pushes):

### ✅ Stats View
- **Presentation**: `.sheet(isPresented: $showingStats)`
- **Trigger Points**:
  - Custom header "STATS" button (all tabs)
  - Home "Stats" quick action card
  - Any analytics-related action
- **Rationale**: Stats is a temporary overlay for quick insights, not a destination

### ✅ Settings View
- **Presentation**: `.sheet(isPresented: $showingSettings)`
- **Trigger Points**:
  - Custom header "SETTINGS" button (all tabs)
- **Rationale**: Settings is a modal experience, should not interrupt navigation flow

### ✅ Card Collection
- **Presentation**: `.sheet(isPresented: $showingCardCollection)`
- **Trigger Points**:
  - Home "View Collection" button
- **Rationale**: Collection is a focused experience separate from main flow

---

## 🚫 Anti-Patterns (DO NOT USE)

### ❌ Mixing Navigation Styles
```swift
// ❌ BAD: Using TabRouter for modal views
tabRouter.navigate(to: .stats)  // NEVER DO THIS

// ✅ GOOD: Use sheet presentation
showingStats = true
```

### ❌ Adding Stats/Settings to SecondaryRoute
```swift
// ❌ BAD: Don't add these to navigation routes
enum SecondaryRoute {
    case stats  // REMOVED - use sheet
    case settings  // REMOVED - use sheet
}

// ✅ GOOD: Use @State binding + sheet
@State private var showingStats = false
.sheet(isPresented: $showingStats) {
    StatsViewExpanded()
}
```

---

## 📐 Secondary Routes (NavigationPath)

These routes are for **drill-down navigation** within a tab context:

| Route | Use Case | Where Used |
|-------|----------|------------|
| `sparkDetail` | View spark details | Tracker tab |
| `missionDetail` | View mission info | Missions tab |
| `tableDetail` | View table entries | Library tab |
| `entryDetail` | Edit table entry | Library tab |
| `achievements` | View achievements | Future feature |
| `collectibles` | View collectibles | Future feature |

**Implementation**: `TabRouter.swift` → `SecondaryRoute` enum

---

## 🎬 Quick Actions Pattern

Quick actions in Home use **direct tab switching**:

```swift
// Example: Add Spark button
func quickAddSpark() {
    selectedTab = .tracker
    shouldShowAddSpark = true
}
```

This ensures the user lands in the correct tab context.

---

## ✅ Standardization Benefits

1. **Predictable UX**: Stats always appears the same way
2. **Easy Testing**: Consistent presentation makes automation easier
3. **Maintainability**: Single source of truth for navigation logic
4. **No Conflicts**: Sheet and navigation don't interfere

---

## 🔍 Code Locations

- **TabRouter**: `/Core/Navigation/TabRouter.swift`
- **MainTabView**: `/Core/Views/MainTabView.swift`
- **CustomAppHeader**: `/Core/Views/CustomAppHeader.swift` (Stats/Settings buttons)
- **HomeView**: `/Features/Home/HomeView.swift` (Quick actions)

---

## 📝 Adding New Views

### If it's a Modal Experience (temporary overlay):
```swift
// 1. Add @State variable
@State private var showingMyView = false

// 2. Add trigger action
Button("Open My View") {
    showingMyView = true
}

// 3. Add sheet presentation
.sheet(isPresented: $showingMyView) {
    MyView()
}
```

### If it's a Drill-Down (detail view):
```swift
// 1. Add case to SecondaryRoute enum
case myDetail = "my_detail"

// 2. Use navigation
tabRouter.navigate(to: .myDetail)

// 3. Handle in NavigationStack
.navigationDestination(for: SecondaryRoute.self) { route in
    if route == .myDetail {
        MyDetailView()
    }
}
```

---

## 🎯 Summary

| View Type | Method | Example |
|-----------|--------|---------|
| Main Tabs | TabRoute | Home, Tracker, Library, Missions |
| Modal Overlays | Sheet | Stats, Settings, Card Collection |
| Detail Views | NavigationPath | Spark Detail, Mission Detail |
| Quick Actions | Tab Switch | Quick Add Spark |

---

**Consistency is key!** Follow these patterns to maintain a cohesive user experience.

