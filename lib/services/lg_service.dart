import 'dart:io';
import 'package:ssh2/ssh2.dart';
import 'package:path_provider/path_provider.dart';

class LGService {
  final SSHClient _client;
  LGService(SSHClient client) : _client = client;
  static LGService? shared;

  int screenAmount = 3;

  Future<String?> getScreenAmount() async {
    return _client
        .execute("grep -oP '(?<=DHCP_LG_FRAMES_MAX=).*' personavars.txt");
  }

  int get logoSlave {
    if (screenAmount == 1) {
      return 1;
    }
    return (screenAmount / 2).floor() + 2;
  }

  int get infoSlave {
    if (screenAmount == 1) {
      return 1;
    }
    return (screenAmount / 2).floor() + 1;
  }

  Future<void> reboot() async {

    final pw = _client.passwordOrKey;

    for (var i = screenAmount; i >= 1; i--) {
      try {
        await _client
            .execute('sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S reboot"');
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> sendKMLToSlave() async {
    try {
      String command = """chmod 777 /var/www/html/kml/slave_$infoSlave.kml; echo '<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>historic.kml</name> 
    <Style id="purple_paddle">
      <BalloonStyle>
        <text>\$[description]</text>
        <bgColor>ffffffff</bgColor>
      </BalloonStyle>
    </Style>
    <Placemark id="0A7ACC68BF23CB81B354">
      <name>Baloon</name>
      <Snippet maxLines="0"></Snippet>
      <description>
      <![CDATA[<!-- BalloonStyle background color: ffffffff -->
        <table width="400" height="300" align="left">
          <tr>
            <td colspan="2" align="center">
              <h1>Rafel Salgueiro</h1>
            </td>
          </tr>
          <tr>
            <td colspan="2" align="center">
              <h1>Lleida</h1>
            </td>
          </tr>
        </table>]]>
      </description>
      <LookAt>
        <longitude>-17.841486</longitude>
        <latitude>28.638478</latitude>
        <altitude>0</altitude>
        <heading>0</heading>
        <tilt>0</tilt>
        <range>24000</range>
      </LookAt>
      <styleUrl>#purple_paddle</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>-17.841486,28.638478,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>
' > /var/www/html/kml/slave_$infoSlave.kml""";
      await _client
          .execute(command);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  Future<bool> connected() async {
    try {
      await _client.connect();
      return true;
    } catch (e) {
      print (e);
      return false;
    }
  }

  Future<void> sendTourToLleida() async {
    await _client.connect();
    await _client.execute("echo 'flytoview=<gx:duration>5</gx:duration><LookAt><longitude> 0.6259788 </longitude><latitude> 41.618023 </latitude><altitude>10000</altitude><heading>0</heading><tilt>0</tilt><range>1000.66</range><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>' > /tmp/query.txt");
  }

  Future<Object?> sendOrbit() async {
    double heading = 0;
    int orbit= 0;
    String content = '';

    while (orbit <= 36) {
      if (heading >= 360) heading -= 360;
      content += '''
            <gx:FlyTo>
              <gx:duration>1.2</gx:duration>
              <gx:flyToMode>smooth</gx:flyToMode>
              <LookAt>
                  <longitude>0.6259788</longitude>
                  <latitude>41.618023</latitude>
                  <heading>$heading</heading>
                  <tilt>0</tilt>
                  <range>1000.66</range>
                  <gx:fovy>60</gx:fovy> 
                  <altitude>15000</altitude> 
                  <gx:altitudeMode>absolute</gx:altitudeMode>
              </LookAt>
            </gx:FlyTo>
          ''';
      heading += 10;
      orbit += 1;
    }
    String kmlOrbit = '''
<?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
        <gx:Tour>
          <name>Orbit</name>
          <gx:Playlist> 
            $content
          </gx:Playlist>
        </gx:Tour>
      </kml>
    ''';


    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Orbit.kml');
    file.writeAsStringSync(kmlOrbit);

    await _client.connectSFTP();
    await _client.sftpUpload(
        path: file.path,
        toPath: '/var/www/html',
        callback: (progress) {
          print('Sent $progress');
        });
    await _client.execute(
        "echo 'http://lg1:81/Orbit.kml' >> /var/www/html/kmls.txt");

    try {
      await _client.execute('echo "playtour=Orbit" > /tmp/query.txt');
      print ("query set");
      return "sent";
    } catch (e) {
      print('Could not connect to host LG');
      return Future.error(e);
    }
  }
}