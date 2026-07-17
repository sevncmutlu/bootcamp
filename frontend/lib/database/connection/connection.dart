export 'connection_unsupported.dart'
    if (dart.library.js) 'connection_web.dart'
    if (dart.library.ffi) 'connection_native.dart';
