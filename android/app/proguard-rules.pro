# Flutter Local Notifications - Preserve generic signatures
-keepattributes Signature
-keepattributes *Annotation*

# Keep all classes related to flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Keep TypeToken classes
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Preserve generic information for GSON
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Keep notification related classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Flutter Local Notifications specific rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep all enum classes
-keepclassmembers enum * { *; }

# Prevent obfuscation of notification classes
-keep class * extends android.app.NotificationManager { *; }
-keep class * extends androidx.core.app.NotificationManagerCompat { *; } 