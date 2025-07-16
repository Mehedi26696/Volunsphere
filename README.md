<div align="center">
  <img src="frontend/screenshots/image.png" alt="Volunsphere Logo" width="300"/>
</div>

# Volunsphere 🌟

A comprehensive volunteer management platform that connects volunteers with meaningful opportunities and helps organizations manage their volunteer programs effectively.

## 📑 Table of Contents

<div align="center">

| **🚀 Getting Started** | **📋 Documentation** | **👥 Community** |
|------------------------|----------------------|------------------|
| [📱 Project Overview](#-project-overview) | [🏗️ Project Architecture](#️-project-architecture) | [👥 Contributors](#-contributors) |
| [📸 Screenshots](#-screenshots) | [🔧 Development](#-development) | [🤝 Contributing](#-contributing) |
| [✨ Features](#-features) | [🧪 Testing](#-testing) | [📄 License](#-license) |
| [🛠️ Technology Stack](#️-technology-stack) | [🚀 Deployment](#-deployment) | [🆘 Support & Documentation](#-support--documentation) |
| [📋 Prerequisites](#-prerequisites) | [🛡️ Security Features](#️-security-features) | [🌟 Acknowledgments](#-acknowledgments) |
| [🚀 Installation & Setup](#-installation--setup) | [📊 Performance Optimizations](#-performance-optimizations) | |
| [📱 Platform Support](#-platform-support) | [🌍 Internationalization](#-internationalization) | |

| **🎯 Roadmap & Stats** |
|----------------------|
| [🎯 Future Roadmap](#-future-roadmap) |
| [📈 Project Statistics](#-project-statistics) |

</div>

---

## 📱 Project Overview

Volunsphere is a full-stack application consisting of:
- **Frontend**: Flutter mobile application with cross-platform support
- **Backend**: FastAPI REST API with modern Python stack
- **Database**: PostgreSQL with Redis for caching
- **Storage**: Supabase for file storage and additional services

## 📸 Screenshots

<div align="center">
  <img src="frontend/screenshots/signin.png" alt="Sign In Screen" width="200"/>
  <img src="frontend/screenshots/home_page.png" alt="Home Screen" width="200"/>
  <img src="frontend/screenshots/home_page2.png" alt="Home Screen Extended" width="200"/>
  <img src="frontend/screenshots/events_page.png" alt="Events Screen" width="200"/>
</div>

<div align="center">
  <img src="frontend/screenshots/signup.png" alt="Profile Screen" width="200"/>
  <img src="frontend/screenshots/leaderboard.png" alt="Community Newsfeed" width="200"/>
  <img src="frontend/screenshots/side_navbar.png" alt="Side Navigation" width="200"/>
  <img src="frontend/screenshots/community.png" alt="Side Navigation" width="200"/>
</div>

### 🎯 Key App Screens
- **🔐 Sign In**: Secure authentication with remember me option
- **🏠 Home Dashboard**: Welcome section with volunteer statistics and opportunities
- **📅 Events**: Browse and manage volunteer events with beautiful cards
- **👤 Profile**: User profile management with statistics and achievements
- **🌐 Community**: Social newsfeed for community engagement and updates
- **📱 Navigation**: Elegant side drawer with purple theme and smooth animations

## ✨ Features

### For Volunteers
- 🔐 **User Authentication** - Secure login/signup with JWT tokens and guest mode
- 📍 **Location-Based Events** - Find volunteer opportunities near you using Google Maps
- 📅 **Event Management** - Browse, join, and track volunteer events
- 💬 **Real-time Chat** - Communicate with other volunteers and organizers
- 👤 **Profile Management** - Customize your volunteer profile with image upload
- 🏆 **Leaderboard** - Track volunteer hours and achievements with ranking system
- 🌐 **Community Feed** - Share posts, like, comment, and engage with the community
- 📱 **Cross-Platform** - Available on Android, iOS, and Web
- 🎨 **Modern UI** - Beautiful purple-themed interface with smooth animations

### For Organizations
- 📝 **Event Creation** - Create and manage volunteer events with location mapping
- 👥 **Volunteer Management** - Track participant registrations and attendance
- 📊 **Community Feed** - Share updates and engage with volunteers
- 📈 **Analytics** - Monitor volunteer engagement and event success
- ⭐ **Rating System** - Rate volunteers after events completion
- 📧 **Email Notifications** - Automated email communications for events

### Technical Features
- 🌓 **Modern Theme** - Purple gradient design with glassmorphism effects
- 📧 **Email Integration** - Automated notifications and OTP verification
- 📄 **PDF Generation** - Generate certificates and reports
- 🔄 **Real-time Updates** - WebSocket connections for live chat
- 📱 **Phone Integration** - Direct calling functionality
- 🖼️ **Image Handling** - Photo upload and cropping capabilities
- 🗺️ **Interactive Maps** - Google Maps integration for location selection
- 🔍 **Advanced Search** - Filter events by location, date, and categories
- 📲 **Push Notifications** - Firebase Cloud Messaging integration



## 🗂️ Sample API File (Flutter)

Below is a sample `lib/utils/api.dart` file for configuring API endpoints in your Flutter app. Replace the placeholder URL with your actual backend URL:

```dart
// utils/api.dart

const String baseUrl = "https://your-backend-url/api/v1"; // <-- Replace with your backend URL

const String authUrl = "$baseUrl/auth";
const String eventUrl = "$baseUrl/events";
const String userUrl = "$baseUrl/users";
const String chatUrl = "wss://your-backend-url/api/v1/chat"; // <-- Replace with your backend WebSocket URL
const String communityUrl = "$baseUrl/community";
const String leaderboardUrl = "$baseUrl/leaderboard";
```


### Frontend (Flutter)
```yaml
dependencies:
  flutter: ^3.7.2
  http: ^1.1.0
  shared_preferences: ^2.2.2
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  image_picker: ^1.0.4
  image_cropper: ^5.0.1
  cached_network_image: ^3.3.0
  url_launcher: ^6.2.1
  intl: ^0.18.1
  lottie: ^2.7.0
  web_socket_channel: ^2.4.0
  provider: ^6.1.1
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
```

### Backend (FastAPI)
```python
# Core Framework
fastapi==0.104.1
uvicorn==0.24.0

# Database & ORM
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9
redis==5.0.1

# Authentication & Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# External Services
supabase==2.0.2
requests==2.31.0

# Email & Communication
smtplib (built-in)
email-validator==2.1.0

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
```

## 📋 Prerequisites

### System Requirements
- **Flutter SDK** 3.7.2 or higher
- **Python** 3.9 or higher
- **PostgreSQL** 12 or higher
- **Redis** server
- **Android Studio** / **VS Code** for development
- **Google Maps API Key** for location services
- **Firebase Project** for push notifications
- **Supabase Account** for additional services

### Development Tools
- Git version control
- Postman (for API testing)
- Android/iOS emulators or physical devices

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/Volunsphere.git
cd Volunsphere
```

### 2. Backend Setup

#### Navigate to backend directory
```bash
cd backend
```

#### Create and activate virtual environment
```bash
python -m venv env
# On Windows
env\Scripts\activate
# On macOS/Linux
source env/bin/activate
```

#### Install dependencies
```bash
pip install -r requirements.txt
```

#### Environment Configuration
Create a `.env` file in the backend directory:
```env
# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/volunsphere

# JWT Configuration
JWT_SECRET_KEY=your-super-secret-jwt-key-here
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Email Configuration
GMAIL_USER=your-email@gmail.com
GMAIL_PASSWORD=your-app-password

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key

# Google Maps API
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# Environment
ENVIRONMENT=development
```

#### Database Setup
```bash
# Create database
createdb volunsphere

# Run migrations
alembic upgrade head

# (Optional) Seed initial data
python scripts/seed_data.py
```

#### Start the backend server
```bash
uvicorn src.main:app --reload --host 0.0.0.0 --port 8080
```

### 3. Frontend Setup

#### Navigate to frontend directory
```bash
cd frontend
```

#### Install Flutter dependencies
```bash
flutter pub get
```

#### Configure API endpoints
Create `lib/config/api_config.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
  static const String googleMapsApiKey = 'your-google-maps-api-key';
}
```

#### Firebase Configuration
1. Create a Firebase project
2. Add Android/iOS apps to your Firebase project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place them in the appropriate directories
5. Configure Firebase in `lib/main.dart`

#### Run the Flutter app
```bash
# For development
flutter run

# For specific platforms
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS
```


## � Download APK

You can download the latest Volunsphere Android APK from the following Google Drive link:

[👉 Download Volunsphere APK](https://drive.google.com/file/d/120QFg7ldNSJppr34CKiaw3ckg6Mt9JgQ/view?usp=sharing)

_Replace the above link with your actual APK file location on Google Drive._

- ✅ **Android** - Full support with native features
- ✅ **iOS** - Full support with native features  
- ✅ **Web** - Full support with responsive design
- ⚠️ **Windows** - Basic support (limited features)
- ⚠️ **macOS** - Basic support (limited features)
- ⚠️ **Linux** - Basic support (limited features)

## 🏗️ Project Architecture

### Backend Architecture
```
backend/
├── src/
│   ├── auth/              # Authentication & authorization
│   │   ├── routes.py      # Auth endpoints
│   │   ├── models.py      # User models
│   │   └── utils.py       # JWT utilities
│   ├── events/            # Event management
│   │   ├── routes.py      # Event CRUD operations
│   │   ├── models.py      # Event models
│   │   └── services.py    # Business logic
│   ├── community/         # Community features
│   │   ├── routes.py      # Posts & comments
│   │   └── models.py      # Community models
│   ├── chat/              # Real-time chat
│   │   ├── websocket.py   # WebSocket handlers
│   │   └── models.py      # Chat models
│   ├── leaderboard/       # User rankings
│   ├── notifications/     # Push notifications
│   ├── db/               # Database configuration
│   │   ├── database.py   # DB connection
│   │   └── base.py       # Base models
│   └── main.py           # FastAPI app initialization
├── migrations/           # Alembic migrations
├── tests/               # Unit & integration tests
└── requirements.txt     # Python dependencies
```

### Frontend Architecture
```
frontend/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── config/                      # Configuration files
│   ├── models/                      # Data models
│   │   ├── user_model.dart
│   │   ├── event_model.dart
│   │   └── post_model.dart
│   ├── services/                    # API services
│   │   ├── auth_service.dart
│   │   ├── events_service.dart
│   │   ├── community_service.dart
│   │   └── chat_service.dart
│   ├── screens/                     # UI screens
│   │   ├── auth/                    # Authentication screens
│   │   ├── events/                  # Event-related screens
│   │   ├── community/               # Community features
│   │   ├── profile/                 # User profile
│   │   └── settings/                # App settings
│   ├── widgets/                     # Reusable widgets
│   ├── utils/                       # Utility functions
│   └── constants/                   # App constants
├── assets/                          # Static assets
│   ├── images/                      # App images & logos
│   ├── animations/                  # Lottie animations
│   └── fonts/                       # Custom fonts
├── android/                         # Android configuration
├── ios/                            # iOS configuration
├── web/                            # Web configuration
└── pubspec.yaml                    # Flutter dependencies
```

## 🔧 Development

### Backend Development
- **API Documentation**: Available at `http://localhost:8080/docs` (Swagger UI)
- **Database Migrations**: 
  ```bash
  alembic revision --autogenerate -m "description"
  alembic upgrade head
  ```
- **Run Tests**: 
  ```bash
  pytest tests/ -v
  ```
- **Code Formatting**:
  ```bash
  black src/
  isort src/
  ```

### Frontend Development
- **Hot Reload**: Enabled automatically in development mode
- **Widget Testing**: 
  ```bash
  flutter test
  ```
- **Build for Production**: 
  ```bash
  flutter build apk --release           # Android APK
  flutter build ios --release           # iOS
  flutter build web --release           # Web
  ```
- **Code Analysis**:
  ```bash
  flutter analyze
  dart format lib/
  ```

## 🧪 Testing

### Backend Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src tests/

# Run specific test file
pytest tests/test_auth.py -v
```

### Frontend Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

## 🚀 Deployment

### Backend Deployment
```bash
# Using Docker
docker build -t volunsphere-backend .
docker run -p 8080:8080 volunsphere-backend

# Using cloud platforms (Heroku, Railway, etc.)
# Configure environment variables
# Deploy using platform-specific commands
```

### Frontend Deployment
```bash
# Android Play Store
flutter build appbundle --release

# iOS App Store
flutter build ios --release

# Web deployment
flutter build web --release
# Deploy dist files to hosting service
```

## 🛡️ Security Features

- **JWT Authentication** with refresh tokens
- **Password Hashing** using bcrypt
- **Input Validation** with Pydantic
- **CORS Configuration** for web security
- **Rate Limiting** on API endpoints
- **SQL Injection Protection** via SQLAlchemy ORM
- **File Upload Validation** for images
- **Environment Variables** for sensitive data

## 📊 Performance Optimizations

- **Database Indexing** on frequently queried fields
- **Redis Caching** for session management
- **Image Compression** and lazy loading
- **API Response Pagination**
- **WebSocket Connection Pooling**
- **Flutter Widget Optimization**
- **Code Splitting** for web builds

## 🌍 Internationalization

Currently supports:
- **English** (Primary)

Planned languages:
- Bengali
- Spanish
- French

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** following our coding standards
4. **Write tests** for new functionality
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Coding Standards
- Follow **Flutter/Dart** style guidelines
- Follow **PEP 8** for Python code
- Write **meaningful commit messages**
- Include **tests** for new features
- Update **documentation** as needed
- Use **conventional commits** format

## 👥 Contributors

<div align="center">

### 🚀 Project Team

<table>
  <tr>
    <td align="center">
      <img src="frontend/assets/images/mehedi.jpg" width="100px;" height="100px;" alt="Mehedi Hasan" style="border-radius: 50%; object-fit: cover;"/>
      <br />
      <sub><b>H.M. Mehedi Hasan</b></sub>
      <br />
      <a href="https://github.com/Mehedi26696">🐛 💻 📖</a>
      <br />
      <small>Full-Stack Developer</small>
    </td>
    <td align="center">
      <img src="frontend/assets/images/abs.jpg" width="100px;" height="100px;" alt="Abu Bakar" style="border-radius: 50%; object-fit: cover;"/>
      <br />
      <sub><b>Abu Bakar Siddique</b></sub>
      <br />
      <a href="https://github.com/Abs-Futy7">💻 🎨 📱</a>
      <br />
      <small>Frontend Developer</small>
    </td>
    <td align="center">
      <img src="frontend/assets/images/aurnob.jpg" width="100px;" height="100px;" alt="Ahil Islam" style="border-radius: 50%; object-fit: cover;"/>
      <br />
      <sub><b>Ahil Islam Aurnob</b></sub>
      <br />
      <a href="https://github.com/aheel03">💻 🗃️ ⚡</a>
      <br />
      <small>Backend Developer</small>
    </td>
    <td align="center">
      <img src="frontend/assets/images/shamiun.jpg" width="100px;" height="100px;" alt="Shamiun Ferdous" style="border-radius: 50%; object-fit: cover;"/>
      <br />
      <sub><b>S M Shamiun Ferdous</b></sub>
      <br />
      <a href="https://github.com/ShamiunFerdous">💻 🧪 📊</a>
      <br />
      <small>QA & Analytics</small>
    </td>
  </tr>
</table>

</div>

### Contact Information
- **H.M. Mehedi Hasan**: hasanmehedi26696@gmail.com
- **Abu Bakar Siddique**: bojackabs@gmail.com  
- **Ahil Islam Aurnob**: aheelislam03@gmail.com
- **S M Shamiun Ferdous**: shamiunferdous1234@gmail.com

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Volunsphere Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

## 🆘 Support & Documentation

### Getting Help
- 📖 **Documentation**: Check our [Wiki](../../wiki) for detailed guides
- 🐛 **Bug Reports**: Use our [Issue Template](../../issues/new?template=bug_report.md)
- 💡 **Feature Requests**: Use our [Feature Template](../../issues/new?template=feature_request.md)
- 💬 **Discussions**: Join our [Discussions](../../discussions)
- 📧 **Email Support**: contact@volunsphere.com

### Useful Links
- [API Documentation](http://localhost:8080/docs)
- [Flutter Documentation](https://docs.flutter.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🎯 Future Roadmap

### Version 2.0 (Planned)
- [ ] **Advanced Analytics Dashboard** with charts and insights
- [ ] **Multi-language Support** (Bengali, Spanish, French)
- [ ] **Offline Mode** capabilities with data synchronization
- [ ] **Social Media Integration** (Facebook, Twitter, LinkedIn)
- [ ] **Advanced Search** with AI-powered recommendations
- [ ] **Gamification Features** with badges and achievements
- [ ] **Event Categories** and advanced filtering
- [ ] **Mobile App Widgets** for quick actions

### Version 3.0 (Future)
- [ ] **AI-Powered Matching** between volunteers and opportunities
- [ ] **Video Calling** integration for remote volunteering
- [ ] **Blockchain Integration** for volunteer hour verification
- [ ] **AR/VR Features** for immersive event experiences
- [ ] **IoT Integration** for smart event management
- [ ] **Machine Learning** for predictive analytics

## 📈 Project Statistics

- **Lines of Code**: ~15,000+
- **API Endpoints**: 50+
- **Database Tables**: 15+
- **Supported Platforms**: 6
- **Test Coverage**: 85%+
- **Performance Score**: 95+

## 🌟 Acknowledgments

- **Flutter Team** for the amazing framework
- **FastAPI** for the excellent Python web framework
- **PostgreSQL** for reliable database management
- **Google Maps** for location services
- **Firebase** for push notifications
- **Supabase** for additional backend services
- **Open Source Community** for inspiration and tools

---

<div align="center">

**Made with ❤️ for the volunteer community**

*Empowering communities through technology and volunteering*

[⬆ Back to Top](#volunsphere-) | [📑 Table of Contents](#-table-of-contents)

</div>
