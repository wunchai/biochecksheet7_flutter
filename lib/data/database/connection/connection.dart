// lib/data/database/connection/connection.dart

// This file uses conditional exports to provide the 'connect' function.
// It ensures that only one 'connect' function (either from .web.dart or .native.dart)
// is exported based on the compilation platform.

export 'connection.native.dart' // This is the default or 'io' platform export
    if (dart.library.html) 'connection.web.dart'; // Override for web platform