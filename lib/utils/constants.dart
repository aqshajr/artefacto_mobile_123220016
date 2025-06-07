class Constants {
  static const String baseUrl =
      "https://artefacto-backend-749281711221.us-central1.run.app/api";
  static const Duration sessionDuration = Duration(hours: 24);

  // Token refresh threshold (refresh token when less than 1 hour remaining)
  static const Duration refreshThreshold = Duration(hours: 1);
}
