# SmartBite Frontend

A modern Flutter application for intelligent food management.

## Features

- Mobile scanner integration for food tracking
- Real-time food management
- User authentication
- Progress tracking with visual indicators
- Cross-platform support (iOS, Android, Web)

## Prerequisites

- Flutter SDK >=3.2.3
- Dart SDK >=3.0.0
- Android Studio / XCode for mobile development

## Setup Instructions

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Create necessary asset directories:
   ```bash
   mkdir -p assets/images assets/icons
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Environment Setup

Create a `.env` file in the root directory with the following variables:
```
API_BASE_URL=your_backend_url
```

## Project Structure

```
lib/
  ├── models/      # Data models
  ├── screens/     # UI screens
  ├── widgets/     # Reusable widgets
  ├── services/    # API services
  ├── utils/       # Helper functions
  └── main.dart    # Entry point
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
