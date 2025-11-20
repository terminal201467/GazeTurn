# GazeTurn v1 Specification

## Overview
GazeTurn is an iOS application that enables hands-free page turning for sheet music using intelligent gesture recognition. Musicians can control page navigation through head movements (head shake) and/or eye blinks, with adaptive control modes optimized for different instrument types. This allows musicians to keep their hands free while playing instruments.

## Core Features

### 1. Gesture Recognition System

#### 1.1 Eye Gaze & Blink Detection
- **Face Detection**: Real-time facial landmark detection using Vision framework
- **Eye Tracking**: Monitor left and right eye states (open/closed)
- **Blink Recognition**: Detect single/double-blink gestures for page turning
- **Configurable Thresholds**:
  - Eye open/close threshold: 0.03 (adjustable)
  - Blink time window: 0.5 seconds
  - Minimum blink duration: 0.1 seconds
  - Blink count: 1-2 blinks (mode dependent)

#### 1.2 Head Pose Detection
- **Yaw Tracking**: Monitor head left/right rotation (yaw angle)
- **Head Shake Recognition**: Detect deliberate head shake gestures
- **Direction Detection**:
  - Left shake: yaw < -threshold (previous page)
  - Right shake: yaw > threshold (next page)
- **Configurable Thresholds**:
  - Shake angle threshold: 15° - 35° (instrument dependent)
  - Shake duration: 0.3 - 0.8 seconds
  - Cooldown period: 0.5 seconds (prevent multiple triggers)

### 2. Instrument-Adaptive Control Modes

The app provides specialized control modes optimized for different instrument families:

#### 2.1 String Instruments Mode (固定頭部)
**Instruments**: Violin, Viola, Cello
- **Primary**: Blink detection only
- **Navigation**: Double blink = next page, Long blink (0.5s) = previous page
- **Rationale**: Head must remain fixed to support instrument

#### 2.2 Woodwind/Brass Mode (嘴部固定)
**Instruments**: Flute, Clarinet, Trumpet, Trombone, Saxophone
- **Primary**: Hybrid (head shake + blink confirmation)
- **Navigation**: Slight head shake (15-20°) + quick blink = confirm turn
- **Rationale**: Mouth position fixed but head can move slightly

#### 2.3 Keyboard Mode (頭部自由)
**Instruments**: Piano, Keyboard, Organ
- **Primary**: Head shake detection
- **Navigation**: Left shake (>30°) = previous, Right shake (>30°) = next
- **Rationale**: Complete head freedom, most intuitive control

#### 2.4 Plucked Strings Mode (可能隨節奏搖頭)
**Instruments**: Guitar, Bass, Ukulele
- **Primary**: Head shake with temporal filtering
- **Navigation**: Deliberate slow shake (0.5s duration, >35°)
- **Rationale**: Filter out rhythmic head movements during playing

#### 2.5 Percussion Mode
**Instruments**: Drums, Marimba, Timpani
- **Primary**: User selectable (head shake OR blink)
- **Navigation**: Configurable based on user preference
- **Rationale**: High variability in playing posture

#### 2.6 Vocal Mode
**Instruments**: Vocal performance
- **Primary**: Head shake detection
- **Navigation**: Clear left/right shake (>30°)
- **Rationale**: Head position important but mobile

#### 2.7 Custom Mode
- **Primary**: Fully customizable
- **Navigation**: User defines gesture combinations
- **Rationale**: Accommodate special instruments or personal preferences

### 3. Camera Management
- **Front Camera Support**: Capture user's face using front-facing camera
- **High-Quality Capture**: Session preset set to `.high`
- **Real-Time Processing**: Continuous frame capture and analysis
- **Session Control**: Start/stop camera session as needed

### 4. Page Turn Management
- **Multi-Format Support**:
  - PDF files (with multi-page support)
  - Image files (PNG, JPG, etc.)
  - Mixed content (PDF + images in same session)
- **Navigation**:
  - Next page (forward navigation)
  - Previous page (backward navigation)
  - Page index tracking
- **Display Modes**:
  - PDFView for PDF content
  - UIImageView for image content

