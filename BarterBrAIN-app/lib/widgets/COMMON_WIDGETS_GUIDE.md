# Common Widgets Usage Guide

This guide explains how to use the common widgets for consistent styling throughout the BarterBrAIn app.

---

## 📝 CommonText Widget

Use `CommonText` for all text in the app to maintain consistent typography.

### Basic Usage

```dart
// Default (bodyMedium - 15px)
CommonText('Hello World')

// Custom styling
CommonText(
  'Hello World',
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: Colors.red,
)
```

### Named Constructors

```dart
// Display Large (34px, bold) - Page titles
CommonText.displayLarge('Welcome to BarterBrAIn')

// Display Medium (28px, bold) - Section titles
CommonText.displayMedium('Featured Products')

// Display Small (22px, semibold) - Subsection titles
CommonText.displaySmall('Categories')

// Headline (20px, semibold) - Card titles
CommonText.headline('Product Title')

// Body Large (17px, regular) - Main content
CommonText.bodyLarge('This is the main content text.')

// Body Medium (15px, regular) - Default body text
CommonText.bodyMedium('Regular body text')

// Body Small (13px, regular, secondary color) - Helper text
CommonText.bodySmall('Additional information')

// Label (15px, semibold) - Form labels, tags
CommonText.label('Required Field')

// Caption (11px, regular, secondary color) - Timestamps, metadata
CommonText.caption('2 hours ago')

// Button (17px, semibold) - Button text
CommonText.button('Continue')
```

### Color Variants

```dart
// Error text (red)
CommonText.error('Invalid email address')

// Success text (green)
CommonText.success('Profile updated successfully')

// Primary colored text (teal)
CommonText.primary('Learn more')

// Secondary colored text (gray)
CommonText.secondary('Optional field')
```

### Advanced Options

```dart
CommonText.bodyLarge(
  'Long text that might overflow',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
)
```

---

## 📝 CommonTextFormField Widget

Use `CommonTextFormField` for all input fields to maintain consistent styling.

### Basic Usage

```dart
CommonTextFormField(
  controller: _controller,
  labelText: 'Username',
  hintText: 'Enter your username',
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    return null;
  },
)
```

### Named Constructors

```dart
// Email field (with email keyboard and @ symbol)
CommonTextFormField.email(
  controller: _emailController,
  validator: (value) {
    if (value == null || !value.contains('@')) {
      return 'Invalid email';
    }
    return null;
  },
)

// Password field (with obscured text)
CommonTextFormField.password(
  controller: _passwordController,
  validator: (value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  },
)

// Name field (with word capitalization)
CommonTextFormField.name(
  controller: _nameController,
  labelText: 'First Name',
  hintText: 'Enter your first name',
)

// Phone field (with number keyboard)
CommonTextFormField.phone(
  controller: _phoneController,
)

// Multiline field (for descriptions, bio, etc.)
CommonTextFormField.multiline(
  controller: _descriptionController,
  labelText: 'Description',
  hintText: 'Enter product description',
  maxLines: 5,
  maxLength: 500,
)

// Search field
CommonTextFormField.search(
  controller: _searchController,
  hintText: 'Search products...',
  onChanged: (value) {
    // Handle search
  },
)
```

### Custom Icons and Actions

```dart
CommonTextFormField(
  controller: _controller,
  labelText: 'Password',
  obscureText: _obscurePassword,
  prefixIcon: Icon(Icons.lock_outline),
  suffixIcon: IconButton(
    icon: Icon(
      _obscurePassword ? Icons.visibility_off : Icons.visibility,
    ),
    onPressed: () {
      setState(() => _obscurePassword = !_obscurePassword);
    },
  ),
)
```

### With Helper and Error Text

```dart
CommonTextFormField.email(
  controller: _emailController,
  helperText: 'Must be a .edu email address',
  validator: (value) {
    if (value == null || !value.endsWith('.edu')) {
      return 'Please use your university email';
    }
    return null;
  },
)
```

---

## 🎨 Typography Constants

Access font sizes and styles via `AppTypography`.

### Font Sizes

```dart
// Use predefined sizes for consistency
AppTypography.fontSizeXs   // 11px - Captions, timestamps
AppTypography.fontSizeS    // 13px - Helper text
AppTypography.fontSizeM    // 15px - Body text (default)
AppTypography.fontSizeL    // 17px - Prominent body text
AppTypography.fontSizeXl   // 20px - Headings
AppTypography.fontSizeXxl  // 22px - Subheadings
AppTypography.fontSize3xl  // 28px - Page titles
AppTypography.fontSize4xl  // 34px - Hero text
```

### Font Weights

```dart
AppTypography.fontWeightRegular   // 400 - Normal text
AppTypography.fontWeightMedium    // 500 - Slightly emphasized
AppTypography.fontWeightSemibold  // 600 - Emphasized text
AppTypography.fontWeightBold      // 700 - Strong emphasis
```

### Text Styles

