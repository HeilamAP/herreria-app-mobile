# Reglas de R8 para la versión final (APK de release).
#
# shared_preferences y path_provider se llaman desde Dart por JNI (paquete jni): R8 no ve
# esas llamadas y borraba sus métodos. En la versión final la app no podía leer los datos
# guardados (empezaba vacía) ni guardar fotos. Se conservan completas.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
# Las llamadas JNI buscan los métodos por su firma exacta, que incluye tipos de Kotlin
# (kotlin.coroutines.Continuation, kotlin.Result...). Si R8 les cambia el nombre o los
# quita, la búsqueda falla (NoSuchMethodError / ClassNotFoundException): se conservan.
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
