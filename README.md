# 🐾 Alifi - Pet Care Platform

<div align="center">
  <img src="assets/images/logo.png" alt="Alifi Logo" width="200"/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.5.3-blue.svg)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## 📱 Overview

**Alifi** is a comprehensive pet care platform that connects pet owners with veterinary services and helps reunite lost pets with their families. Built with Flutter and Firebase, it provides a modern, responsive, and user-friendly experience.

## ✨ Features

### 🏠 Home Dashboard
- **Welcome Screen**: Beautiful animated splash screen with gradient backgrounds
- **Quick Actions**: Easy access to main features
- **Statistics**: Real-time pet and veterinarian statistics
- **Recent Activities**: Latest updates and notifications
- **Featured Services**: Emergency care, grooming, and vaccination services

### 🐕 Lost & Found Pets
- **Report Lost Pets**: Upload photos and details of missing pets
- **Report Found Pets**: Help reunite found pets with owners
- **Search & Filter**: Advanced search by type, breed, and location
- **Real-time Updates**: Instant notifications for matches
- **Location-based Search**: Find pets in your area

### 🏥 Veterinary Services
- **Chat with Veterinarians**: Real-time messaging with certified vets
- **Online Consultations**: Get expert advice from anywhere
- **Emergency Care**: 24/7 emergency veterinary support
- **Appointment Booking**: Schedule in-person consultations
- **Medical Records**: Store and manage pet health information

### 👤 User Profile
- **Pet Management**: Add and manage multiple pets
- **Report History**: Track all your lost/found pet reports
- **Settings**: Customize app preferences and notifications
- **Multi-language Support**: English and Arabic
- **Dark/Light Theme**: Choose your preferred theme

## 🛠 Technology Stack

### Frontend
- **Flutter 3.5.3**: Cross-platform mobile development
- **Dart**: Programming language
- **Provider**: State management
- **Go Router**: Navigation and routing
- **Flutter ScreenUtil**: Responsive design
- **Google Fonts**: Typography
- **Lottie**: Animations

### Backend & Services
- **Firebase Authentication**: User management and security
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: File and image storage
- **Firebase Messaging**: Push notifications
- **Google Maps**: Location services
- **Image Picker**: Camera and gallery integration

### UI/UX
- **Material Design 3**: Modern design system
- **Custom Animations**: Smooth transitions and effects
- **Responsive Layout**: Works on all screen sizes
- **Accessibility**: Support for users with disabilities
- **Internationalization**: Multi-language support

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.5.3 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/alifi-pet-care.git
   cd alifi-pet-care
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and Messaging
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Update Firebase configuration in `lib/core/firebase/firebase_options.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

1. **Authentication**
   - Enable Email/Password authentication
   - Configure password reset emails

2. **Firestore Database**
   - Create collections: `users`, `lost_pets`, `found_pets`, `veterinary_chats`, `veterinarians`
   - Set up security rules

3. **Storage**
   - Create folders: `pet_reports`, `chat_images`, `user_avatars`
   - Configure storage rules

4. **Messaging**
   - Set up FCM for push notifications
   - Configure notification channels

## 📁 Project Structure

```
lib/
├── core/
│   ├── firebase/           # Firebase configuration
│   ├── Font/              # Font management
│   ├── Language/          # Internationalization
│   ├── network/           # Network utilities
│   ├── services/          # Business logic services
│   └── Theme/             # App theming
├── generated/             # Generated files
├── Models/                # Data models
├── Modules/               # Feature modules
│   ├── Main/             # Main app screens
│   └── Splash/           # Splash screen
├── Utilities/            # Utility classes
├── Widgets/              # Reusable widgets
└── main.dart             # App entry point
```

## 🎨 Design System

### Colors
- **Primary Green**: `#4CAF50` - Main brand color
- **Primary Orange**: `#FF9800` - Secondary brand color
- **Success**: `#4CAF50` - Success states
- **Warning**: `#FF9800` - Warning states
- **Error**: `#F44336` - Error states
- **Info**: `#2196F3` - Information states

### Typography
- **Font Family**: Poppins (Google Fonts)
- **Headings**: Bold weights for hierarchy
- **Body Text**: Regular weight for readability
- **Captions**: Light weight for secondary information

### Components
- **Cards**: Rounded corners with subtle shadows
- **Buttons**: Material Design 3 style with animations
- **Input Fields**: Clean design with focus states
- **Navigation**: Custom bottom navigation with animations

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
GOOGLE_MAPS_API_KEY=your_maps_api_key
```

### Build Configuration

#### Android
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

#### iOS
```swift
// Minimum iOS version: 12.0
// Target iOS version: 17.0
```

## 📱 Screenshots

<div align="center">
  <img src="screenshots/home.png" alt="Home Screen" width="200"/>
  <img src="screenshots/lost_found.png" alt="Lost & Found" width="200"/>
  <img src="screenshots/veterinary.png" alt="Veterinary" width="200"/>
  <img src="screenshots/profile.png" alt="Profile" width="200"/>
</div>

## 🧪 Testing

Run tests with:
```bash
flutter test
```

### Test Coverage
- Unit tests for services
- Widget tests for UI components
- Integration tests for user flows

## 📦 Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🔒 Security

- **Authentication**: Firebase Auth with email/password
- **Data Validation**: Input sanitization and validation
- **File Upload**: Secure file upload with size limits
- **API Security**: Firebase security rules
- **Privacy**: GDPR compliant data handling

## 🌐 Internationalization

The app supports multiple languages:
- **English** (en)
- **Arabic** (ar)

To add a new language:
1. Create translation file in `i18n/`
2. Add language to `lib/core/Language/app_languages.dart`
3. Update locale configuration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing framework
- **Firebase Team**: For the powerful backend services
- **Material Design**: For the design system
- **Open Source Community**: For the libraries and tools

## 📞 Support

- **Email**: support@alifi.com
- **Website**: https://alifi.com
- **Documentation**: https://docs.alifi.com
- **Issues**: [GitHub Issues](https://github.com/yourusername/alifi-pet-care/issues)

## 🚀 Roadmap

### Version 2.0
- [ ] Pet health tracking
- [ ] Vaccination reminders
- [ ] Pet insurance integration
- [ ] Emergency SOS feature
- [ ] Pet community forum

### Version 3.0
- [ ] AI-powered pet recognition
- [ ] Virtual vet consultations
- [ ] Pet training videos
- [ ] Pet marketplace
- [ ] Pet sitting services

---

<div align="center">
  Made with ❤️ for pet lovers everywhere
  
  [Download on App Store](#) | [Get it on Google Play](#)
</div>
