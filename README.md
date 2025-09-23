# Photo Analyzer - iOS App

A Flutter app designed to analyze and manage photos on iOS devices, helping users identify and remove low-quality or unnecessary photos to free up storage space.

## Features

### 🎯 Core Functionality
- **Photo Analysis**: Automatically analyzes all photos on the device
- **Quality Assessment**: Uses multiple criteria to determine photo quality:
  - File size analysis
  - Resolution assessment
  - Aspect ratio evaluation
  - Quality scoring algorithm

### 📊 Analysis Levels
The app provides 3 levels of analysis filters:
- **Very Bad**: Only shows photos with the lowest quality scores
- **Bad**: Shows photos with low to very low quality scores
- **Standard**: Shows photos with standard quality and below

### 🖼️ Photo Management
- **Review System**: Users can review bad photos before deletion
- **Selective Deletion**: Choose specific photos to keep or delete
- **Bulk Operations**: Select all or clear all selections
- **Space Calculation**: Shows potential storage space that can be freed

### 🎨 User Interface
- **Modern Design**: Clean, iOS-native design with smooth animations
- **Responsive Layout**: Optimized for iPhone screens
- **Intuitive Navigation**: Easy-to-use interface with clear actions
- **Visual Feedback**: Progress indicators and status updates

## Screenshots

### Home Screen
- Welcome section with app description
- Photo statistics (total photos, bad photos count)
- Analysis level selector
- Action buttons for analysis and review

### Analysis Screen
- Progress indicator during photo analysis
- Results summary with statistics
- Space calculation display
- Quick action buttons

### Review Screen
- Grid view of bad photos with quality indicators
- Selection mode for choosing photos to delete
- Photo details modal with metadata
- Bulk selection controls

## Technical Details

### Architecture
- **State Management**: Provider pattern for app-wide state
- **Photo Access**: Uses `photo_manager` package for iOS photo library access
- **Permissions**: Handles photo library permissions gracefully
- **Image Processing**: Efficient thumbnail generation and display

### Dependencies
```yaml
photo_manager: ^2.8.1          # Photo library access
permission_handler: ^11.3.1     # Permission management
flutter_staggered_grid_view: ^0.7.0  # Photo grid layout
provider: ^6.1.2               # State management
image: ^4.1.7                  # Image processing
shared_preferences: ^2.2.2     # Local storage
path_provider: ^2.1.2          # File system access
uuid: ^4.3.3                   # Unique identifiers
```

## Setup Instructions

### Prerequisites
1. **Flutter SDK**: Install Flutter (version 3.35.2 or higher)
2. **Xcode**: Install Xcode from the App Store
3. **iOS Simulator**: Available through Xcode
4. **CocoaPods**: Install for iOS dependency management

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd photo_analyzer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **iOS Setup**
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Run the app**
   ```bash
   # For iOS Simulator
   flutter run
   
   # For physical iOS device
   flutter run --device-id <device-id>
   ```

### iOS Permissions

The app requires the following permissions (already configured in `Info.plist`):
- **Photo Library Access**: To read and analyze photos
- **Photo Library Add**: To manage photo deletion
- **Camera**: For potential future features
- **Microphone**: For video analysis (future feature)

## Usage Guide

### First Launch
1. Grant photo library permissions when prompted
2. The app will automatically load and analyze your photos
3. Default analysis level is set to "Very Bad"

### Analyzing Photos
1. Navigate to the Analysis screen
2. The app will process all photos automatically
3. View results and statistics
4. Choose to review bad photos or delete all

### Reviewing Photos
1. Tap "Review Bad Photos" from the analysis results
2. Browse through identified low-quality photos
3. Tap photos to view details
4. Use selection mode to choose photos for deletion
5. Confirm deletion to free up storage space

### Changing Analysis Level
1. On the home screen, select your preferred analysis level
2. Levels range from "Very Bad" (most aggressive) to "Standard"
3. Re-analyze photos to see different results

## Development

### Project Structure
```
lib/
├── main.dart              # App entry point
├── models/
│   └── photo_model.dart   # Photo data model
├── providers/
│   └── photo_provider.dart # State management
├── screens/
│   ├── home_screen.dart   # Main dashboard
│   ├── analysis_screen.dart # Photo analysis
│   └── review_screen.dart # Photo review
├── widgets/
│   ├── stat_card.dart     # Statistics display
│   ├── gradient_button.dart # Custom buttons
│   └── photo_grid.dart    # Photo grid layout
└── utils/
    └── constants.dart     # App constants and colors
```

### Key Components

#### PhotoProvider
- Manages app state and photo data
- Handles photo loading and analysis
- Manages user selections and deletions
- Provides permission handling

#### PhotoModel
- Represents individual photos
- Contains metadata and analysis results
- Provides utility methods for display

#### Analysis Algorithm
- File size evaluation
- Resolution quality assessment
- Aspect ratio analysis
- Quality scoring system

## Future Enhancements

### Planned Features
- **AI-Powered Analysis**: Machine learning for better photo quality assessment
- **Duplicate Detection**: Identify and remove duplicate photos
- **Cloud Integration**: Backup important photos before deletion
- **Batch Operations**: More advanced bulk management features
- **Photo Categories**: Organize photos by type (screenshots, selfies, etc.)
- **Storage Analytics**: Detailed storage usage breakdown

### Technical Improvements
- **Performance Optimization**: Faster photo processing
- **Memory Management**: Better handling of large photo libraries
- **Offline Support**: Work without internet connection
- **Dark Mode**: Support for iOS dark mode
- **Accessibility**: VoiceOver and accessibility improvements

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Go to Settings > Privacy & Security > Photos
   - Enable access for Photo Analyzer

2. **Photos Not Loading**
   - Check internet connection
   - Restart the app
   - Verify photo library permissions

3. **Analysis Not Working**
   - Ensure photos are accessible
   - Check device storage space
   - Restart the app

4. **Deletion Failed**
   - Verify photo permissions
   - Check if photos are in use by other apps
   - Try deleting fewer photos at once

### Debug Mode
```bash
flutter run --debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the documentation

---

**Note**: This app is designed specifically for iOS devices and requires proper photo library permissions to function. Always review photos before deletion as the process cannot be undone.
