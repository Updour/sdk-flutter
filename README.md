
# c_icare_sipcall - Flutter SIP Call SDK

`c_icare_sipcall` adalah SDK Flutter untuk melakukan panggilan SIP berbasis VoIP. SDK ini dibangun di atas [sip_ua](https://pub.dev/packages/sip_ua) dan dibungkus ulang agar lebih mudah digunakan untuk pemula. Cocok untuk aplikasi seperti call center, customer service, atau aplikasi internal perusahaan.

---

## 1. Instalasi

Tambahkan package ini ke dalam `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  c_icare_sipcall: ^1.0.0 # Ganti dengan versi terbaru
```

Lalu jalankan:

```bash
flutter pub get
```

---

## 2. Konfigurasi Android

Tambahkan permission berikut ke file `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
```

---

## 3. Import Package

```dart
import 'package:c_icare_sipcall/c_icare_sipcall.dart';
```

---

## 🧩 Komponen Utama

### CicareSipcall
- Registrasi dan unregistrasi akun SIP
- Melakukan panggilan keluar dan menerima panggilan
- Event listener: status registrasi, status panggilan, dan panggilan masuk

### Call
- Objek panggilan (incoming/outgoing)
- Dapat digunakan untuk `accept()`, `hangup()`, dan `reject()`

---

## Fitur Utama

### Registrasi SIP

```dart
final sipCall = CicareSipcall(
  exten: 'your-extension',
  password: 'your-password',
  displayName: 'C-Icare.cc',
  realm: 'your-domain',
);

await sipCall.requestPermissions();
await sipCall.register();
```

Event perubahan status registrasi:

```dart
sipCall.onRegistrationStateChanged = (RegistrationState state) {
  print('Status: ${state.state}');
};
```

---

### Panggilan Masuk

```dart
sipCall.onIncomingCall = (Call call) {
  // Tampilkan UI menerima atau menolak
};
```

---

### Panggilan Keluar

```dart
sipCall.call('1002'); // Ganti dengan nomor tujuan
```

---

### Mengakhiri Panggilan

```dart
sipCall.hangup(call);
```

---

## Lifecycle

Jangan lupa membersihkan resource:

```dart
@override
void dispose() {
  _extendController.dispose();
  _passwordController.dispose();
  sip?.unregister();
  super.dispose();
}
```

---

## Validasi

- Field yang divalidasi: `extension`, `password`
- Nomor tujuan hanya divalidasi saat ingin melakukan panggilan

---

## UI Utama (Komponen)

| Komponen               | Fungsi                                 |
|------------------------|----------------------------------------|
| TextFormField          | Input extension dan password           |
| Button "Register SIP"  | Memulai proses registrasi              |
| TextFormField          | Nomor tujuan panggilan                 |
| Button "Call"          | Memulai panggilan SIP                  |
| Incoming Call UI       | Tampilkan tombol "Terima" dan "Tolak" |

---

## Konfigurasi Default

- Domain: `demo.c-icare.cc`
- Display name: `Agent <extension>`
- Tombol panggilan tidak aktif jika belum register
- Status ditampilkan secara real-time di UI & debug console

---

## Contoh penggunaan

## Dukungan

```
import 'package:flutter/material.dart';
import 'package:c_icare_sipcall/c_icare_sipcall.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cicare SIP Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SipHomePage(),
    );
  }
}

class SipHomePage extends StatefulWidget {
  const SipHomePage({super.key});

  @override
  SipHomePageState createState() => SipHomePageState();
}

class SipHomePageState extends State<SipHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _extendController = TextEditingController();
  final _passwordController = TextEditingController();
  final _numberController = TextEditingController();
  String _statusMessage = 'Not connected';
  String targetNumber = '';
  bool _isConnected = false;

  CicareSipcall? sip;
  Call? incomingCall;

  @override
  void dispose() {
    _extendController.dispose();
    _passwordController.dispose();
    sip?.unregister();
    super.dispose();
  }

  void _registerSip() async {
    print(" Tombol Register SIP ditekan");

    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final extend = _extendController.text;
      final password = _passwordController.text;

      final sipCall = CicareSipcall(
        exten: extend,
        password: password,
        displayName: 'Agent $extend',
        realm: 'demo.c-icare.cc',
      );

      sipCall.onRegistrationStateChanged = (RegistrationState state) {
        setState(() {
          _statusMessage = ' ${state.state.toString()}';
        });
        print(" Registration State: ${state.state}");
      };

      sipCall.onIncomingCall = (Call call) {
        setState(() {
          incomingCall = call;
          _statusMessage = ' Incoming call from $call';
        });
        print(" Incoming call from $call");
      };

      sipCall.onCallStateChanged = (Call call, CallState state) {
        setState(() {
          _statusMessage = ' Call state: $state';
        });
        print("Call state: ${state.state}");
        if (state.state == CallStateEnum.ENDED ||
            state.state == CallStateEnum.FAILED) {
          incomingCall = null;
        }
      };

      await sipCall.requestPermissions();
      await sipCall.register();

      setState(() {
        sip = sipCall;
        _isConnected = true;
        _statusMessage = ' Registered as $extend';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' SIP Registered as $extend')),
      );
    } else {
      print(' Form tidak valid');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' Mohon isi semua form yang dibutuhkan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cicare SIP Demo'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  "Status: $_statusMessage",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _extendController,
                  decoration: InputDecoration(
                    labelText: 'Extension',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon isi extension';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon isi password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: _registerSip,
                  child: Text(_isConnected ? ' Registered' : ' Register SIP'),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Target Number',
                    border: OutlineInputBorder(),
                  ),
                  controller: _numberController,
                  // onChanged: (value) => targetNumber = value,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (!_isConnected || sip == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                ' Anda belum terhubung. Silakan register dulu.')),
                      );
                      return;
                    }

                    final number = _numberController.text.trim();
                    if (number.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(' Masukkan nomor tujuan')),
                      );
                      return;
                    }

                    setState(() {
                      targetNumber = number;
                    });

                    sip?.call(targetNumber);
                  },
                  child: Text('Call $targetNumber'),
                ),
                const SizedBox(height: 20.0),
                if (incomingCall != null) ...[
                  Text(
                      " Panggilan dari: ${incomingCall ?? 'Tidak diketahui'}"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () => sip!.accept(incomingCall!),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text("Terima"),
                      ),
                      ElevatedButton(
                        onPressed: () => sip!.hangup(incomingCall!),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text("Tolak"),
                      ),
                    ],
                  ),
                ],
              ],
            )),
      ),
    );
  }
}

```
Jika kamu mengalami kendala, silakan buat issue di GitHub repo atau hubungi tim pengembang.