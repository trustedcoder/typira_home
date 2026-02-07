# Typira Mobile App

Typira is a mobile application built with **Flutter** that includes a custom keyboard extension (iOS/Android) to assist users with typing using AI.

## Prerequisites

Before running the project, ensure you have the following installed:

- **Flutter SDK** (Version 3.8.1 or higher recommended)
- **Dart SDK**
- **Xcode** (for iOS development)
- **Android Studio** (for Android development)
- **CocoaPods** (for iOS dependencies)

## Getting Started

1.  **Navigate to the mobile project directory:**
    ```bash
    cd mobile/typira
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the Application:**
    - To run on a connected device or emulator:
      ```bash
      flutter run
      ```

## Architecture & Tech Stack

- **Framework**: Flutter
- **State Management**: GetX
- **Keyboard Extension**: Native integrations for iOS (Swift) and Android (Kotlin)
- **Local Storage**: Shared Preferences / App Groups for sharing data between App and Keyboard.
- **Networking**: `http` package for API communication.
- **Firebase**: Integrated for Authentication, Analytics, and Messaging (FCM).

## Key Features

- **Custom Keyboard**: Replaces the system keyboard to provide smart typing features.
- **AI Integration**: Uses Gemini AI for text generation, correction, and analysis.
- **Insights**: Tracks typing speed, usage, and "time saved" metrics.

## iOS Specifics

Since Typira uses a custom keyboard extension, there are specific setups for iOS:
- **App Groups**: Ensure App Groups are correctly configured in Xcode capabilities to allow data sharing between the main app and the keyboard extension.
- **Pod Install**: If you encounter issues, try running `pod install` inside the `ios` folder.

## Troubleshooting

- **Build Errors**: If you encounter build errors related to dependencies, try `flutter clean` followed by `flutter pub get`.
- **Keyboard Not Showing**: On iOS, go to Settings -> Typira -> Keyboards and enable "Typira". Ensure "Allow Full Access" is toggled if required for AI features.
