# OTP Card Enhancement Specification

## Overview
Simplify the OTP card design by removing redundant UI elements and improving visual hierarchy. This will make cards more compact, cleaner, and allow more cards to be visible on screen.

## Current State Analysis

### Current OTP Card Features
1. **Header Section**
   - Service icon (40x40 with colored background)
   - Issuer name (bold)
   - Account name (caption)
   - Favorite button (star icon)
   - Delete button (trash icon)

2. **OTP Code Section**
   - "Verification Code" label with copy icon
   - 6-digit OTP code (formatted as XXX XXX)
   - Circular timer (right side) showing seconds remaining
   - "seconds" label below timer

3. **Progress Section**
   - Linear progress bar at bottom

4. **Interactions**
   - Tap card to view details
   - Tap OTP code area to copy
   - Swipe left to reveal delete action
   - Swipe right to reveal favorite action
   - Tap favorite button to toggle
   - Tap delete button to remove

### Current Issues
- **Redundancy**: Both button actions AND swipe gestures for favorite/delete
- **Visual clutter**: Two progress indicators (circular + linear)
- **Wasted space**: Buttons take up valuable header space
- **Height**: Cards are taller than necessary (~180-200px)

## Proposed Changes

### Change 1: Remove Redundant Action Buttons
**Rationale**: Swipe gestures already provide favorite and delete actions. Having both buttons and gestures is redundant and clutters the UI.

**Implementation**:
- Remove favorite IconButton from header
- Remove delete IconButton from header
- Keep swipe gestures (already implemented in home_screen.dart)
- Header will only show: icon + issuer name + account name

**Benefits**:
- Cleaner header design
- More space for text (longer issuer/account names)
- Reduces visual noise
- Saves ~48px horizontal space

### Change 2: Remove Linear Progress Bar
**Rationale**: The circular timer already shows progress visually. The linear bar duplicates this information.

**Implementation**:
- Remove LinearProgressIndicator from bottom of card
- Remove associated spacing (SizedBox)
- Keep circular timer as the single source of progress

**Benefits**:
- Reduces card height by ~16px
- Cleaner, less cluttered design
- Single, clear progress indicator

### Change 3: Move Circular Timer to Header
**Rationale**: Moving the timer to the header creates better visual balance and makes the OTP code section cleaner.

**Implementation**:
- Move circular timer from OTP section to header (right side)
- Position timer where favorite/delete buttons were
- Keep timer size (48x48) and styling
- Remove "seconds" label (redundant with number inside)

**Benefits**:
- Better visual hierarchy
- More prominent timer visibility
- Cleaner OTP code section
- Saves ~24px vertical space

### Change 4: Add First-Time Swipe Hint
**Rationale**: Without visible buttons, users need to discover swipe gestures. A subtle hint on first use improves discoverability.

**Implementation**:
- Show animated swipe hint on first 1-2 cards
- Use subtle overlay with left/right arrows
- Auto-dismiss after 3 seconds or first swipe
- Store hint-shown state in SharedPreferences
- Only show once per app install

**Benefits**:
- Improves gesture discoverability
- Reduces user confusion
- Follows iOS/Android patterns

## User Stories

### US-1: Cleaner Card Header
**As a** user  
**I want** a cleaner card header without redundant buttons  
**So that** I can see longer issuer/account names and have less visual clutter

**Acceptance Criteria**:
- [ ] Favorite button removed from header
- [ ] Delete button removed from header
- [ ] Swipe gestures still work for favorite/delete
- [ ] Header shows: icon + issuer + account name + timer
- [ ] Longer text displays without truncation (up to available space)

### US-2: Single Progress Indicator
**As a** user  
**I want** a single, clear progress indicator  
**So that** I'm not distracted by redundant information

**Acceptance Criteria**:
- [ ] Linear progress bar removed from card bottom
- [ ] Circular timer remains as sole progress indicator
- [ ] Timer shows seconds remaining (number + circular fill)
- [ ] Timer color changes to red when < 10 seconds
- [ ] Card height reduced by ~16px

### US-3: Timer in Header
**As a** user  
**I want** the timer positioned in the card header  
**So that** I can see time remaining at a glance without scanning the whole card

**Acceptance Criteria**:
- [ ] Circular timer moved to header (right side)
- [ ] Timer size: 48x48 (matches removed button space)
- [ ] "seconds" label removed (redundant)
- [ ] Timer syncs with TOTP 30-second window
- [ ] Timer color: primary (>10s), error (<10s)

### US-4: Swipe Gesture Discovery
**As a** first-time user  
**I want** a hint about swipe gestures  
**So that** I can discover how to favorite/delete accounts

**Acceptance Criteria**:
- [ ] Hint shown on first 1-2 cards on first app launch
- [ ] Animated arrows indicate swipe left/right
- [ ] Hint auto-dismisses after 3 seconds
- [ ] Hint dismisses on first swipe action
- [ ] Hint never shows again after dismissal
- [ ] Hint state persisted in SharedPreferences

## Technical Implementation

### Files to Modify

#### 1. lib/widgets/otp_card.dart
**Changes**:
- Remove favorite IconButton from header Row
- Remove delete IconButton from header Row
- Move circular timer Stack to header Row (right side)
- Remove "seconds" Text below timer
- Remove LinearProgressIndicator from bottom
- Remove associated SizedBox spacing
- Adjust Row layout to accommodate timer in header

**Code Structure**:
```dart
Row(
  children: [
    // Icon (40x40)
    Container(...),
    SizedBox(width: 12),
    // Issuer + Account names
    Expanded(
      child: Column(
        children: [
          Text(issuer),
          Text(accountName),
        ],
      ),
    ),
    // Circular timer (moved here)
    SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          CircularProgressIndicator(...),
          Center(child: Text(seconds)),
        ],
      ),
    ),
  ],
)
```

