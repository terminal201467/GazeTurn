# GazeTurn v1 Implementation Plan (Updated for Multi-Instrument Support)

## Phase 1: Core Gesture Detection Infrastructure

### 1.1 Implement HeadPoseDetector
**Files**: New `GazeTurn/FeatManager/GazeCore/HeadPoseDetector.swift`

**Tasks**:
- [ ] Create HeadPoseDetector class
- [ ] Extract yaw angle from VNFaceObservation
- [ ] Implement head shake detection logic
  - Track yaw changes over time
  - Detect left shake (yaw < -threshold)
  - Detect right shake (yaw > threshold)
- [ ] Add configurable thresholds (angle, duration, cooldown)
- [ ] Implement gesture direction enum (left, right, none)
- [ ] Add temporal filtering to avoid false positives
- [ ] Test with different head movement speeds

**Dependencies**: None (uses existing VisionProcessor)
**Estimated Complexity**: Medium
**Key Technical Points**:
```swift
enum HeadShakeDirection {
    case left, right, none
}

class HeadPoseDetector {
    func detectShake(from face: VNFaceObservation) -> HeadShakeDirection
}
```

### 1.2 Create Instrument Mode System
**Files**:
- New `GazeTurn/Model/InstrumentType.swift`
- New `GazeTurn/FeatManager/GestureControl/InstrumentMode.swift`

**Tasks**:
- [ ] Define InstrumentType enum (strings, woodwind, keyboard, etc.)
- [ ] Create InstrumentMode protocol/struct
- [ ] Define gesture configurations for each instrument:
  - Blink-only mode (strings)
  - Hybrid mode (woodwind/brass)
  - Head shake mode (keyboard, vocal)
  - Filtered shake mode (plucked strings)
- [ ] Implement mode-specific thresholds
- [ ] Add mode validation logic
- [ ] Create UserDefaults persistence for selected instrument

**Dependencies**: None
**Estimated Complexity**: Medium
**Key Technical Points**:
```swift
enum InstrumentType: String, CaseIterable {
    case stringInstruments, woodwindBrass, keyboard
    case pluckedStrings, percussion, vocal, custom
}

struct InstrumentMode {
    let type: InstrumentType
    let enableBlink: Bool
    let enableHeadShake: Bool
    let requireConfirmation: Bool  // hybrid mode
    let shakeAngleThreshold: Double
    // ...
}
```

### 1.3 Create GestureCoordinator
**Files**: New `GazeTurn/FeatManager/GestureControl/GestureCoordinator.swift`

**Tasks**:
- [ ] Create GestureCoordinator class
- [ ] Accept input from both BlinkRecognizer and HeadPoseDetector
- [ ] Implement instrument mode logic
- [ ] Route gestures based on active mode:
  - Blink-only: only process blinks
  - Head-only: only process head shakes
  - Hybrid: require both gestures in sequence
- [ ] Add gesture cooldown to prevent double-triggers
- [ ] Define delegate/callback for page turn events
- [ ] Emit direction (next/previous) with page turn

**Dependencies**: 1.1, 1.2
**Estimated Complexity**: Medium-High
**Key Technical Points**:
```swift
protocol GestureCoordinatorDelegate: AnyObject {
    func didDetectPageTurn(direction: PageDirection)
}

class GestureCoordinator {
    var currentMode: InstrumentMode
    weak var delegate: GestureCoordinatorDelegate?

    func processBlinkResult(_ detected: Bool)
    func processHeadShake(_ direction: HeadShakeDirection)
}
```

### 1.4 Update VisionProcessor
**Files**: `GazeTurn/FeatManager/GazeCore/VisionProcessor.swift`

**Tasks**:
- [ ] Enhance VisionProcessor to extract head pose data
- [ ] Return both face landmarks AND head pose (yaw/pitch/roll)
- [ ] Add error handling for missing pose data
- [ ] Optimize to minimize processing overhead

**Dependencies**: None
**Estimated Complexity**: Low

---

## Phase 2: User Interface Implementation

