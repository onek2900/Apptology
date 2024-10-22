# Keep necessary classes for BouncyCastle, Conscrypt, and OpenJSSE
-keep class org.bouncycastle.** { *; }
-keep class org.conscrypt.** { *; }
-keep class org.openjsse.** { *; }

# Additional keep rules for OkHttp and its dependencies
-dontwarn okhttp3.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
