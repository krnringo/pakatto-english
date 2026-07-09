import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/game_repository.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await GameRepository.create();
  final gameState = GameState(repository: repository)..load();
  runApp(PakattoApp(gameState: gameState, audioService: TtsAudioService()));
}

class PakattoApp extends StatelessWidget {
  const PakattoApp({
    super.key,
    required this.gameState,
    required this.audioService,
  });

  final GameState gameState;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameState),
        Provider<AudioService>.value(value: audioService),
      ],
      child: MaterialApp(
        title: 'ぱかっとえいご',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF42A5F5)),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