### 2.1 Create InstrumentSelectionView
**Files**: New `GazeTurn/View/InstrumentSelectionView.swift`

**Tasks**:
- [ ] Design instrument picker UI with icons
- [ ] Display instrument categories with descriptions
- [ ] Show recommended control mode for each instrument
- [ ] Implement selection persistence
- [ ] Add "Learn More" info for each mode
- [ ] Create smooth transition to main app
- [ ] Add skip option (use default keyboard mode)

**Dependencies**: 1.2 (InstrumentType)
**Estimated Complexity**: Medium

### 2.2 Implement FileListView
**Files**: `GazeTurn/View/FileListView.swift`

**Tasks**:
- [ ] Integrate UIDocumentPickerViewController
- [ ] Support PDF and image file types (pdf, png, jpg, jpeg)
- [ ] Display imported files in a list
- [ ] Add file thumbnails (optional)
- [ ] Implement file selection handler
- [ ] Navigate to BrowseView on selection
- [ ] Add file delete/manage options
- [ ] Persist file references to UserDefaults or local storage

**Dependencies**: None
**Estimated Complexity**: Medium

### 2.3 Implement BrowseView
**Files**: `GazeTurn/View/BrowseView.swift`

**Tasks**:
- [ ] Create SwiftUI wrapper for PDFView (UIViewRepresentable)
- [ ] Create SwiftUI wrapper for UIImageView
- [ ] Initialize PageTurnManager with selected files
- [ ] Display current page content
- [ ] Show page number indicator (e.g., "3 / 12")
- [ ] Add manual page turn buttons (for testing/fallback)
- [ ] Handle file loading errors gracefully
- [ ] Add visual feedback for gesture detection
  - Blink indicator
  - Head shake direction indicator

**Dependencies**: 2.2, 3.1 (for gesture feedback)
**Estimated Complexity**: Medium-High

### 2.4 Create SettingsView
**Files**: New `GazeTurn/View/SettingsView.swift`

**Tasks**:
- [ ] Create settings UI layout
- [ ] Add instrument mode selector
- [ ] Add sensitivity sliders:
  - Blink threshold
  - Head shake angle
  - Gesture duration
- [ ] Show real-time preview of current settings
- [ ] Add calibration wizard button
- [ ] Implement reset to defaults
- [ ] Save settings to UserDefaults

**Dependencies**: 1.2, 3.2 (for calibration)
**Estimated Complexity**: Medium

### 2.5 Update ContentView
**Files**: `GazeTurn/View/ContentView.swift`

**Tasks**:
- [ ] Replace placeholder with NavigationStack
- [ ] Show InstrumentSelectionView on first launch
- [ ] Set FileListView as main view
- [ ] Add navigation to BrowseView
- [ ] Add settings button in navigation bar
- [ ] Implement app branding/title
- [ ] Handle deep linking to specific views

**Dependencies**: 2.1, 2.2, 2.3, 2.4
**Estimated Complexity**: Low

---

## Phase 3: Integration & Coordination

### 3.1 Create Main ViewModel/Coordinator
**Files**: New `GazeTurn/ViewModel/GazeTurnViewModel.swift`

**Tasks**:
- [ ] Create ObservableObject ViewModel
- [ ] Initialize and manage:
  - CameraManager
  - VisionProcessor
  - BlinkRecognizer
  - HeadPoseDetector (new)
  - GestureCoordinator (new)
  - PageTurnManager
- [ ] Implement CameraManagerDelegate
- [ ] Process frames through vision pipeline
- [ ] Route gesture detections to GestureCoordinator
- [ ] Handle page turn events from GestureCoordinator
- [ ] Manage camera lifecycle (start/stop based on view)
- [ ] Expose state to Views (@Published properties)

**Dependencies**: 1.1, 1.3
**Estimated Complexity**: High

### 3.2 Wire End-to-End Gesture Flow
**Tasks**:
- [ ] Connect camera frames → VisionProcessor
- [ ] Connect face observations → BlinkRecognizer + HeadPoseDetector
- [ ] Connect gesture results → GestureCoordinator
- [ ] Connect coordinator delegate → PageTurnManager
- [ ] Add logging for debugging gesture flow
- [ ] Test each gesture mode independently
- [ ] Test hybrid modes (blink + shake confirmation)

