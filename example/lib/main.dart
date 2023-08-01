// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:duet/duet.dart';
import 'package:duet_example/duet_info.dart';
import 'package:duet_example/vod/index.dart';
import 'package:duet_example/vod_client.dart';
import 'package:duet_example/vuihoc_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'model/ielts_lesson.dart';
import 'vod/src/submit_video_param.dart';
import 'vod/src/vod_upload.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MergeView());
  }
}

class MergeView extends StatefulWidget {
  const MergeView({Key? key}) : super(key: key);

  @override
  State<MergeView> createState() => _MergeViewState();
}

class _MergeViewState extends State<MergeView> {
  final _uidController = TextEditingController()..text = '1167712';
  final _lidController = TextEditingController()..text = '1468356';
  final _vodPlugin = VODUpload();
  final Duet _duetPlugin = Duet();
  RxDouble percent = 0.0.obs;
  String status = '';
  String _recordFilePath = '';
  String origin = '';
  String userVideo = '';
  final _vhClient = VuiHocClient(
    Dio()
      ..interceptors.add(LogInterceptor(
        request: true,
        requestBody: false,
        responseBody: true,
        logPrint: (v) => log('$v', name: '_MergeViewState'),
      )),
  );

  String get fileName =>
      '${duet?.userId}-${DateTime.now().millisecondsSinceEpoch}.mp4';

  DuetInfo? duet;

