# SmartBite - Food Tracking App

A Flutter-based food tracking application with a Django backend that helps users track their daily food intake and nutritional information.

## Project Structure

```
├── frontend/           # Flutter application
└── backend/           # Django backend server
```

## Prerequisites

- Flutter SDK (latest stable version)
- Python 3.11 or higher
- Git
- Android Studio / Xcode (for mobile development)
- A physical device or emulator for testing

## Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Create a virtual environment:
```bash
python -m venv venv
```

3. Activate the virtual environment:
- Windows:
```bash
venv\Scripts\activate
```
- macOS/Linux:
```bash
source venv/bin/activate
```

4. Install dependencies:
```bash
pip install -r requirements.txt
```

5. Apply database migrations:
```bash
python manage.py migrate
```

6. Run the development server:
```bash
python manage.py runserver
```

The backend server will run at `http://127.0.0.1:8000`

## Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Features

- User authentication
- Food search and tracking
- Camera-based food recognition (requires physical device)
- Daily calorie tracking
- Meal categorization (Breakfast, Lunch, Dinner, Snacks)
- Dark/Light theme support

## Testing on Physical Devices

1. Enable Developer Options on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings > System > Developer Options
   - Enable "USB Debugging"

2. Connect your device via USB and run:
```bash
flutter run
```

## Contributing

1. Fork the repository
2. Create a new branch for your feature
3. Commit your changes
4. Push to your branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 