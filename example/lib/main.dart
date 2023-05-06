import 'dart:io';

import 'package:duet/duet.dart';
import 'package:duet/duet_view.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CameraView());
  }
}

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final url =
      'https://dphw5vqyyotoi.cloudfront.net/upload/5c209fe6176b0/2023/05/05/dd92_manhdz.mp4';
  final _duetPlugin = Duet();

  @override
  void initState() {
    super.initState();
    _duetPlugin.onNativeCall(
      onAudioReceived: printHau,
      onVideoMerged: printHau,
      onVideoRecorded: (url) {
        print('onVideoRecorded: $url');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlayVideosScreen(
              recordFilePath: url,
            ),
          ),
        );
      },
    );
  }

  void printHau(String? url) {
    print('HAUHAUHAU:$url');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            DuetView(args: DuetViewArgs(url: url)),
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
            onPressed: () => _duetPlugin.recordDuet(),
            child: const Text('Record'),
          ),
          ElevatedButton(
            onPressed: () => _duetPlugin.resetDuet(),
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Reset'),
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
      print(widget.recordFilePath);
      controller1 = VideoPlayerController.network(url);
      // controller2 = VideoPlayerController.asset('example.assets/3.mp4');
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
    final width = MediaQuery.of(context).size.width;
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
