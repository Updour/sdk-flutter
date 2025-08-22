import 'package:flutter/material.dart';
import 'package:c_icare_sipcall/c_icare_sipcall.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final CicareSipcall sipClient = CicareSipcall(
    exten: 'your_extend',
    password: 'your_password',
    displayName: 'Agent',
  );

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SIP Call')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await sipClient.register();
                },
                child: const Text('Register SIP'),
              ),
              ElevatedButton(
                onPressed: () {
                  sipClient.call('81002'); // Ganti dengan nomor tujuan
                },
                child: const Text('Call'),
              ),
              ElevatedButton(
                onPressed: () {
                  sipClient.unregister();
                },
                child: const Text('Unregister SIP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