#### 2. lib/widgets/otp_card_skeleton.dart
**Changes**:
- Remove favorite/delete button skeletons
- Add circular timer skeleton to header
- Remove linear progress bar skeleton
- Adjust spacing to match new layout

#### 3. lib/widgets/swipe_hint_overlay.dart (NEW FILE)
**Purpose**: Reusable widget for showing swipe gesture hints

**Features**:
- Animated left/right arrows
- Semi-transparent overlay
- Auto-dismiss timer
- Dismissible on tap/swipe

#### 4. lib/view/home_screen.dart
**Changes**:
- Add swipe hint logic for first-time users
- Check SharedPreferences for hint-shown state
- Show hint on first 1-2 cards
- Update hint state on dismissal

### State Management

#### SharedPreferences Keys
```dart
static const String SWIPE_HINT_SHOWN = 'swipe_hint_shown';
```

#### Hint Display Logic
```dart
// Show hint if:
// 1. First app launch (key not set)
// 2. Card index is 0 or 1
// 3. User hasn't swiped yet in current session
```

## Design Specifications

### Card Dimensions
- **Current height**: ~180-200px
- **New height**: ~140-160px
- **Space saved**: ~40-50px per card
- **Cards visible**: +1-2 more cards on screen

### Header Layout
```
[Icon 40x40] [Issuer Name + Account] [Timer 48x48]
```

### Timer Specifications
- Size: 48x48
- Stroke width: 3.5
- Colors: primary (>10s), error (≤10s)
- Background: onSurface with 10% opacity
- Font: bodyMedium, fontWeight: w600

### Swipe Hint Design
- Background: black with 40% opacity
- Arrows: white, size 32
- Animation: fade in + slide
- Duration: 3 seconds
- Position: centered overlay on card

## Testing Checklist

### Visual Testing
- [ ] Card height reduced by ~40-50px
- [ ] Header shows icon + text + timer only
- [ ] No favorite/delete buttons visible
- [ ] No linear progress bar visible
- [ ] Timer positioned correctly in header
- [ ] Timer size matches design (48x48)
- [ ] Longer issuer names display properly

### Functional Testing
- [ ] Swipe left reveals delete action
- [ ] Swipe right reveals favorite action
- [ ] Timer counts down correctly
- [ ] Timer syncs with TOTP window
- [ ] Timer color changes at 10 seconds
- [ ] OTP code copy still works
- [ ] Card tap navigation works

### First-Time User Testing
- [ ] Hint shows on first launch
- [ ] Hint shows on first 1-2 cards only
- [ ] Hint auto-dismisses after 3 seconds
- [ ] Hint dismisses on swipe action
- [ ] Hint never shows again after dismissal
- [ ] Hint state persists across app restarts

### Skeleton Testing
- [ ] Skeleton matches new card layout
- [ ] No button skeletons visible
- [ ] Timer skeleton in header
- [ ] No progress bar skeleton
- [ ] Skeleton height matches new card height

## Performance Considerations

### Improvements
- Fewer widgets per card (removed 2 IconButtons + 1 LinearProgressIndicator)
- Reduced render tree complexity
- Less layout calculations
- Smaller widget tree

### Measurements
- Widget count per card: -3 widgets
- Render time: Expected ~5-10% improvement
- Memory: Minimal reduction (~100 bytes per card)

## Accessibility

### Considerations
- Swipe gestures must have semantic labels
- Timer must have semantic label ("X seconds remaining")
- Swipe hint must be screen-reader friendly
- Alternative actions for users who can't swipe

### Implementation
```dart
Semantics(
  label: 'Swipe left to delete, swipe right to favorite',
  child: OTPCard(...),
)
```

## Migration Notes

### Breaking Changes
None - this is a UI-only change

### User Impact
- Existing users will see new design immediately
- Swipe gestures already exist, no behavior change
- First-time hint only for new installs

### Rollback Plan
If issues arise, revert changes to:
- lib/widgets/otp_card.dart
- lib/widgets/otp_card_skeleton.dart
- lib/view/home_screen.dart

## Success Metrics

### Quantitative
- Card height reduced by 20-25%
- 1-2 more cards visible on screen
- Widget count reduced by 3 per card
- No performance regression

### Qualitative
- Cleaner, less cluttered design
- Better visual hierarchy
- Improved focus on OTP code
- Consistent with modern app design patterns

## Timeline

### Phase 1: Core Changes (1-2 hours)
- Remove buttons from header
- Move timer to header
- Remove linear progress bar
- Update skeleton

### Phase 2: Swipe Hint (1 hour)
- Create SwipeHintOverlay widget
- Add SharedPreferences logic
- Integrate into home_screen.dart
- Test hint behavior

### Phase 3: Testing & Polish (30 minutes)
- Visual testing on multiple devices
- Functional testing
- Accessibility testing
- Performance verification

**Total Estimated Time**: 2.5-3.5 hours

## Open Questions

1. Should swipe hint show on first 1 or 2 cards?
   - **Recommendation**: 1 card (less intrusive)

2. Should hint auto-dismiss or require user action?
   - **Recommendation**: Auto-dismiss after 3 seconds (better UX)

3. Should timer show "seconds" label?
   - **Recommendation**: No (redundant, saves space)

4. Should we add haptic feedback for swipe actions?
   - **Recommendation**: Yes (already implemented in home_screen.dart)

## Approval

- [ ] User approval received
- [ ] Design reviewed
- [ ] Technical approach validated
- [ ] Ready for implementation

---

**Created**: 2026-01-14  
**Status**: Draft - Awaiting Approval  
**Priority**: Medium  
**Complexity**: Low-Medium