**Dependencies**: 3.1
**Estimated Complexity**: High

### 3.3 Add Camera Permissions
**Files**: `Info.plist`, `GazeTurnApp.swift` or `ContentView.swift`

**Tasks**:
- [ ] Add NSCameraUsageDescription to Info.plist
- [ ] Request camera permission on app launch
- [ ] Handle permission denied gracefully
- [ ] Show permission explanation UI
- [ ] Provide deep link to Settings if denied

**Dependencies**: None
**Estimated Complexity**: Low

---

## Phase 4: Calibration & Fine-Tuning

### 4.1 Create Calibration Wizard
**Files**: New `GazeTurn/View/CalibrationView.swift`

**Tasks**:
- [ ] Design step-by-step calibration flow
- [ ] Guide user through:
  - Blink calibration (if applicable to mode)
  - Head shake calibration (if applicable)
- [ ] Measure user's natural gesture patterns
- [ ] Auto-calculate optimal thresholds
- [ ] Show real-time feedback during calibration
- [ ] Allow re-calibration at any time
- [ ] Save calibrated values per instrument mode

**Dependencies**: 3.1
**Estimated Complexity**: Medium-High

### 4.2 Implement Gesture Visualization
**Files**: Update `BrowseView.swift`, new `GestureDebugView.swift`

**Tasks**:
- [ ] Add real-time gesture indicators:
  - Eye state visualization (open/closed)
  - Blink counter
  - Head yaw angle indicator
  - Shake direction arrows
- [ ] Show gesture confidence levels
- [ ] Add debug mode toggle in settings
- [ ] Create gesture history timeline (last 5 sec)

**Dependencies**: 3.1
**Estimated Complexity**: Medium

---

## Phase 5: Testing & Validation

### 5.1 Unit Testing
**Tasks**:
- [ ] Test BlinkRecognizer logic with mock data
- [ ] Test HeadPoseDetector angle calculations
- [ ] Test GestureCoordinator mode switching
- [ ] Test InstrumentMode configurations
- [ ] Test PageTurnManager navigation logic

**Dependencies**: All core components
**Estimated Complexity**: Medium

### 5.2 Integration Testing
**Tasks**:
- [ ] Test camera → vision → gesture flow
- [ ] Test each instrument mode end-to-end:
  - String mode (blink only)
  - Woodwind/Brass (hybrid)
  - Keyboard (head shake)
  - Plucked strings (filtered shake)
- [ ] Test mode switching during session
- [ ] Test with PDF files
- [ ] Test with image files
- [ ] Test with mixed content
- [ ] Measure false positive rates
- [ ] Measure latency (gesture → page turn)

**Dependencies**: 3.2
**Estimated Complexity**: High

### 5.3 Real-World User Testing
**Tasks**:
- [ ] Test with actual musicians
- [ ] Test each instrument type with real instruments:
  - Violinist testing string mode
  - Pianist testing keyboard mode
  - Flutist testing woodwind mode
- [ ] Gather feedback on gesture comfort
- [ ] Measure success rate across different users
- [ ] Test in various lighting conditions
- [ ] Test with different face shapes/angles
- [ ] Iterate on thresholds based on feedback

**Dependencies**: 5.2
**Estimated Complexity**: High

---

## Phase 6: Polish & Refinements

### 6.1 Error Handling & Edge Cases
**Tasks**:
- [ ] Handle camera unavailable
- [ ] Handle no face detected for >5 seconds
- [ ] Handle multiple faces in frame
- [ ] Handle corrupted/invalid files
- [ ] Add loading indicators
- [ ] Add informative error messages
- [ ] Implement graceful degradation

**Dependencies**: 3.2
**Estimated Complexity**: Medium

### 6.2 Performance Optimization
**Tasks**:
- [ ] Profile Vision processing performance
- [ ] Optimize frame processing rate (target 30 fps)
- [ ] Reduce memory usage
- [ ] Optimize PDF/image rendering
- [ ] Implement frame skipping if needed
- [ ] Test on older iOS devices (iPhone X, 11)

