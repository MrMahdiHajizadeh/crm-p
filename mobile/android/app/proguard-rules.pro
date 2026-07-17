# Keep url_launcher API class used by the plugin
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# Keep all Flutter plugin classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep all Flutter embedding classes
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**
