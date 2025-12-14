
-keep class com.google.mlkit.** { *; }

# Giữ lại các thông tin Generic Signature để Gson hoạt động
-keepattributes Signature
-keepattributes *Annotation*

# Giữ lại thư viện Gson
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Giữ lại thư viện Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Nếu bạn dùng timezone
-keep class androidx.window.** { *; }