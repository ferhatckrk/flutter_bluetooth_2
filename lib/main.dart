import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
 
import 'package:quick_blue/models.dart';
import 'package:quick_blue/quick_blue.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

var _scanResults = <BlueScanResult>[];

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<BlueScanResult>? subscription;

  @override
  void initState() {
 

    super.initState();
    if (kDebugMode) {
      QuickBlue.setLogger(Logger("example"));
    }
    QuickBlue.isBluetoothAvailable();

    QuickBlue.setConnectionHandler((deviceId, state) {
      print("CONNECTION ID" + deviceId);
      print("CONNECTION STATE" + state.value);

      QuickBlue.readValue(deviceId, "service", "characteristic");
    });

    subscription = QuickBlue.scanResultStream.listen((result) {
      if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
        setState(() => _scanResults.add(result));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(children: [
          FutureBuilder(
            future: QuickBlue.isBluetoothAvailable(),
            builder: (context, snapshot) {
              var available = snapshot.data?.toString() ?? '...';
              return Text('Bluetooth init: $available');
            },
          ),
          Divider(
            color: Colors.blue,
          ),
          _buildButtons(),
          _buildListView(), 
          SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 20,
          ),
          _buildPermissionWarning(),
        ]),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
          child: Text('startScan'),
          onPressed: () {
            QuickBlue.startScan();
          },
        ),
        ElevatedButton(
          child: Text('stopScan'),
          onPressed: () {
            QuickBlue.stopScan();
          },
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title:
              Text('${_scanResults[index].name}(${_scanResults[index].rssi})'),
          subtitle: Text(_scanResults[index].deviceId),
          onTap: () {
            /*     Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  PeripheralDetailPage(_scanResults[index].deviceId),
                )); */
          },
          trailing: PopupMenuButton(
            onSelected: (value) {
              if (value == "1") {
                QuickBlue.connect(_scanResults[index].deviceId);
              } else if (value == "2") {
                QuickBlue.disconnect(_scanResults[index].deviceId);
              } else if (value == "3") {
                QuickBlue.writeValue(
                    _scanResults[index].deviceId,
                    "deneme",
                    "characteristic",
                    Uint8List(1212),
                    BleOutputProperty.withResponse);
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  child: Text("connect"),
                  value: '1',
                ),
                PopupMenuItem(
                  child: Text("disconnect"),
                  value: '2',
                ),
                PopupMenuItem(
                  child: Text("Contact"),
                  value: '3',
                )
              ];
            },
          ),
        ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _scanResults.length,
      ),
    );
  }

  Widget _buildPermissionWarning() {
    if (Platform.isAndroid) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Text('BLUETOOTH_SCAN/ACCESS_FINE_LOCATION needed'),
      );
    }
    return Container();
  }
}
