import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/catch_local_datasource.dart';

class CatchState {
  const CatchState({required this.caught, required this.masterBalls});

  final Set<int> caught;
  final int masterBalls;
}

class CatchNotifier extends Notifier<CatchState> {
  CatchLocalDataSource get _store =>
      CatchLocalDataSource(ref.read(sharedPreferencesProvider));

  @override
  CatchState build() => CatchState(
        caught: _store.loadCaught(),
        masterBalls: _store.loadMasterBalls(),
      );

  Future<void> recordCatch(int pokemonId) {
    final caught = {...state.caught, pokemonId};
    state = CatchState(caught: caught, masterBalls: state.masterBalls);
    return _store.saveCaught(caught);
  }

  Future<void> useMasterBall() {
    final left = (state.masterBalls - 1).clamp(0, 999);
    state = CatchState(caught: state.caught, masterBalls: left);
    return _store.saveMasterBalls(left);
  }
}

final catchProvider =
    NotifierProvider<CatchNotifier, CatchState>(CatchNotifier.new);
