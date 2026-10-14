import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  // ProviderScope stores the state of every Riverpod provider in the app.
  runApp(const ProviderScope(child: PokedexApp()));
}
