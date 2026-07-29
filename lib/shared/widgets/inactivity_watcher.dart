import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/secure_session_store.dart';
import '../../core/services/session_service.dart';

/// Cierra sesión por inactividad; la última interacción se persiste para sobrevivir un reinicio del proceso.
class InactivityWatcher extends StatefulWidget {
  static const Duration timeout = Duration(minutes: 5);

  final Widget child;

  const InactivityWatcher({super.key, required this.child});

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkElapsedSinceBackground();
    }
  }

  Future<void> _checkElapsedSinceBackground() async {
    final lastActive = await SecureSessionStore.readLastActive();
    if (lastActive == null) {
      _resetTimer();
      return;
    }
    final elapsed = DateTime.now().difference(lastActive);
    if (elapsed >= InactivityWatcher.timeout) {
      _timer?.cancel();
      await SessionService.logoutForInactivity();
    } else {
      _resetTimer();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    SecureSessionStore.saveLastActive(DateTime.now());
    _timer = Timer(InactivityWatcher.timeout, () {
      SessionService.logoutForInactivity();
    });
  }

  void _onUserInteraction([PointerEvent? _]) => _resetTimer();

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      onPointerSignal: _onUserInteraction,
      child: widget.child,
    );
  }
}
