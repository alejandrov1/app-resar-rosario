# ML Kit referencia modelos de idiomas opcionales que la app no incluye.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit crea sus registradores por reflexión: sin el constructor, el lector falla en release.
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
