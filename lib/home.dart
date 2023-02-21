import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter_config/flutter_config.dart';

// const appId = ""; 
// const token = "";

String appId = FlutterConfig.get('AGORA_APPID');
String token = FlutterConfig.get('AGORA_RTC_TOKEN');

const channel = "ch1";

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _remoteUid = null;
  late RtcEngine _engine;
  bool _localUserJoined = false;

  bool muted = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initForAgora();
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  Future<void> initForAgora() async {
    await [Permission.microphone, Permission.camera].request();
    // create the engine
    _engine = await RtcEngine.create(appId);

    await _engine.enableVideo();
    _engine.setEventHandler(RtcEngineEventHandler(
        joinChannelSuccess: (String channel, int uid, int elapsed) {
      print("local user $uid joinded");
      _localUserJoined = true;
      // _engine.setEnableSpeakerphone(true);
    }, userJoined: (int uid, int elapsed) {
      print("remote user $uid joinded");
      setState(() {
        _remoteUid = uid;
      });
    }, userOffline: (int uid, UserOfflineReason reason) {
      print("remote user $uid left channel");
      setState(() {
        _remoteUid = null;
      });
    }));

    await _engine.joinChannel(token, channel, null, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _renderRemoteVideo(),
            ),
            Positioned(
              top: 30,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: _localUserJoined ? Colors.transparent : Colors.grey,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                height: 200,
                width: 120,
                child: Center(
                  child: _localUserJoined
                      ? _renderLocalPreview()
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(bottom: 80),
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RawMaterialButton(
                      onPressed: () {
                        setState(() {
                          muted = !muted;
                        });
                        _engine.muteLocalAudioStream(muted);
                      },
                      child: Icon(
                        Icons.mic,
                        color: muted ? Colors.white : Colors.blueAccent,
                        size: 20.0,
                      ),
                      shape: CircleBorder(),
                      elevation: 2,
                      fillColor: muted ? Colors.blueAccent : Colors.white,
                      padding: const EdgeInsets.all(12.0),
                    ),
                    RawMaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 35,
                      ),
                      shape: const CircleBorder(),
                      elevation: 2,
                      fillColor: Colors.redAccent,
                      padding: const EdgeInsets.all(15.0),
                    ),
                    RawMaterialButton(
                      onPressed: () {
                        _engine.switchCamera();
                      },
                      child: Icon(
                        Icons.switch_camera,
                        color: Colors.blueAccent,
                        size: 20.0,
                      ),
                      shape: CircleBorder(),
                      elevation: 2,
                      fillColor:Colors.white,
                      padding: const EdgeInsets.all(12.0),
                    )
                  ],
                ),
              ),
            )
          ],
        ));
  }

  Widget _renderRemoteVideo() {
    if (_remoteUid != null) {
      return Platform.isIOS
          ? Transform.rotate(
              angle: 0 * pi / 180,
              child: RtcRemoteView.SurfaceView(
                  uid: _remoteUid!, channelId: channel),
            )
          : RtcRemoteView.SurfaceView(uid: _remoteUid!, channelId: channel);
    } else {
      return const Text(
        'Please wait for patient to join',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _renderLocalPreview() {
    // return  Transform.rotate(
    //   angle: 90 * pi / 180,
    //   child: RtcLocalView.SurfaceView());

    return const RtcLocalView.SurfaceView();
  }
}
