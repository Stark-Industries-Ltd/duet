import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DuetView extends StatelessWidget {
  final DuetViewArgs args;

  const DuetView({
    Key? key,
    required this.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = '<platform-view-type>';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};
    creationParams.addAll(args.toJson());

    if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return const Center(child: Text('Platform not supported'));
  }
}

class DuetViewArgs {
  final String url;
  final String image;
  final int userId;
  final String userName;
  final int classId;
  final int lessonId;

  const DuetViewArgs({
    required this.url,
    required this.image,
    required this.userName,
    required this.userId,
    required this.classId,
    required this.lessonId,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'url': url,
      'image': image,
      'user_id': userId,
      'user_name': userName,
      'class_id': classId,
      'lesson_id': lessonId,
    };
  }
}
