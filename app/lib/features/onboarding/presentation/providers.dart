import 'dart:async';

import 'package:bookia_mobile/core/location/location_providers.dart';
import 'package:bookia_mobile/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:bookia_mobile/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:bookia_mobile/features/onboarding/domain/usecases/answer_location_prompt.dart';
import 'package:bookia_mobile/features/onboarding/domain/usecases/should_ask_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (_) => const OnboardingRepositoryImpl(),
);

final shouldAskLocationProvider = Provider<ShouldAskLocation>(
  (ref) => ShouldAskLocation(
    ref.watch(locationServiceProvider),
    ref.watch(onboardingRepositoryProvider),
  ),
);

final answerLocationPromptProvider = Provider<AnswerLocationPrompt>(
  (ref) => AnswerLocationPrompt(
    ref.watch(locationServiceProvider),
    ref.watch(onboardingRepositoryProvider),
  ),
);

/// Decided once after 01 Splash: true opens 02, false goes to Inicio and
/// loads the position in the background if it is already allowed.
final locationPromptNeededProvider = FutureProvider<bool>((ref) async {
  final bool ask;
  try {
    ask = await ref.read(shouldAskLocationProvider).call();
  } on Exception {
    return false;
  }
  if (!ask) unawaited(ref.read(currentPositionProvider.notifier).refresh());
  return ask;
});