  VODUploadModel? uploadModel;

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((value) {
      log(value.path, name: 'DOCUMENT PATH');
      origin = '${value.path}/origin.mp4';
      if (mounted) setState(() {});
    });
    _duetPlugin.onNativeCall(
      onVideoMerged: _onDuetMerged,
      onVideoError: _onDuetError,
    );
    _vodPlugin.onNativeCall(
      onSuccess: (v) {
        final data = VODUploadModel.fromJson(jsonDecode(v));
        log(data.toJson().toString(), name: '_MergeViewState. remote Url');
        uploadModel = data;
        setState(() => status = 'Upload Alibaba success');
      },
      onProgress: (count, total) {
        percent.value = (count ?? 0) / (total ?? 1);
      },
    );
  }

  _onDuetMerged(url) {
    setState(() => _recordFilePath = url);
    setState(() => status = 'Duet merged');
    log(url, name: 'VIDEO MERGED');
  }

  _onDuetError(v) {
    log(v, name: '_MergeViewState. ERROR');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.greenAccent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_recordFilePath.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 18 / 16,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: PlayVideosScreen(
                          recordFilePath: _recordFilePath,
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: <Widget>[
                        duetInput(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final result =
                                    await FilePicker.platform.pickFiles();

                                if (result != null) {
                                  File file =
                                      File(result.files.single.path ?? '');
                                  setState(() => userVideo = file.path);
                                }
                              },
                              child: const Text('Pick'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final documentDir =
                                    await getApplicationDocumentsDirectory();
                                origin = '${documentDir.path}/origin.mp4';
                                setState(() => status = 'Duet downloading...');
                                await Dio().download(
                                  duet?.videoDuet ?? '',
                                  origin,
                                  onReceiveProgress: (count, total) {
                                    percent.value =
                                        total != 0 ? count / total : 0;
                                  },
                                );
                                log('${duet?.videoDuet}', name: 'VIDEO DUET');
                                setState(() => status = 'Duet downloaded');
                                log(origin, name: '_MergeViewState.build');
                              },
                              child: const Text('Download'),
                            ),
                            ElevatedButton(
                              style: (origin.isEmpty ||
                                      duet?.userVideo?.isEmpty == true)
                                  ? _deActiveButtonStyle
                                  : null,
                              onPressed: () async {
                                if (origin.isEmpty ||
                                    duet?.userVideo?.isEmpty == true) {
                                  return;
                                }
                                setState(() => status = 'Duet merging...');
                                log(
                                  'MERGE\n$origin\n$userVideo',
                                  name: '_MergeViewState.build',
                                );
                                _duetPlugin.merge('$origin|$userVideo');
                              },
                              child: const Text('Merge'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                setState(() => status = 'Aliyun uploading...');
                                final vod = await _getUploadSlot(fileName);
                                if (vod != null) _uploadByAliSDK(vod);
                              },
                              child: const Text('Upload'),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.red),
                              ),
                              onPressed: () async {
                                final param = SubmitVideoParam(
                                  videoId: uploadModel?.videoId ?? '',
                                  lessonId: uploadModel?.lessonId ?? 0,
                                  sectionId: uploadModel?.sectionId ?? 0,
                                  fileName: uploadModel?.fileName,
                                  fileSize: 0,
                                  skillId: duet?.skillId,
                                  duetVideoId: duet?.duetVideoId,
                                  videoPath: uploadModel?.pathUpload,
                                );
                                final result = await _vhClient.submitVideo(
                                  param,
                                  token: duet?.token,
                                );
                                log('$result', name: '_MergeViewState.build');
                                setState(() => status = 'Submit completed');
                              },
                              child: const Text('Submit BE'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                _uidController.text = '';
                                duet = null;
                                _recordFilePath = '';
                                userVideo = '';
                                uploadModel = null;
                                setState(() => status = '');
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        Text(status),
                      ].separator(Container(height: 4)),
                    ),
                  ),
                  if (_recordFilePath.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: () {
                          final info = duet?.toJson();
                          info?.addAll({'user_video': userVideo});
                          return info?.entries
                                  .map(
                                    (e) => Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${e.key}:  ', style: style),
                                        Flexible(
                                          child: Text(
                                            '${e.value}',
                                            style: style,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList() ??
                              [];
                        }(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  final style = const TextStyle(color: Colors.black, fontSize: 16);

  void _getInfo() async {
    try {
      status = "Loading info...";
      final result = await VuiHocClient(Dio()).getStudentsByLessonId(
        _lidController.text,
      );
      percent.value = 0.2;
      final lesson = IeltsLesson.fromJson(result['data']);
      final student = lesson.students?.singleWhereOrNull(
        (e) => '${e.coreUserId}' == _uidController.text,
      );
      final auth = await _vhClient.getToken(
        birthday: student?.getBirthday ?? '',
        uid: student?.coreUserId ?? 0,
      );

      percent.value = 0.4;
      final token = 'Bearer ${auth['data']['token']}';
      final lessonData = await _vhClient.getLesson(
        lessonId: lesson.lessonId.toString(),
        token: token,
      );
      log('', name: '_MergeViewState._getInfo');
      percent.value = 0.8;

      final lessonInfo = IeltsLesson.fromJson(lessonData['data']);
      log('${lessonInfo.skills?.last.listMission?.last.toJson()}',
          name: '_MergeViewState._getInfo');
      final lessonDuet = lessonInfo.skills?.last.listMission?.first;
      if (lessonDuet?.isDuet != true) return;

      final duetInfo = DuetInfo(
        userId: student?.coreUserId,
        userName: student?.fullName,
        sectionId: lessonInfo.sectionId,
        lessonId: lesson.lessonId,
        skillId: lessonInfo.skills?.last.id,
        duetVideoId: lessonDuet?.id,
        videoDuet: lessonDuet?.videoUrl,
        token: token,
      );
      status = "Load info success";
      setState(() => duet = duetInfo);

      log('${duet?.videoDuet}', name: '_MergeViewState._getInfo');
      percent.value = 1;
    } catch (e, st) {
      log('', name: '_MergeViewState._getInfo', error: e, stackTrace: st);
    }
  }

  final ButtonStyle _deActiveButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateColor.resolveWith((states) => Colors.red),
  );

  Future<VodResponse?> _getUploadSlot(String fileName) async {
    final request = VodRequest(fileName: fileName, title: fileName);
    try {
      final slot = await VODClient(Dio()).getSlot(request);
      if (slot.uploadAuth.isNotEmpty) return slot;
    } catch (e) {
      log('', name: '_MergeViewState._getUploadSlot', error: e);
    }
    return null;
  }

  void _uploadByAliSDK(VodResponse vod) async {
    if (duet?.lessonId == null || duet?.sectionId == null) {
      log(
        'NULL: ${duet?.lessonId} ${duet?.sectionId}',
        name: '_MergeViewState._uploadByAliSDK',
      );
      return;
    }
    final request = VODUploadModel(
      videoId: vod.videoId,
      lessonId: duet!.lessonId!,
      sectionId: duet!.sectionId!,
      fileName: fileName,
      pathVideo: _recordFilePath,
      uploadAuth: vod.uploadAuth,
      uploadAddress: vod.uploadAddress,
    );
    try {
      _vodPlugin.upload(request.toJson());
    } catch (e, st) {
      log('', name: '._uploadByAliSDK', error: e, stackTrace: st);
    }
  }

  Stack duetInput() {
    return Stack(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _uidController,
                  decoration: const InputDecoration(
                    labelText: 'UserID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _lidController,
                  decoration: const InputDecoration(
                    labelText: 'LessonID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _getInfo,
                child: const Text('Get Info'),
              ),
            ],
          ),
        ),
        ObxValue<RxDouble>(
          (v) {
            if (v.value == 0 || v.value == 1) {
              return const SizedBox();
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: Colors.black54,
                color: Colors.green,
                value: v.value,
                minHeight: 30,
              ),
            );
          },
          percent,
        ),
      ],
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
  late VideoPlayerController controller1;

  @override
  void initState() {
    super.initState();
    try {
      controller1 = VideoPlayerController.file(File(widget.recordFilePath));
      controller1.initialize().then((value) {
        setState(() {});
      });
    } catch (err) {
      initState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
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
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            ElevatedButton(
              onPressed: () {
                log('', name: '_PlayVideosScreenState.build');
                controller1.play();
              },
              child: const Text('Play'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                controller1.pause();
              },
              child: const Text('Pause'),
            ),
          ],
        ),
      ],
    );
  }
}

extension SeparatorExt<T> on List<T> {
  List<T> separator(T child) {
    if (length <= 1) return this;
    for (int i = length - 1; i > 0; i--) {
      insert(i, child);
    }
    return this;
  }
}
