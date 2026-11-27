# Fix room-runtime 2.5.0 & work-runtime 2.9.0 consumer rules for R8 fullMode (AGP 8+/9+)
# Preserves only the no-arg constructors needed for Class.forName().newInstance()
# while allowing R8 to obfuscate and shrink all other DEX code (>25% Play Store threshold).
-keep class * extends androidx.room.RoomDatabase {
    void <init>();
}
-keep class * extends androidx.work.InputMerger {
    void <init>();
}
