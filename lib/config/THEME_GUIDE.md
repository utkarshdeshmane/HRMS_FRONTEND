# HRMS App Theme Guide

## 🎨 Professional Green & Grey Theme

The app now uses a consistent, professional color scheme with **Green** as the primary color and **Light Grey** accents.

---

## Color Palette

### Primary Colors (Green)
```dart
AppColors.primary           // #2E7D32 - Dark Green (Main)
AppColors.primaryLight      // #4CAF50 - Medium Green
AppColors.primaryLighter    // #66BB6A - Light Green
AppColors.primaryDark       // #1B5E20 - Very Dark Green
```

### Grey Colors
```dart
AppColors.greyBackground    // #F5F5F5 - Very Light Grey (Backgrounds)
AppColors.greyLight         // #E0E0E0 - Light Grey (Borders)
AppColors.greyMedium        // #9E9E9E - Medium Grey
AppColors.greyDark          // #757575 - Dark Grey
AppColors.greyText          // #424242 - Text Grey
```

### Status Colors
```dart
AppColors.success           // #4CAF50 - Green (Success)
AppColors.error             // #E53935 - Red (Error)
AppColors.warning           // #FFA726 - Orange (Warning)
AppColors.info              // #42A5F5 - Blue (Info)
```

---

## Usage Examples

### 1. Using Theme Colors

```dart
// Primary button
ElevatedButton(
  onPressed: () {},
  child: Text('Submit'),
  // Automatically uses AppTheme.primaryGreen
)

// Custom colored container
Container(
  color: AppColors.primary,
  child: Text('Green Container'),
)
```

### 2. Using Gradients

```dart
// Primary gradient header
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text('Header'),
)

// Success gradient
Container(
  decoration: BoxDecoration(
    gradient: AppColors.successGradient,
  ),
)
```

### 3. Status Badges

```dart
// Active status (Green)
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: AppColors.success.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.success),
  ),
  child: Text(
    'Active',
    style: TextStyle(
      color: AppColors.success,
      fontWeight: FontWeight.bold,
    ),
  ),
)

// Inactive status (Red)
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: AppColors.error.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.error),
  ),
  child: Text(
    'Inactive',
    style: TextStyle(
      color: AppColors.error,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### 4. Cards with Shadow

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: YourContent(),
)
```

### 5. Input Fields

```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Enter text',
    prefixIcon: Icon(Icons.search, color: AppColors.primary),
    // Automatically uses theme styling
  ),
)
```

---

## Component Colors

### AppBar
- Background: `AppColors.primary` (Green)
- Text: White
- Icons: White

### Buttons
- Primary: `AppColors.primary` (Green)
- Text: White
- Disabled: Grey

### Cards
- Background: White (Light mode) / Dark Surface (Dark mode)
- Shadow: Light grey shadow
- Border Radius: 12-16px

### Text Fields
- Background: `AppColors.greyBackground` (Light grey)
- Border: `AppColors.greyLight`
- Focus Border: `AppColors.primary` (Green)
- Error Border: `AppColors.error` (Red)

### Floating Action Button
- Background: `AppColors.primary` (Green)
- Icon: White

---

## Dark Mode

The theme automatically supports dark mode:

```dart
// In main.dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Auto switch based on system
)
```

### Dark Mode Colors
- Background: `#121212`
- Surface: `#1E1E1E`
- Cards: `#2A2A2A`
- Primary: `#4CAF50` (Lighter green for better contrast)

---

## Best Practices

### ✅ DO
- Use `AppColors.primary` for main actions
- Use `AppColors.greyBackground` for page backgrounds
- Use `AppColors.success` for positive actions
- Use `AppColors.error` for destructive actions
- Use consistent border radius (12-16px)
- Use shadows for elevation

### ❌ DON'T
- Don't use hardcoded colors like `Colors.blue`
- Don't mix different color schemes
- Don't use too many different shades
- Don't forget to test in dark mode

---

## Migration Guide

### Replacing Old Colors

```dart
// OLD (Blue theme)
Colors.blue[600]           → AppColors.primary
Colors.blueAccent          → AppColors.primaryLight
Colors.orange[600]         → AppColors.primary (for edit screens)
Colors.grey[100]           → AppColors.greyBackground
Colors.grey[200]           → AppColors.greyLight

// Status colors remain the same
Colors.green[600]          → AppColors.success
Colors.red[600]            → AppColors.error
```

### Example Migration

```dart
// BEFORE
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue[600]!, Colors.blue[400]!],
    ),
  ),
)

// AFTER
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

---

## Quick Reference

| Element | Color | Hex |
|---------|-------|-----|
| Primary Action | Green | #2E7D32 |
| Background | Light Grey | #F5F5F5 |
| Cards | White | #FFFFFF |
| Text | Dark Grey | #424242 |
| Success | Green | #4CAF50 |
| Error | Red | #E53935 |
| Warning | Orange | #FFA726 |
| Info | Blue | #42A5F5 |

---

## 🎉 Result

Your app now has a **professional, consistent green and grey theme** that looks modern and clean!

- ✅ Green primary color for actions
- ✅ Light grey backgrounds
- ✅ Consistent spacing and shadows
- ✅ Professional appearance
- ✅ Dark mode support
- ✅ Accessible color contrast
