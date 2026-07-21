abstract class MpConnectRepository {
  Future<bool> getStatus();
  Future<String> getAuthURL();
}
