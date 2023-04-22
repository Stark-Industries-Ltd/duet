import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DuetView extends StatefulWidget {
  const DuetView({Key? key}) : super(key: key);

  @override
  State<DuetView> createState() => _DuetViewState();
}

class _DuetViewState extends State<DuetView> {
  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = '<platform-view-type>';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
