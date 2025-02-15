import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:duet/duet.dart';
import 'package:duet/duet_view.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraView(),
          ),
        ),
        child: const Text('Open Camera'),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MainScreen());
  }
}

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class DuetScrip {
  final int time;
  final int duration;

  DuetScrip({
    required this.time,
    required this.duration,
  });
}

class _CameraViewState extends State<CameraView> {
  final url =
      'https://dphw5vqyyotoi.cloudfront.net/upload/5c209fe6176b0/2023/05/05/dd92_manhdz.mp4';
  final _duetPlugin = Duet();
  String _recordFilePath = '';

// ...
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _duetPlugin.onNativeCall(
      onAudioReceived: printHau,
      onVideoMerged: printHau,
      onVideoRecorded: (url) {
        setState(() {
          _recordFilePath = url;
        });
        print('onVideoRecorded: $url');
      },
      onTimerVideoReceived: _handleVideoTime,
      onWillEnterForeground: (_) {
        print('onWillEnterForeground');
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      _duetPlugin.playSound('assets/duet_start.m4a');
    });
  }

  _handleVideoTime(timer) {}

  void printHau(String? url) {
    print('HAUHAUHAU:$url');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _recordFilePath.isNotEmpty
            ? Stack(
                children: [
                  PlayVideosScreen(
                    recordFilePath: _recordFilePath,
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _recordFilePath = '';
                        });
                      },
                      child: const Text('back'),
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  DuetView(
                    args: DuetViewArgs(
                        url: url,
                        userName: '',
                        userId: 0,
                        image: '',
                        lessonId: 0,
                        classId: 0),
                  ),
                  _buildButton(context),
                ],
              ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              _duetPlugin.playSound('assets/duet_321go.m4a');

              Future.delayed(const Duration(seconds: 4), () {
                _duetPlugin.recordDuet();
                Future.delayed(const Duration(seconds: 2), () {
                  player.play(
                    UrlSource(
                      'https://onlinetestcase.com/wp-content/uploads/2023/06/1-MB-MP3.mp3',
                    ),
                  );
                  Future.delayed(const Duration(seconds: 4), () {
                    player.dispose();
                    _duetPlugin.playAudioFromUrl(
                      'https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.mp3',
                    );
                    Future.delayed(const Duration(seconds: 1), () {
                      _duetPlugin.stopAudioPlayer();
                    });
                  });
                });
              });
            },
            child: const Text('Record'),
          ),
          ElevatedButton(
            onPressed: () {
              _duetPlugin.resumeDuet();
              _duetPlugin.recordAudio();
            },
            child: const Text('Record Audio'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('back'),
          ),
        ],
      ),
    );
  }
}

class PlayVideosScreen extends StatefulWidget {
  const PlayVideosScreen({Key? key, required this.recordFilePath})
      : super(key: key);
  final String recordFilePath;

  @override
  State<PlayVideosScreen> createState() => _PlayVideosScreenState();
}

class _PlayVideosScreenState extends State<PlayVideosScreen> {
  late VideoPlayerController controller1, controller2;
  final url =
      'https://dphw5vqyyotoi.cloudfront.net/upload/5c209fe6176b0/2023/05/05/dd92_manhdz.mp4';

  @override
  void initState() {
    super.initState();
    try {
      controller1 = VideoPlayerController.network(url);
      controller2 = VideoPlayerController.file(File(widget.recordFilePath));
      controller1.initialize().then((value) {
        // controller1.setVolume(1);
        setState(() {});
      });
      controller2.initialize().then((value) {
        // controller2.setVolume(1.0);
        setState(() {});
      });
    } catch (err) {
      initState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  InkWell(
                    onTap: () {
                      controller1.play();
                      controller2.play();
                    },
                    child: Container(
                      width: 50,
                      height: 48,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.blue),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Play'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      controller1.pause();
                      controller2.pause();
                    },
                    child: Container(
                      width: 50,
                      height: 48,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.blue),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Pause'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    // width: width / 2,
                    // height: width / 2 / controller1.value.aspectRatio,
                    child: AspectRatio(
                      aspectRatio: controller1.value.aspectRatio,
                      child: VideoPlayer(controller1),
                    ),
                  ),
                  Flexible(
                    // width: width / 2,
                    // height: width / 2 / controller2.value.aspectRatio,
                    child: AspectRatio(
                      aspectRatio: controller2.value.aspectRatio,
                      child: VideoPlayer(controller2),
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
