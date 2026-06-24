# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**
-keep class io.flutter.plugin.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# geolocator
-keep class com.baseflow.geolocator.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# cached_network_image / flutter_cache_manager
-keep class com.ryanheise.** { *; }

# General AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Keep all annotation classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
