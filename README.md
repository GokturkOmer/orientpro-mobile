# OrientPro

**Enterprise orientation & training platform** built with Flutter (frontend) and FastAPI (backend).

OrientPro helps organizations onboard new employees, deliver training content, track progress, and manage technical operations — all from a single platform.

## Features

- **Orientation & Training** — Route-based training modules, content management, progress tracking
- **Quiz System** — AI-generated quizzes with spaced repetition, scoring, retry mechanisms
- **Badge & Achievement** — Automated badge awarding, leaderboard, gamification
- **Certificate Generation** — PDF certificates upon route completion
- **AI Chatbot** — RAG-based assistant using uploaded documents (Gemini 2.5 Flash + ChromaDB)
- **SCADA Monitoring** — Real-time sensor data via Modbus TCP (5 units, 24 sensors)
- **Digital Twin** — 5-zone facility visualization with live sensor color coding
- **QR Tour System** — 3 routes, 18 checkpoints with mobile scanning
- **AI Fault Prediction** — Z-Score analysis, trend detection, health scoring
- **Equipment Management** — 284 equipment items, 9 categories, work orders with SLA
- **Admin Panel** — User management, RBAC (21 roles), content approval workflow
- **Maintenance Dashboard** — Docker service monitoring, Redis cache, DB optimization
- **Subscription & Payment** — iyzico integration, plan management, invoice history
- **Multi-language** — Turkish and English (i18n ready)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x (Web + Mobile), Dart |
| **State Management** | Riverpod 3.x (NotifierProvider) |
| **HTTP Client** | Dio 5.9.1 with auth interceptors |
| **Backend** | FastAPI (Python 3.12) |
| **Database** | PostgreSQL 16 (TimescaleDB) |
| **Cache** | Redis 7 |
| **AI/LLM** | Gemini 2.5 Flash (API) |
| **Embeddings** | nomic-embed-text (Ollama, local GPU) |
| **Vector DB** | ChromaDB |
| **Storage** | MinIO (S3-compatible) |
| **Auth** | JWT Bearer + refresh tokens |

## Project Structure

```
lib/
  core/
    auth/          # Role helpers, permission checks
    config/        # API configuration
    locale/        # i18n setup
    network/       # Dio client, auth interceptors
    storage/       # Secure token storage
    theme/         # SCADA dark/light theme system
    utils/         # Error handling, helpers
  l10n/            # Localization files (TR/EN)
  models/          # Data models (13 files)
  providers/       # Riverpod state management (14 providers)
  screens/         # UI screens organized by domain
    admin/         # Admin panel, maintenance, user management
    auth/          # Login, register, password reset, onboarding
    chatbot/       # AI assistant
    dashboard/     # Main dashboard
    digital_twin/  # Facility visualization
    equipment/     # Equipment list & details
    orientation/   # Training routes, modules, quizzes, badges
    scada/         # Sensor monitoring, alarms
    subscription/  # Plans & payments
    tour/          # QR inspection tours
    work_orders/   # Work order management
  widgets/         # Reusable UI components
  main.dart        # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK (included with Flutter)
- Backend server running (FastAPI)

### Installation

```bash
# Clone the repository
git clone https://github.com/GokturkOmer/orientpro-mobile.git
cd orientpro-mobile

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Android
flutter run -d android

# Build APK
flutter build apk --release
```

### Environment Configuration

The app uses build-time configuration for API URLs:

```bash
# Development (default: localhost:8000)
flutter run -d chrome

# Production
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

## Architecture

```
User Interaction
      |
  Screens (UI Layer)
      |
  Providers (State Management - Riverpod)
      |
  Auth Dio (Network Layer - Interceptors)
      |
  Backend API (FastAPI)
      |
  PostgreSQL / Redis / ChromaDB
```

- **State Management**: Riverpod 3.x with NotifierProvider pattern
- **Authentication**: JWT with automatic refresh, secure storage, auto-logout on 401
- **Theme**: Custom SCADA theme system with dark/light mode support
- **Localization**: Flutter intl with Turkish and English

## Security

- JWT tokens stored in encrypted secure storage
- Automatic token refresh with race condition protection
- RBAC with 21 roles and department-based filtering
- CORS environment-based configuration
- Rate limiting on sensitive endpoints
- IDOR protection with organization-level data isolation
- Input validation via Pydantic (backend) and form validators (frontend)

## License

This project is proprietary software. All rights reserved.

## Author

**Omer Gokturk** — [@GokturkOmer](https://github.com/GokturkOmer)
