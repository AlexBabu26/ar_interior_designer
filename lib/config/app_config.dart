/// Base URL for loading product 3D model files (e.g. from Dart Frog server).
/// When set, relative model paths like /product_assets/models/foo.glb are
/// resolved against this origin so the AR view can load models in development
/// even when the Flutter web server does not serve them.
String? productModelsBaseUrl;
