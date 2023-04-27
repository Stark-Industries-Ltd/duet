import 'package:duet/duet.dart';
import 'package:duet/duet_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final url =
      'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
  final _duetPlugin = Duet();

  @override
  void initState() {
    super.initState();
    _duetPlugin.onNativeCall(
      onAudioReceived: printHau,
      onVideoMerged: printHau,
      onVideoRecorded: printHau,
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
            _buildButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildButton() {
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
        ],
      ),
    );
  }
}