### 5. User Interface
- **Instrument Selection**: Choose instrument type on first launch or in settings
- **File List View**: Browse and select sheet music files
- **Browse View**: Display and navigate through sheet music
- **Settings View**: Calibration, sensitivity adjustment, mode selection
- **Visual Feedback**: Real-time gesture detection indicators
- **Content View**: Main application entry point

## Technical Architecture

### Component Structure
```
GazeTurn/
   FeatManager/
      Camara/
         CameraManager.swift - Camera capture and session management
      GazeCore/
         VisionProcessor.swift - Vision framework integration
         GazeDetector.swift - Eye state detection (legacy, to be refactored)
         BlinkRecognizer.swift - Blink pattern analysis
         HeadPoseDetector.swift - [NEW] Head shake recognition
      GestureControl/
         GestureCoordinator.swift - [NEW] Unified gesture management
         InstrumentMode.swift - [NEW] Instrument mode configurations
      PageControl/
         PageTurnManager.swift - Page navigation logic
   Model/
      InstrumentType.swift - [NEW] Instrument type definitions
   View/
      ContentView.swift - Main entry view
      InstrumentSelectionView.swift - [NEW] Instrument picker
      FileListView.swift - File selection interface
      BrowseView.swift - Sheet music display
      SettingsView.swift - [NEW] Configuration and calibration
```

### Data Flow (Updated)
1. **Camera** → CameraManager captures video frames
2. **Vision** → VisionProcessor analyzes frames for face landmarks + head pose (yaw/pitch/roll)
3. **Detection** → GestureCoordinator routes to:
   - BlinkRecognizer for eye blink detection
   - HeadPoseDetector for head shake detection
4. **Mode Logic** → InstrumentMode determines which gestures to activate based on selected instrument
5. **Action** → PageTurnManager executes page navigation based on detected gesture
6. **Display** → View updates to show new page + visual feedback

## Implementation Status

### ✅ Completed
- Core vision processing infrastructure (VisionProcessor)
- Blink detection algorithm (BlinkRecognizer)
- Page turn management system (PageTurnManager)
- Camera capture setup (CameraManager)
- Basic project structure

### 🚧 In Progress / TODO

#### New Components (High Priority)
- **HeadPoseDetector.swift**: Implement head shake recognition using yaw angle
- **GestureCoordinator.swift**: Create unified coordinator to manage both blink and head shake gestures
- **InstrumentMode.swift**: Define instrument-specific gesture configurations
- **InstrumentType.swift**: Enum/model for instrument categories

#### UI Implementation (High Priority)
- **InstrumentSelectionView**: Onboarding flow to select instrument type
- **FileListView**: File browser implementation with document picker
- **BrowseView**: Sheet music display with PDFView/ImageView integration
- **SettingsView**: Configuration UI for calibration and sensitivity
- **ContentView**: Navigation structure connecting all views

#### Integration (Critical)
- Connect CameraManager → VisionProcessor → GestureCoordinator
- Wire gesture events to PageTurnManager with direction support
- Implement mode-specific gesture filtering
- Add visual feedback for gesture detection

#### Additional Features
- File picker for selecting sheet music
- File storage and persistence
- Camera permissions handling
- Calibration wizard for each instrument mode
- Real-time gesture detection indicators

## Success Criteria
1. Users can select their instrument type
2. Users can load PDF/image sheet music files
3. Head shake gestures reliably trigger page turns (for applicable modes)
4. Blink gestures reliably trigger page turns (for applicable modes)
5. Hybrid mode (head shake + blink) works without false positives
6. Page navigation works smoothly without lag
7. Camera feed processes at acceptable frame rate (>15 fps)
8. False positive detection rate < 5% across all modes
9. Gesture detection works across different lighting conditions

## Future Enhancements (Post-v1)
- Auto-scroll mode based on tempo
- Foot pedal integration as alternative control
- Gaze-point tracking for more precise navigation
- Multiple simultaneous file support (multi-part scores)
- Cloud storage integration
- Practice mode with annotations
- AI-based gesture learning (personalized calibration)
- Metronome integration
- Recording practice sessions
