# ALIFI Authentication Screens

This document describes the new ALIFI authentication screens that have been created for the mobile app.

## Overview

Two new authentication screens have been built with a modern, pet-themed design:

1. **AlifiLoginScreen** - Login screen with email and password fields
2. **AlifiRegisterScreen** - Sign up screen with user name, email, phone, and password fields

## Design Features

### Visual Design
- **Centered Card Layout**: White rounded card with shadow elevation
- **Color Scheme**: 
  - Primary Orange: `#F47A1F`
  - Primary Green: `#3A6B35`
  - Light Gray Background: `#F5F5F5`
- **Pet Logo**: Custom cat and dog silhouette illustration
- **Paw Print Decorations**: Scattered around the card and form fields
- **Clean Typography**: Rounded, friendly font style

### Interactive Elements
- **Form Validation**: Email format, password length, required fields
- **Password Visibility Toggle**: Eye icon to show/hide password
- **Loading States**: Circular progress indicator during authentication
- **Navigation**: Seamless switching between login and sign up screens
- **Forgot Password**: Password reset functionality

## File Structure

```
lib/Modules/Auth/
├── alifi_login_screen.dart      # Login screen implementation
├── alifi_register_screen.dart   # Sign up screen implementation
└── alifi_auth_demo.dart         # Demo screen to showcase both screens
```

## Usage

### Basic Navigation
```dart
// Navigate to login screen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const AlifiLoginScreen(),
  ),
);

// Navigate to register screen
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const AlifiRegisterScreen(),
  ),
);
```

### Route Names
- Login Screen: `/alifi-login`
- Register Screen: `/alifi-register`

### Demo Screen
Use `AlifiAuthDemo` to showcase both authentication screens with navigation buttons.

## Features Implemented

### Login Screen
- ✅ "Welcome to ALIFI" title with orange accent
- ✅ Pet logo (cat & dog silhouette)
- ✅ Email and password text fields with orange borders
- ✅ Paw print decorations around form fields
- ✅ "Forgot Password?" clickable text
- ✅ Orange login button with white text
- ✅ "Sign Up" link at bottom
- ✅ Responsive layout with SingleChildScrollView
- ✅ flutter_screenutil for adaptive sizing

### Sign Up Screen
- ✅ "Welcome to ALIFI" title with orange accent
- ✅ Pet logo (cat & dog silhouette)
- ✅ Four text fields: User Name, Email, Phone Number, Password
- ✅ Paw print decorations around form fields
- ✅ Orange sign up button with white text
- ✅ "Login" link at bottom
- ✅ Responsive layout with SingleChildScrollView
- ✅ flutter_screenutil for adaptive sizing

### Technical Features
- ✅ Form validation for all fields
- ✅ Password visibility toggle
- ✅ Loading states with progress indicators
- ✅ Error handling with snackbar messages
- ✅ Firebase authentication integration
- ✅ Responsive design for different screen sizes
- ✅ Clean, lint-free code

## Dependencies

The screens use the following dependencies (already included in pubspec.yaml):
- `flutter_screenutil` - For responsive sizing
- `go_router` - For navigation
- `firebase_auth` - For authentication (via AuthService)

## Customization

### Colors
The color scheme can be easily modified by changing the constants at the top of each file:
```dart
static const Color primaryOrange = Color(0xFFF47A1F);
static const Color primaryGreen = Color(0xFF3A6B35);
static const Color lightGray = Color(0xFFF5F5F5);
```

### Paw Print Decorations
Paw prints are generated programmatically using the `_buildPawPrint()` method, allowing for easy customization of size, color, and positioning.

### Pet Logo
The pet logo is created using custom containers and positioned elements, making it easy to modify or replace with actual image assets.

## Testing

Both screens have been tested for:
- ✅ Flutter analysis (no linting issues)
- ✅ Responsive layout on different screen sizes
- ✅ Form validation
- ✅ Navigation between screens
- ✅ Authentication flow integration

## Future Enhancements

Potential improvements that could be added:
- Social login options (Google, Facebook)
- Biometric authentication
- Remember me functionality
- Terms and conditions checkbox
- Email verification flow
- Custom animations and transitions
