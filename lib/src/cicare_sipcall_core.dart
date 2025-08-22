import 'dart:async';
import 'package:sip_ua/sip_ua.dart';
import 'package:permission_handler/permission_handler.dart';

class CicareSipcall implements SipUaHelperListener {
  @override
  void onNewMessage(SIPMessageRequest msg) {
    handleNewMessage(msg);
  }

  @override
  void onNewNotify(Notify ntf) {
    handleNewNotify(ntf);
  }

  final SIPUAHelper _helper = SIPUAHelper();

  // Callback bisa di-assign oleh pengguna
  Function(Call call)? onIncomingCall;
  Function(Call call, CallState state)? onCallStateChanged;
  Function(RegistrationState state)? onRegistrationStateChanged;
  Function(TransportState state)? onTransportStateChanged;
  Function(SIPMessageRequest msg)? onNewMessageCallback;
  Function(Notify ntf)? onNewNotifyCallback;

  // Konfigurasi dinamis
  late String realm;
  late String port;

  Call? _currentCall;

  String password;
  String exten;
  String displayName;

  CicareSipcall({
    required this.exten,
    required this.password,
    required this.displayName,
    this.realm = 'demo.c-icare.cc',
    this.port = '2790',
  }) {
    _helper.addSipUaHelperListener(this);
  }

  // Allow user to update login info dynamically
  void setLoginInfo(String ext, String pass, String name) {
    exten = ext;
    password = pass;
    displayName = name;
  }

  RegistrationState get registrationState => _helper.registerState;

  void addListener(SipUaHelperListener listener) {
    _helper.addSipUaHelperListener(listener);
  }

  Future<void> requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  Future<void> register() async {
    final settings = UaSettings()
      ..webSocketUrl = 'wss://$realm:$port/ws'
      ..webSocketSettings.allowBadCertificate = true
      ..uri = 'sip:$exten@$realm'
      ..authorizationUser = exten
      ..password = password
      ..displayName = displayName
      ..userAgent = 'C-iCare SIP Client v1.0.0'
      ..dtmfMode = DtmfMode.RFC2833;

    await _helper.start(settings);
  }

  void unregister() => _helper.unregister(true);

  Future<void> _makeCall(String target, {bool withVideo = false}) async {
    await requestPermissions();

    if (_helper.registerState.state != RegistrationStateEnum.REGISTERED) {
      await register();
      await Future.delayed(const Duration(seconds: 3));
    }

    if (await Permission.microphone.isGranted &&
        (!withVideo || await Permission.camera.isGranted)) {
      _helper.call('sip:$target@$realm');
    } else {
      print("Permission microphone or camera not granted");
    }
  }

  // Fungsi-fungsi panggilan
  void call(String target) => _makeCall(target, withVideo: false);
  void callVideo(String target) => _makeCall(target, withVideo: true);

  void spying(String target) => _makeCall('*222$target');
  void whispering(String target) => _makeCall('*223$target');
  void barging(String target) => _makeCall('*224$target');

  void accept(Call call, {bool withVideo = false}) {
    _currentCall = call;
    call.answer(_helper.buildCallOptions(withVideo));
  }

  void reject(Call call) {
    _currentCall = call;
    call.hangup();
  }

  void hangup([Call? call]) {
    _currentCall = call ?? _currentCall;
    _currentCall?.hangup();
  }

  // SIP Listener Implementation
  @override
  void callStateChanged(Call call, CallState state) {
    _currentCall = call;

    // Trigger hanya jika incoming
    if (state.state == CallStateEnum.CALL_INITIATION &&
        call.direction == 'INCOMING') {
      onIncomingCall?.call(call);
    }

    onCallStateChanged?.call(call, state);
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    onRegistrationStateChanged?.call(state);
  }

  @override
  void transportStateChanged(TransportState state) {
    onTransportStateChanged?.call(state);
  }

  void handleNewMessage(SIPMessageRequest msg) {
    onNewMessageCallback?.call(msg);
  }

  void handleNewNotify(Notify ntf) {
    onNewNotifyCallback?.call(ntf);
  }
}
