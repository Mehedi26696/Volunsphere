<div align="center">
  <img src="frontend/screenshots/logo.jpg" alt="Volunsphere Logo" width="300"/>
</div>

# Volunsphere 🌟

A comprehensive volunteer management platform that connects volunteers with meaningful opportunities and helps organizations manage their volunteer programs effectively.
## 📑 Table of Contents

## 📑 Table of Contents

<details open>
  <summary><b>Expand Table of Contents</b></summary>
  <ul>
    <li><a href="#-project-overview">📱 Project Overview</a></li>
    <li><a href="#-key-app-screens">🎯 Key App Screens</a></li>
    <li><a href="#-features">✨ Features</a></li>
    <li><a href="#-sample-api-file-(flutter)">🗂️ Sample API File (Flutter)</a></li>
    <li><a href="#-prerequisites">📋 Prerequisites</a></li>
    <li><a href="#-installation-&-setup">🚀 Installation & Setup</a></li>
    <li><a href="#-download-apk">📦 Download APK</a></li>
    <li><a href="#-project-architecture">🏗️ Project Architecture</a></li>
    <li><a href="#-development">🔧 Development</a></li>
    <li><a href="#-security-features">🛡️ Security Features</a></li>
    <li><a href="#-performance-optimizations">📊 Performance Optimizations</a></li>
    <li><a href="#-contributing">🤝 Contributing</a></li>
    <li><a href="#-contributors">👥 Contributors</a></li>
    <li><a href="#-license">📄 License</a></li>
    <li><a href="#-support-&-documentation">🆘 Support & Documentation</a></li>
    <li><a href="#-future-roadmap">🎯 Future Roadmap</a></li>
  </ul>
</details>



---

## 📱 Project Overview

Volunsphere is a full-stack application consisting of:

- **Frontend**: Flutter mobile application with cross-platform support
- **Backend**: FastAPI REST API with modern Python stack
- **Database**: PostgreSQL with Redis for caching
- **Storage**: Supabase for file storage and additional services
- **Push Notifications**: Firebase Cloud Messaging (FCM) for real-time alerts
## 🎯 Key App Screens

<div align="center">
  <table>
    <tr>
      <td align="center" width="20%">
        <img src="frontend/screenshots/signin.png" alt="Sign In" width="100"/><br>
        <b>🔐 Sign In</b><br>
        <span style="font-size:13px;">Secure authentication with remember me option</span>
      </td>
      <td align="center" width="20%">
        <img src="frontend/screenshots/home.jpg" alt="Home Dashboard" width="100"/><br>
        <b>🏠 Home Dashboard</b><br>
        <span style="font-size:13px;">Volunteer statistics and opportunities</span>
      </td>
      <td align="center" width="20%">
        <img src="frontend/screenshots/events_page.png" alt="Events" width="100"/><br>
        <b>📅 Events</b><br>
        <span style="font-size:13px;">Browse and manage volunteer events</span>
      </td>
      <td align="center" width="20%">
        <img src="frontend/screenshots/leaderboard.png" alt="Leaderboard" width="100"/><br>
        <b>� Leaderboard</b><br>
        <span style="font-size:13px;">Track volunteer hours and achievements</span>
      </td>
      <td align="center" width="20%">
        <img src="frontend/screenshots/bot.jpg" alt="AI Agent" width="100"/><br>
        <b>🤖 AI Agent</b><br>
        <span style="font-size:13px;">Interact with AI for event insights</span>
      </td>
    </tr>
    <tr>
      <td align="center" width="20%">
        <img src="frontend/screenshots/profile.jpg" alt="Profile" width="100"/><br>
        <b>👤 Profile</b><br>
        <span style="font-size:13px;">User profile management, stats, achievements</span>
      </td>
      <td align="center" width="20%">
        <img src="frontend/screenshots/community.png" alt="Community" width="100"/><br>
        <b>🌐 Community</b><br>
        <span style="font-size:13px;">Social newsfeed for engagement and updates</span>
      </td>
      <td align="center" width="20%">
        <img src="frontend/screenshots/p24.jpg" alt="Event Details" width="100"/><br>
        <b>📝 Event Details</b><br>
        <span style="font-size:13px;">Detailed event info and actions</span>
      </td>
      <td align="center" width="20%">
        <img src="frontend/screenshots/chat.jpg" alt="Chat" width="100"/><br>
        <b>💬 Chat</b><br>
        <span style="font-size:13px;">Real-time messaging for events</span>
      </td>
      <td align="center" width="20%">
        <img src="frontend/screenshots/side_navbar.png" alt="Navigation" width="100"/><br>
        <b>📱 Navigation</b><br>
        <span style="font-size:13px;">Elegant side drawer, purple theme, animations</span>
      </td>
    </tr>
  </table>
