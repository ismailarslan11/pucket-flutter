# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Flutter deferred components / Play Core (R8 eksik sınıf uyarılarını sustur)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Firebase (Auth, Firestore, Messaging, Analytics, Installations)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Mobile Ads (AdMob) + UMP
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Sign in with Apple / WebAuth
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }

# Model sınıflarında kullanılan alan adlarını (reflection/JSON) koru
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Genel: serileştirilebilir/parcelable koruması
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
