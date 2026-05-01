class AppEnv {
  AppEnv._();

  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.waste-mgmt.lk',
  );

  static const wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'https://api.waste-mgmt.lk',
  );

  static const mqttBroker = String.fromEnvironment(
    'MQTT_BROKER',
    defaultValue: 'emqx.waste-mgmt.lk',
  );

  static const keycloakUrl = String.fromEnvironment(
    'KEYCLOAK_URL',
    defaultValue: 'https://auth.waste-mgmt.lk',
  );

  static const mapboxToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: 'pk.eyJ1IjoiZ3JvdXAtZiIsImEiOiJncm91cC1mIn0.demo',
  );

  static const keycloakRealm = 'waste-management';
  static const keycloakClientId = 'waste-mobile-app';
  static const redirectUri = 'com.groupf.wasteapp://callback';

  static String get authEndpoint =>
      '$keycloakUrl/realms/$keycloakRealm/protocol/openid-connect/auth';

  static String get tokenEndpoint =>
      '$keycloakUrl/realms/$keycloakRealm/protocol/openid-connect/token';

  static String get mapTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}?access_token=$mapboxToken';
}
