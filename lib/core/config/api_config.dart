class ApiConfig {
  // Bilgisayarinizin IP adresi (WSL2 localhost)
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String webUrl = 'http://localhost:8000/api/v1';
  
  static String get url {
    // Chrome'da calisirken localhost, telefonda 10.0.2.2
    return const bool.fromEnvironment('dart.vm.product') ? baseUrl : webUrl;
  }
}
