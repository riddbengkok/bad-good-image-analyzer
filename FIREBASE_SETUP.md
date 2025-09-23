# Firebase Authentication Setup Guide

## Overview
This guide will help you set up Firebase Authentication with Google Sign-In for your Photo Analyzer app.

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter a project name (e.g., "photo-analyzer-app")
4. Choose whether to enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Enable Authentication

1. In your Firebase project, go to "Authentication" in the left sidebar
2. Click "Get started"
3. Go to the "Sign-in method" tab
4. Click on "Google" provider
5. Enable Google Sign-In by toggling the switch
6. Add your support email
7. Click "Save"

## Step 3: Configure Web App

1. In your Firebase project, click the gear icon next to "Project Overview"
2. Select "Project settings"
3. Scroll down to "Your apps" section
4. Click the web icon (</>) to add a web app
5. Enter an app nickname (e.g., "Photo Analyzer Web")
6. Check "Also set up Firebase Hosting" if you want to deploy to Firebase Hosting
7. Click "Register app"
8. Copy the Firebase configuration object

## Step 4: Update Firebase Configuration

1. Open `lib/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase configuration:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-actual-api-key',
  appId: 'your-actual-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  authDomain: 'your-actual-project-id.firebaseapp.com',
  storageBucket: 'your-actual-project-id.appspot.com',
  measurementId: 'your-actual-measurement-id',
);
```

## Step 5: Configure Google Sign-In for Web

1. In your Firebase project, go to "Authentication" > "Sign-in method"
2. Click on "Google" provider
3. Add your authorized domains:
   - For development: `localhost`
   - For production: your actual domain
4. Click "Save"

## Step 6: Test the Setup

1. Run the app in development mode:
   ```bash
   flutter run -d chrome
   ```

2. The app should now show a login screen with "Continue with Google" button
3. Click the button to test Google Sign-In

## Troubleshooting

### Common Issues:

1. **"popup_closed_by_user" error**
   - Make sure you're running on `localhost` or an authorized domain
   - Check that popup blockers are disabled

2. **"invalid_client" error**
   - Verify your Firebase configuration is correct
   - Make sure Google Sign-In is enabled in Firebase Console

3. **"network_error" error**
   - Check your internet connection
   - Verify Firebase project is active

### Debug Steps:

1. Check browser console for error messages
2. Verify Firebase configuration values
3. Ensure all dependencies are installed: `flutter pub get`
4. Clear browser cache and cookies
5. Try incognito/private browsing mode

## Security Considerations

1. **API Key Security**: The web API key is safe to expose in client-side code
2. **Domain Restrictions**: Always configure authorized domains in Firebase Console
3. **User Data**: Implement proper data validation and sanitization
4. **Privacy Policy**: Ensure you have a privacy policy for user data handling

## Production Deployment

When deploying to production:

1. Update authorized domains in Firebase Console
2. Configure proper CORS settings
3. Set up Firebase Hosting (optional)
4. Enable HTTPS (required for production)
5. Update Firebase configuration for production domain

## Additional Features

You can extend the authentication system with:

- Email/Password authentication
- Phone number authentication
- Anonymous authentication
- Custom authentication providers
- User profile management
- Role-based access control

## Support

If you encounter issues:

1. Check [Firebase Documentation](https://firebase.google.com/docs)
2. Review [FlutterFire Documentation](https://firebase.flutter.dev/)
3. Check [Firebase Console](https://console.firebase.google.com/) for project status
4. Verify all configuration steps are completed correctly