```dart
// Use directly with Text widget
Text(
  'Custom Text',
  style: AppTypography.bodyLarge,
)

// Or modify existing styles
Text(
  'Custom Text',
  style: AppTypography.bodyLarge.copyWith(
    color: AppConstants.primaryColor,
    fontWeight: FontWeight.bold,
  ),
)

// Create custom style
Text(
  'Custom Text',
  style: AppTypography.custom(
    fontSize: AppTypography.fontSizeXl,
    fontWeight: AppTypography.fontWeightBold,
    color: AppConstants.primaryColor,
  ),
)
```

---

## 🎨 Color Constants

Use `AppConstants` for consistent colors.

### Text Colors

```dart
AppConstants.textPrimary    // Black - Primary text
AppConstants.textSecondary  // Gray - Secondary text
```

### Brand Colors

```dart
AppConstants.primaryColor     // #0ABAB5 - Teal
AppConstants.backgroundColor  // #FFFFFF - White
AppConstants.errorColor       // #FF3B30 - Red
AppConstants.successColor     // #34C759 - Green
```

### System Colors (iOS Grays)

```dart
AppConstants.systemGray   // 8E8E93
AppConstants.systemGray2  // AEAEB2
AppConstants.systemGray3  // C7C7CC
AppConstants.systemGray4  // D1D1D6
AppConstants.systemGray5  // E5E5EA
AppConstants.systemGray6  // F2F2F7 - Input backgrounds
```

---

## 📏 Spacing Constants

Use `AppConstants` for consistent spacing.

```dart
AppConstants.spacingXs   // 4px
AppConstants.spacingS    // 8px
AppConstants.spacingM    // 16px
AppConstants.spacingL    // 24px
AppConstants.spacingXl   // 32px
AppConstants.spacingXxl  // 48px
```

### Example Usage

```dart
Padding(
  padding: EdgeInsets.all(AppConstants.spacingM),
  child: Column(
    children: [
      CommonText.headline('Title'),
      SizedBox(height: AppConstants.spacingS),
      CommonText.bodyMedium('Content'),
    ],
  ),
)
```

---

## 🔘 Border Radius Constants

Use `AppConstants` for consistent border radius.

```dart
AppConstants.radiusS      // 8px
AppConstants.radiusM      // 12px
AppConstants.radiusL      // 16px
AppConstants.radiusXl     // 24px
AppConstants.radiusCircle // 999px - Full circle
```

---

## ✅ Best Practices

### DO ✅

```dart
// Use CommonText for all text
CommonText.bodyLarge('Product Name')

// Use CommonTextFormField for all inputs
CommonTextFormField.email(controller: _emailController)

// Use AppTypography constants
style: AppTypography.bodyLarge

// Use AppConstants for colors and spacing
color: AppConstants.primaryColor
padding: EdgeInsets.all(AppConstants.spacingM)
```

### DON'T ❌

```dart
// Don't use Text widget directly
Text('Product Name', style: TextStyle(fontSize: 17)) // ❌

// Don't use TextFormField directly
TextFormField(decoration: InputDecoration(...)) // ❌

// Don't hardcode font sizes
TextStyle(fontSize: 17) // ❌

// Don't hardcode colors
color: Color(0xFF0ABAB5) // ❌

// Don't hardcode spacing
padding: EdgeInsets.all(16) // ❌
```

---

## 📋 Migration Checklist

When refactoring existing code:

- [ ] Replace all `Text` widgets with `CommonText`
- [ ] Replace all `TextFormField` widgets with `CommonTextFormField`
- [ ] Replace all hardcoded font sizes with `AppTypography` constants
- [ ] Replace all hardcoded colors with `AppConstants` colors
- [ ] Replace all hardcoded spacing with `AppConstants` spacing
- [ ] Replace all hardcoded border radius with `AppConstants` radius

---

## 🎯 Examples

### Login Form

```dart
Form(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CommonText.displayMedium('Welcome Back'),
      SizedBox(height: AppConstants.spacingS),
      CommonText.bodyMedium('Sign in to continue'),
      SizedBox(height: AppConstants.spacingXl),
      
      CommonTextFormField.email(
        controller: _emailController,
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      SizedBox(height: AppConstants.spacingM),
      
      CommonTextFormField.password(
        controller: _passwordController,
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      SizedBox(height: AppConstants.spacingL),
      
      IOSButton(
        text: 'Sign In',
        onPressed: _handleLogin,
      ),
    ],
  ),
)
```

### Product Card

```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(AppConstants.spacingM),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonText.headline('Product Name'),
        SizedBox(height: AppConstants.spacingS),
        CommonText.bodyMedium('Product description goes here...'),
        SizedBox(height: AppConstants.spacingS),
        Row(
          children: [
            CommonText.primary('\$49.99', fontWeight: FontWeight.bold),
            Spacer(),
            CommonText.caption('2 days ago'),
          ],
        ),
      ],
    ),
  ),
)
```

---

**For more information, see:**
- `lib/core/typography.dart` - Typography constants
- `lib/core/constants.dart` - App constants
- `lib/widgets/common_text.dart` - CommonText widget
- `lib/widgets/common_text_form_field.dart` - CommonTextFormField widget

