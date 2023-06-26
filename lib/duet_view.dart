import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DuetView extends StatelessWidget {
  final DuetViewArgs args;

  const DuetView({
    Key? key,
    this.args = const DuetViewArgs(),
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
  final String? url;
  final String? image;
  final int? lessonId;
  final int? userId;

  const DuetViewArgs({
    this.url,
    this.image,
    this.lessonId,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'url': url,
      'image': image,
      'lesson_id': lessonId,
      'user_id': userId,
    };
  }
}
