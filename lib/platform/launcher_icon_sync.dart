import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/garden_controller.dart';

/// Synchronizes the saved app theme with the Android launcher, outside domain state.
class LauncherIconSync extends StatefulWidget {
  const LauncherIconSync({
    super.key,
    required this.controller,
    required this.child,
  });

  final GardenController controller;
  final Widget child;

  @override
  State<LauncherIconSync> createState() => _LauncherIconSyncState();
}

class _LauncherIconSyncState extends State<LauncherIconSync>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('mygarden/launcher_icon');
  Future<void> _queue = Future.value();
  ThemeMode? _requested;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(LauncherIconSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _requested = null;
      _sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requested = null;
      _sync();
    }
  }

  void _sync() {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !widget.controller.initialized) {
      return;
    }
    final mode = widget.controller.themeMode;
    if (_requested == mode) return;
    _requested = mode;
    _queue = _queue.then((_) async {
      if (!mounted || widget.controller.themeMode != mode) return;
      try {
        await _channel.invokeMethod<void>('setTheme', {'theme': mode.name});
      } on PlatformException catch (error) {
        if (_requested == mode) _requested = null;
        debugPrint('Launcher icon update failed: ${error.code}: ${error.message}');
      } on MissingPluginException {
        if (_requested == mode) _requested = null;
        debugPrint('Launcher icon channel unavailable.');
      }
    });
    unawaited(_queue);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
