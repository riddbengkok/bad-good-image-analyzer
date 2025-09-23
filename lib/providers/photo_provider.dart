// This file serves as a bridge between web and mobile implementations
// The actual implementation is in photo_provider_web.dart or photo_provider_mobile.dart

import 'package:flutter/foundation.dart';
import 'package:photo_analyzer/models/photo_model.dart';
import 'package:photo_analyzer/utils/constants.dart';

// Export the appropriate implementation based on platform
export 'photo_provider_mobile.dart' if (dart.library.html) 'photo_provider_web.dart';
