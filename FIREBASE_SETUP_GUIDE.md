# Firebase Setup Guide for Photo Analyzer

## Prerequisites
1. Google account
2. Firebase CLI installed (`npm install -g firebase-tools`)
3. FlutterFire CLI installed (`dart pub global activate flutterfire_cli`)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `photo-analyzer-app` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click "Add app" and select iOS
2. Enter iOS bundle ID: `com.example.photoAnalyzer`
3. Enter app nickname: `Photo Analyzer iOS`
4. Download `GoogleService-Info.plist`
5. Place the file in `ios/Runner/` directory

## Step 3: Add Web App to Firebase (Optional)

1. In Firebase Console, click "Add app" and select Web
2. Enter app nickname: `Photo Analyzer Web`
3. Copy the Firebase config object

## Step 4: Enable Authentication

1. In Firebase Console, go to "Authentication" > "Sign-in method"
2. Enable "Google" sign-in provider
3. Add your support email
4. Save the changes

## Step 5: Configure FlutterFire

Run the following command in your project directory:
```bash
flutterfire configure
```

This will:
- Ask you to select your Firebase project
- Configure iOS and Android apps
- Update `firebase_options.dart` with real credentials

## Step 6: Update iOS Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Add `GoogleService-Info.plist` to the Runner target
3. Update `ios/Runner/Info.plist` with URL schemes:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## Step 7: Test the Setup

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `cd ios && pod install`
4. Run `flutter run` on your device

## Troubleshooting

### Common Issues:
1. **Build errors**: Make sure all Firebase dependencies are properly installed
2. **Authentication not working**: Check that Google sign-in is enabled in Firebase Console
3. **iOS build issues**: Ensure `GoogleService-Info.plist` is in the correct location

### Manual Configuration:
If FlutterFire CLI doesn't work, manually update `lib/firebase_options.dart` with your project credentials from Firebase Console.

## Security Notes:
- Never commit real Firebase credentials to public repositories
- Use environment variables for production apps
- Regularly rotate API keys
