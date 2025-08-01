# Play Core 관련 규칙
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# OkHttp 관련 규칙
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn org.bouncycastle.**
-dontwarn okhttp3.internal.platform.**
-keepclassmembers class okhttp3.internal.platform.** { *; }

# 일반적인 Android 규칙
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Flutter 관련 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Kotlin 관련 규칙
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlinx.** { *; }

# Firebase 관련 규칙 (만약 사용중이라면)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; } 