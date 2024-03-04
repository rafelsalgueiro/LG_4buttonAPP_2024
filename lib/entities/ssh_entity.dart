class SSHEntity {
  String host;
  int port;
  String username;
  String passwordOrKey;

  SSHEntity({
    this.host = '',
    this.port = 22,
    this.username = '',
    this.passwordOrKey = ''
  });
}