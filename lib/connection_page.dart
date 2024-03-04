import 'package:flutter/material.dart';
import 'package:gsoc_2024_4_button_app/services/ssh_services.dart';
import 'package:gsoc_2024_4_button_app/services/storage_service.dart';
import 'package:ssh2/ssh2.dart';
import 'entities/ssh_entity.dart';

class ConnectionPage extends StatefulWidget {
  final void Function(bool, SSHClient?) onConnectionChanged;
  const ConnectionPage({Key? key, required this.onConnectionChanged})
      : super(key: key);

  @override
  _ConnectionSettingsState createState() => _ConnectionSettingsState();
}
class _ConnectionSettingsState extends State<ConnectionPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  final StorageService settingsService = StorageService.shared;
  final SSHService sshService = SSHService.shared;

  @override
  void initState() {
    super.initState();
    loadSavedSettings();
  }

  bool connected = false;

  Future<void> loadSavedSettings() async {
    final settings = await settingsService.getConnectionSettings();
    _usernameController.text = settings['username']!;
    _passwordController.text = settings['password']!;
    _ipController.text = settings['ipAddress']!;
    _portController.text = settings['port']!;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Liquid Galaxy'),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Connection page',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 60),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'IP Address',
                ),
                controller: _ipController,
              ),
              const SizedBox(height: 10),
              TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Port',
              ),
                controller: _portController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                ),
                controller: _usernameController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                controller: _passwordController,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final username = _usernameController.text;
                  final password = _passwordController.text;
                  final ipAddress = _ipController.text;
                  final port = int.parse(_portController.text);

                  final connectionSettings = SSHEntity(
                    host: ipAddress,
                    port: port,
                    username: username,
                    passwordOrKey: password,
                  );

                  await settingsService.saveConnectionSettings(
                    username,
                    password,
                    ipAddress,
                    port.toString(),
                  );
                  try {
                    print("Username: " + username +"Pswrd: " + password + "IpAddress: " + ipAddress + "Port: " + port.toString());
                    await sshService.initializeSSH();
                    await sshService.connect(connectionSettings);
                    setState(() {
                      connected = true;
                    });
                    const snackBar = SnackBar(
                        content: Text('¡Connection successful!'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    widget.onConnectionChanged(
                        connected, sshService.client);
                  } catch (e) {
                    print('Connection error : $e');
                    setState(() {
                      connected = false;
                    });
                    const snackBar =
                    SnackBar(content: Text('¡Connection error, bad parameters!'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    widget.onConnectionChanged(connected, null);
                  }
                },
                child: const Text('Connect'),
              ),
            ]

        )
        ),
    );
  }
}

