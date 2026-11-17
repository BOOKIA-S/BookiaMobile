import 'dart:async';

import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/core/location/location_service.dart';
import 'package:bookia_mobile/features/onboarding/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel (PAT-02) of screen 02. The state is true while the system
/// dialog is open, so the buttons can be disabled.
class LocationPermissionController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<LocationAccess> allow() async {
    state = true;
    try {
      final access = await ref.read(answerLocationPromptProvider).allow();
      if (access == LocationAccess.granted) {
        unawaited(ref.read(currentPositionProvider.notifier).refresh());
      }
      return access;
    } on Exception {
      return LocationAccess.denied;
    } finally {
      if (ref.mounted) state = false;
    }
  }

  Future<void> skip() => ref.read(answerLocationPromptProvider).skip();
}

final locationPermissionControllerProvider =
    NotifierProvider.autoDispose<LocationPermissionController, bool>(
      LocationPermissionController.new,
    );