**Dependencies**: 5.2
**Estimated Complexity**: Medium

### 6.3 UI/UX Polish
**Tasks**:
- [ ] Add smooth page turn animations
- [ ] Add haptic feedback on gesture detection
- [ ] Add haptic feedback on page turn
- [ ] Improve visual design consistency
- [ ] Add app icon and launch screen
- [ ] Dark mode support
- [ ] Accessibility (VoiceOver, Dynamic Type)
- [ ] Localization support (EN, ZH)

**Dependencies**: Phase 2
**Estimated Complexity**: Medium

---

## Recommended Implementation Order

1. **Phase 1.2** - Instrument mode system (defines architecture)
2. **Phase 1.1** - HeadPoseDetector (new capability)
3. **Phase 1.3** - GestureCoordinator (integrates gestures)
4. **Phase 1.4** - Update VisionProcessor (enable head pose)
5. **Phase 2.1** - InstrumentSelectionView (onboarding)
6. **Phase 2.2** - FileListView (file loading)
7. **Phase 2.3** - BrowseView (core viewing)
8. **Phase 2.5** - ContentView (connect navigation)
9. **Phase 3.3** - Camera permissions (quick win)
10. **Phase 3.1** - Main ViewModel (integrate everything)
11. **Phase 3.2** - Wire gesture flow (make it work)
12. **Phase 5.2** - Integration testing (validate)
13. **Phase 4.1** - Calibration wizard (improve UX)
14. **Phase 2.4** - SettingsView (user control)
15. **Phase 4.2** - Gesture visualization (debugging)
16. **Phase 5.3** - Real-world testing (validate with users)
17. **Phase 6** - Polish & refinements (ship quality)

---

## Technical Considerations

### Architecture Decisions
- **MVVM Pattern**: ViewModel manages business logic
- **Coordinator Pattern**: GestureCoordinator handles gesture routing
- **Strategy Pattern**: InstrumentMode encapsulates mode-specific behavior
- **Delegation**: Use delegates for loose coupling
- **Combine Framework**: Use for reactive state management (@Published)

### Code Cleanup Needed
- Remove duplicate blink detection in `GazeDetector.swift`
- Fix incorrect Vision revision in `GazeDetector.swift:25` (uses VNDetectBarcodesRequestRevision3)
- Refactor or deprecate `GazeDetector.swift` (replaced by BlinkRecognizer)

### Head Pose Detection Implementation
```swift
// VNFaceObservation provides:
face.yaw   // NSNumber? - left/right rotation
face.pitch // NSNumber? - up/down tilt
face.roll  // NSNumber? - head tilt

// Yaw values:
// -1.0 to 1.0 radians (~-57° to 57°)
// Negative = looking left
// Positive = looking right
```

### Performance Targets
- Frame processing: 30 fps (ideal), >15 fps (minimum)
- Gesture detection latency: <200ms
- Page turn response: <300ms total
- Memory usage: <100MB during active use
- False positive rate: <5% across all modes
- True positive rate: >95% for deliberate gestures

### Testing Strategy
- Unit tests for gesture recognition logic
- Integration tests for vision pipeline
- Manual testing for each instrument mode
- Real-world testing with actual musicians
- Performance testing on multiple devices
- Accessibility testing (VoiceOver, contrast)

### Potential Challenges
1. **Head shake false positives**: Musicians may naturally move their heads with rhythm
   - Solution: Temporal filtering, higher thresholds for plucked string mode
2. **Blink false positives**: Natural blinking during performance
   - Solution: Require double-blink or longer duration
3. **Lighting variations**: Poor lighting affects face detection
   - Solution: Add lighting quality indicator, guide user to better position
4. **Performance on older devices**: Vision processing intensive
   - Solution: Adaptive frame rate, lower quality mode
5. **Hybrid mode complexity**: Coordinating two gestures
   - Solution: Clear visual feedback, timeout between gestures
