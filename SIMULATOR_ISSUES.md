# Known Simulator Issues

## Haptic Feedback Errors

When running the app in the iOS Simulator, you may see repeated errors like:

```
CHHapticPattern.mm:487   +[CHHapticPattern patternForKey:error:]: Failed to read pattern library data
Error Domain=NSCocoaErrorDomain Code=260 "The file "hapticpatternlibrary.plist" couldn't be opened..."
```

### Cause
This is a **known iOS Simulator bug** and not an issue with the app itself. The simulator lacks the haptic engine hardware and some system files required for haptic feedback.

### Impact
- **No impact on real devices**: The app works perfectly on physical iPhones and iPads
- **No functional impact**: The app continues to work normally in the simulator; haptic feedback is simply not provided

### Solution
These errors can be safely ignored when testing in the simulator. To verify haptic functionality:
1. Test on a real iOS device
2. Or: Disable haptic feedback in Settings during simulator testing

## SF Symbol Cache Issues

If you see errors about missing SF Symbols after updating the code:

```
No symbol named 'chart.area.fill' found in system symbol set
No symbol named 'crystal.ball' found in system symbol set
```

### Cause
Xcode's Derived Data cache may still contain references to old symbol names.

### Solution
Run a clean build:
```bash
# Delete Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData/Ignition_Mobile_Tracker-*

# Clean and rebuild
xcodebuild -project "Ignition Mobile Tracker.xcodeproj" -scheme "Ignition Mobile Tracker" clean build
```

Or from Xcode:
1. Product → Clean Build Folder (Cmd + Shift + K)
2. Delete Derived Data (Xcode → Settings → Locations → Derived Data → Delete)
3. Rebuild (Cmd + B)

## Reference
All SF Symbols used in the app are now verified to exist in iOS 17+:
- ✅ `chart.xyaxis.line` (replaced `chart.area.fill`)
- ✅ `sparkles` (replaced `crystal.ball`)
- ✅ `scope` (replaced `target`)

