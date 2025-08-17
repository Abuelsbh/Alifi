# Alifi - Pet Care Platform

Alifi is a comprehensive cross-platform mobile application designed to help pet owners in their daily lives. Built with Flutter, it provides veterinary consultations, pet supplies search, lost/found reports, adoption, breeding opportunities, and community connection — all in one app.

## Features

### 🏠 Home
- Quick navigation to all app features
- Latest community posts and updates
- Personalized dashboard for pet owners

### 🐾 Lost & Found Pets
- **Lost Pet Reports**: Post detailed ads with photos, location, and pet details
- **Found Pet Reports**: Report found pets with location and contact information
- **Location-based Filtering**: Find pets in your area
- **Search & Filter**: Filter by pet type, breed, and other criteria
- **Direct Communication**: Contact pet owners or finders directly

### 🩺 Veterinary Consultation
- **Real-time Chat**: Text, image, and video messaging with veterinarians
- **Veterinarian Directory**: Browse qualified veterinarians with ratings and reviews
- **Online Consultations**: Get professional advice without leaving home
- **Chat History**: Access previous conversations and medical advice

### 👤 User Profile & Pets
- **Pet Management**: Add and manage your pets' information
- **Vaccination Records**: Track your pets' vaccination history
- **Profile Management**: Update personal information and preferences
- **Report History**: View your lost/found pet reports

### 🎨 Design Features
- **Multi-language Support**: Arabic (RTL) and English (LTR)
- **Light & Dark Themes**: Toggle between light and dark modes
- **Responsive Design**: Optimized for phones and tablets
- **Modern UI**: Clean, intuitive interface with green and orange theme colors

## Technical Stack

### Frontend
- **Framework**: Flutter 3.5.3+
- **State Management**: Provider
- **Navigation**: Go Router
- **UI Components**: Custom widgets with Material Design 3
- **Responsive Design**: Flutter ScreenUtil

### Backend & Services
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (for images and media)
- **Push Notifications**: Firebase Cloud Messaging
- **Maps & Location**: Google Maps API, Geolocator

### Key Dependencies
```yaml
# Firebase
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
cloud_firestore: ^4.13.6
firebase_storage: ^11.5.6
firebase_messaging: ^14.7.10

# Maps & Location
google_maps_flutter: ^2.5.3
geolocator: ^10.1.0
geocoding: ^2.1.1

# UI & Media
image_picker: ^1.0.4
cached_network_image: ^3.3.0
flutter_screenutil: ^5.7.0
google_fonts: ^5.1.0

# State Management
provider: ^6.0.5
get_it: ^7.6.0
```

## Project Structure

```
lib/
├── core/
│   ├── firebase/          # Firebase configuration
│   ├── services/          # Business logic services
│   ├── Theme/            # App themes and styling
│   └── Language/         # Internationalization
├── Models/               # Data models
├── Modules/
│   ├── Main/            # Main app screens
│   │   ├── home/        # Home screen
│   │   ├── veterinary/  # Veterinary consultation
│   │   ├── lost_found/  # Lost & found pets
│   │   └── profile/     # User profile
│   └── Splash/          # Splash screen
├── Widgets/             # Reusable UI components
└── Utilities/           # Helper utilities
```

## Getting Started

### Prerequisites
- Flutter SDK 3.5.3 or higher
- Dart SDK 3.5.3 or higher
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd alifi
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and Cloud Messaging
   - Download and add the configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS

4. **Google Maps Setup**
   - Get a Google Maps API key
   - Add it to your Android and iOS configurations

5. **Run the app**
   ```bash
   flutter run
   ```

### Platform-specific Setup

#### Android
1. Add Google Maps API key to `android/app/src/main/AndroidManifest.xml`
2. Ensure minimum SDK version is 21 or higher

#### iOS
1. Add Google Maps API key to `ios/Runner/AppDelegate.swift`
2. Update iOS deployment target to 12.0 or higher

## Features Implementation

### Lost & Found System
- **Real-time Updates**: Posts are updated in real-time using Firestore
- **Location Services**: Automatic location detection and geocoding
- **Image Upload**: Secure image storage with Firebase Storage
- **Search & Filter**: Efficient querying with Firestore indexes

### Veterinary Chat
- **Real-time Messaging**: Live chat using Firestore real-time listeners
- **Media Support**: Send images and videos during consultations
- **Message Status**: Read receipts and typing indicators
- **Chat History**: Persistent conversation history

### User Management
- **Authentication**: Secure user registration and login
- **Profile Management**: Complete user profile with pet information
- **Data Persistence**: All user data stored securely in Firestore

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

## Roadmap

### Phase 1 (Current)
- ✅ Core lost & found functionality
- ✅ Veterinary chat system
- ✅ User profiles and pet management
- ✅ Basic UI/UX implementation

### Phase 2 (Planned)
- 🔄 Pet stores and supplies integration
- 🔄 Adoption and breeding features
- 🔄 Advanced search and filtering
- 🔄 Push notifications

### Phase 3 (Future)
- 📋 Community features and forums
- 📋 Pet health tracking
- 📋 Emergency veterinary services
- 📋 Pet insurance integration

---

**Alifi** - Making pet care easier, one paw at a time! 🐾
# Alifi
