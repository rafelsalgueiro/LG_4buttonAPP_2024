import 'package:flutter/material.dart';
import 'package:ssh2/ssh2.dart';
import 'connection_page.dart';
import 'package:gsoc_2024_4_button_app/services/lg_service.dart';

class LandingPage extends StatefulWidget  {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}
class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  bool connected = false;
  SSHClient? sshClient;

  void _handleConnectionChanged(bool connected, SSHClient? client) {
    setState(() {
      this.connected = connected;
      sshClient = client;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LG 4 BUTTONS APP',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Confirm Reboot"),
                          content: const Text("Liquid Galaxy will be rebooted. Are you sure?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text("No"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text("Yes"),
                            ),
                          ],
                        );
                      },
                    ).then((confirmed) async {
                      if (confirmed == true) {
                        await LGService.shared?.reboot();
                      }
                    });
                  },
                  child: const Text('Reboot LG'),
                ),

                ElevatedButton(
                  onPressed: () async {
                       await LGService.shared?.sendTourToLleida();
                  },
                  child: const Text('Move LG to Lleida'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                     await LGService.shared?.sendOrbit();
                  },
                  child: const Text('Orbit around your home city'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await LGService.shared?.sendKMLToSlave();
                  },
                  child: const Text('HTML bubble'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ConnectionPage(onConnectionChanged: _handleConnectionChanged)),
          );
        },
        label: const Text(
          'Connection page',
          style: TextStyle(color: Colors.black),
        ),
        icon: const Icon(
          Icons.arrow_forward,
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
