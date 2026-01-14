# Shimmer Loading Improved

## Problem

The loading skeleton on pull-to-refresh looked like a glitch:
- **Simple rectangles** - Didn't match OTP card design
- **No card structure** - Just flat boxes
- **Jarring transition** - Sudden switch from skeleton to actual cards
- **Felt like a bug** - Didn't look intentional or polished

## Solution: OTP Card Skeleton

Created a dedicated skeleton that matches the actual OTP card design exactly.

### Before

```dart
// Simple rectangle skeleton
Skeleton(height: AppConstants.getResponsiveOTPCardMinHeight(context))
```

Result: Plain gray rectangle that doesn't look like anything

### After

```dart
// Detailed OTP card skeleton
const OTPCardSkeleton()
```

Result: Looks exactly like an OTP card with shimmer effect

## New OTPCardSkeleton Widget

### Structure Matches Real OTP Card

```dart
Card(
  elevation: AppConstants.elevationMedium,
  shape: RoundedRectangleBorder(borderRadius: ...),
  child: Container(
    padding: ...,
    child: Column(
      children: [
        // Header row
        Row(
          children: [
            Skeleton(40x40, rounded), // Icon
            Column([
              Skeleton(120x18),       // Issuer name
              Skeleton(80x14),        // Account name
            ]),
            Skeleton(24x24),          // Menu icon
          ],
        ),
        
        // OTP code row
        Row(
          children: [
            Skeleton(expanded, 48h), // OTP code
            Skeleton(48x48),         // Copy button
          ],
        ),
        
        // Progress bar
        Skeleton(full width, 4h),    // Timer bar
      ],
    ),
  ),
)
```

### Features

✅ **Same Card elevation** - Matches real card shadow
✅ **Same border radius** - Rounded corners like real cards
✅ **Same padding** - Internal spacing matches
✅ **Same layout** - Icon, text, button positions match
✅ **Same spacing** - Gaps between elements match
✅ **Smooth shimmer** - Animated gradient effect
✅ **Responsive** - Uses same responsive sizing as real cards

## Visual Comparison

### Before (Simple Rectangle)
```
┌─────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ← Just a gray box
└─────────────────────────┘
```

### After (OTP Card Skeleton)
```
┌─────────────────────────┐
│ ┌──┐ ▓▓▓▓▓▓▓▓▓▓         │ ← Icon + Issuer
│ └──┘ ▓▓▓▓▓▓              │ ← Account name
│                          │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ┌──┐ │ ← OTP + Copy
│                    └──┘ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ ← Progress bar
└─────────────────────────┘
```

## Benefits

✅ **Professional appearance** - Looks intentional, not broken
✅ **Smooth transition** - Skeleton → Real card feels natural
✅ **User confidence** - Clear that data is loading
✅ **Consistent design** - Matches app's visual language
✅ **No glitch feeling** - Smooth, polished experience
✅ **Better UX** - Users know what to expect

## Implementation

### New File
- ✅ `lib/widgets/otp_card_skeleton.dart` - Dedicated skeleton widget

### Updated Files
- ✅ `lib/view/home_screen.dart` - Uses new OTPCardSkeleton

### Usage
```dart
if (viewModel.isLoading) {
  return Padding(
    padding: EdgeInsets.all(AppConstants.spaceMd),
    child: Column(
      children: [
        const OTPCardSkeleton(),
        SizedBox(height: AppConstants.otpCardSpacing),
        const OTPCardSkeleton(),
        SizedBox(height: AppConstants.otpCardSpacing),
        const OTPCardSkeleton(),
      ],
    ),
  );
}
```

## Result

Pull-to-refresh now shows beautiful, card-shaped skeletons that:
- Look exactly like the real OTP cards
- Have smooth shimmer animation
- Transition seamlessly to real content
- Feel polished and professional

No more glitchy rectangles! 🎯