</div>

---
## ✨ Features

### 👤 For Volunteers
- 🔐 **Secure Authentication** – JWT-based login/signup, guest mode
- 📅 **Event Management** – Browse, join, and track volunteer events
- 💬 **Real-Time Chat** – Communicate with volunteers and organizers
- 👤 **Profile Management** – Customize profiles, image upload
- 🏆 **Leaderboard** – Rank volunteers by achievements
- 🌐 **Community Feed** – Create posts, like, comment, engage
- 🎨 **Modern UI** – Purple-themed, smooth animations
- 📄 **Certification** – Download certificates after volunteering
- 🤖 **AI Agent** – Get event and volunteer insights via AI

### 🏢 For Organizations
- 🗓️ **Event Creation** – Organize/manage events, location mapping
- 👥 **Volunteer Management** – Track registrations, attendance
- 🌐 **Community Feed** – Share updates/posts with volunteers
- 📊 **Analytics** – Monitor engagement, event performance
- ⭐ **Rating System** – Rate volunteers after events

### ⚙️ Technical Features
- 🎨 **Modern Theme** – Purple gradient, glassmorphism effects
- ✉️ **Email Integration** – OTP verification for password changes
- 📝 **PDF Generation** – Create volunteer certificates
- 🔄 **Real-Time Updates** – WebSocket live chat & sync
- 🖼️ **Image Handling** – Upload, crop profile/event photos
- 🗺️ **Interactive Maps** – Google Maps for location selection
- 🔍 **Advanced Search** – Search events and volunteers
- 🤖 **AI Agent** – Automated chat service
- ⏰ **Automated Logout** – Redirect to login on session expiry
- 💾 **Saved Credentials** – Device remembers login for a period
- 🔔 **Push Notifications** – Via Firebase Cloud Messaging


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

# Firebase Admin SDK for FCM
firebase-admin==6.2.0

# Email & Communication
smtplib (built-in)
email-validator==2.1.0

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
```
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
- **GROQ API Access**: Valid API key for [GROQ](https://groq.com/) (for chatbot integration)

### Development Tools

- Git version control
- Postman/Fastapi Swagger Docs(for API testing)
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
SUPABASE_KEY=your-supabase-service_role-key

# Google Maps API
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# GROQ API KEY
GROQ_API_KEY = your-GROQ-api-key

# Environment
ENVIRONMENT=development

# Firebase Credentials

FIREBASE_CREDENTIALS_JSON = your-firbase-project-credentials-as-string
```

#### Database Setup

```bash
# Create database
createdb volunsphere

# Run migrations
alembic upgrade head

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

Create `lib/utils/api.dart`:
 
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


- ✅ **Android** - Full support with native features
- ✅ **iOS** - Full support with native features
- ✅ **Web** - Full support with responsive design

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
|
└── requirements.txt     # Python dependencies
```

### Frontend Architecture

```
frontend/
├── lib/
│   ├── main.dart                    # App entry point
│   |
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

### Frontend Development

- **Hot Reload**: Enabled automatically in development mode
- **Build for Development**:
  ```bash
  flutter run
  ```
- **Build for Production**:
  ```bash
  flutter build apk --release           # Android APK
  flutter build ios --release           # iOS
  flutter build web --release           # Web
  ```

## 🛡️ Security Features

- **JWT Authentication** with refresh tokens
- **Password Hashing** using bcrypt
- **Input Validation** with Pydantic
- **CORS Configuration** for web security
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

## 🆘 Support & Documentation

### Getting Help

- 📧 **Email Support**: contact@volunsphere.com

### Useful Links
- [Flutter Documentation](https://docs.flutter.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🎯 Future Roadmap

- [ ] **Advanced Analytics Dashboard** with charts and insights
- [ ] **Multi-language Support** (Bengali, Spanish, French)
- [ ] **Offline Mode** capabilities with data synchronization
- [ ] **Social Media Integration** (Facebook, Twitter, LinkedIn)
- [ ] **Advanced Search** with AI-powered recommendations
- [ ] **Gamification Features** with badges and achievements
- [ ] **Event Categories** and advanced filtering
- [ ] **Mobile App Widgets** for quick actions

---

<div align="center">

**Made with ❤️ for the volunteer community**

*Empowering communities through technology and volunteering*

[⬆ Back to Top](#volunsphere-) | [📑 Table of Contents](#-table-of-contents)

</div>
