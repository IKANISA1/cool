# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Google Generative AI
-keep class com.google.ai.** { *; }
-dontwarn com.google.ai.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# NFC Manager
-keep class io.flutter.plugins.nfc_manager.** { *; }

# QR Scanner
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep data classes for serialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Play Core (used by Flutter for deferred components, suppress warnings)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
