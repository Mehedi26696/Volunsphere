# Volunsphere 🌟

A comprehensive volunteer management platform that connects volunteers with meaningful opportunities and helps organizations manage their volunteer programs effectively.

## 📱 Project Overview

Volunsphere is a full-stack application consisting of:
- **Frontend**: Flutter mobile application with cross-platform support
- **Backend**: FastAPI REST API with modern Python stack
- **Database**: PostgreSQL with Redis for caching
- **Storage**: Supabase for file storage and additional services

## ✨ Features

### For Volunteers
- 🔐 **User Authentication** - Secure login/signup with JWT tokens
- 📍 **Location-Based Events** - Find volunteer opportunities near you using Google Maps
- 📅 **Event Management** - Browse, join, and track volunteer events
- 💬 **Real-time Chat** - Communicate with other volunteers and organizers
- 👤 **Profile Management** - Customize your volunteer profile
- 🏆 **Leaderboard** - Track volunteer hours and achievements
- 📱 **Cross-Platform** - Available on Android, iOS, and Web

### For Organizations
- 📝 **Event Creation** - Create and manage volunteer events
- 👥 **Volunteer Management** - Track participant registrations and attendance
- 📊 **Community Feed** - Share updates and engage with volunteers
- 📈 **Analytics** - Monitor volunteer engagement and event success

### Technical Features
- 🌓 **Dark/Light Theme** - Customizable UI themes
- 📧 **Email Notifications** - Automated email communications
- 📄 **PDF Generation** - Generate certificates and reports
- 🔄 **Real-time Updates** - WebSocket connections for live chat
- 📱 **Phone Integration** - Direct calling functionality
- 🖼️ **Image Handling** - Photo upload and cropping capabilities

## 🛠️ Technology Stack

### Frontend (Flutter)
- **Flutter SDK** ^3.7.2
- **Dart** for cross-platform development
- **Provider** for state management
- **Google Maps** for location services
- **WebSocket** for real-time chat
- **Lottie** for animations
- **Image Picker & Cropper** for media handling

### Backend (FastAPI)
- **FastAPI** for REST API framework
- **SQLAlchemy** for ORM
- **Alembic** for database migrations
- **PostgreSQL** as primary database
- **Redis** for caching and sessions
- **JWT** for authentication
- **Supabase** for additional services
- **Python 3.9+** runtime

## 📋 Prerequisites

### System Requirements
- **Flutter SDK** 3.7.2 or higher
- **Python** 3.9 or higher
- **PostgreSQL** 12 or higher
- **Redis** server
- **Node.js** (for any additional tooling)

### Development Tools
- Android Studio / VS Code
- Git
- Postman (for API testing)

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
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
DATABASE_URL=postgresql://username:password@localhost:5432/volunsphere
JWT_SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256
REDIS_HOST=localhost
REDIS_PORT=6379
GMAIL_USER=your-email@gmail.com
GMAIL_PASSWORD=your-app-password
SUPABASE_URL=your-supabase-url
SUPABASE_KEY=your-supabase-key
```

#### Database Setup
```bash
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
Update the API base URL in your Flutter app configuration files to point to your backend server.

#### Run the Flutter app
```bash
flutter run

flutter run -d chrome
flutter run -d android
flutter run -d ios
```

## 📱 Platform Support

- ✅ **Android** - Full support
- ✅ **iOS** - Full support  
- ✅ **Web** - Full support
- ✅ **Windows** - Basic support
- ✅ **macOS** - Basic support
- ✅ **Linux** - Basic support

## 🔧 Development

### Backend Development
- API documentation available at: `http://localhost:8000/docs`
- Database migrations: `alembic revision --autogenerate -m "description"`
- Run tests: `pytest`

### Frontend Development
- Hot reload enabled in development mode
- Widget testing: `flutter test`
- Build for production: `flutter build <platform>`

### Project Structure
```
Volunsphere/
├── backend/
│   ├── src/
│   │   ├── auth/          # Authentication modules
│   │   ├── chat/          # Chat functionality
│   │   ├── community/     # Community features
│   │   ├── db/           # Database configuration
│   │   ├── events/       # Event management
│   │   ├── leaderboard/  # Leaderboard features
│   │   └── users/        # User management
│   ├── migrations/       # Database migrations
│   └── requirements.txt  # Python dependencies
└── frontend/
    ├── lib/
    │   ├── models/       # Data models
    │   ├── screens/      # UI screens
    │   ├── services/     # API services
    │   └── utils/        # Utility functions
    ├── assets/          # Images, fonts, animations
    └── pubspec.yaml     # Flutter dependencies
```



### Coding Standards
- Follow Flutter/Dart style guidelines
- Follow PEP 8 for Python code
- Write meaningful commit messages
- Include tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions:

1. Check the [Issues](../../issues) section
2. Create a new issue with detailed description
3. Contact the development team

## 🎯 Future Roadmap

- [ ] Push notifications
- [ ] Advanced analytics dashboard
- [ ] Integration with more mapping services
- [ ] Multi-language support
- [ ] Offline mode capabilities
- [ ] Social media integration
- [ ] Advanced search and filtering
- [ ] Event recommendation system

## 👥 Team

- **Frontend Development**: Flutter/Dart
- **Backend Development**: Python/FastAPI
- **Database Design**: PostgreSQL/Redis
- **UI/UX Design**: Material Design

---

**Made with ❤️ for the volunteer community**
