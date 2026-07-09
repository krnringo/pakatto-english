import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/owned_card.dart';
import '../models/stamina_state.dart';

/// ローカル永続化(SharedPreferences)。データは端末内のみ(Kids Category対応)。
class GameRepository {
  GameRepository(this._prefs);

  static const _ownedCardsKey = 'ownedCards';
  static const _staminaKey = 'stamina';
  static const _totalOpenCountKey = 'totalOpenCount';
  static const _unlockedPackIdsKey = 'unlockedPackIds';

  final SharedPreferences _prefs;

  static Future<GameRepository> create() async =>
      GameRepository(await SharedPreferences.getInstance());

  Map<String, OwnedCard> loadOwnedCards() {
    final raw = _prefs.getString(_ownedCardsKey);
    if (raw == null) return {};
    final list = (jsonDecode(raw) as List)
        .map((e) => OwnedCard.fromJson(e as Map<String, dynamic>));
    return {for (final owned in list) owned.cardId: owned};
  }

  Future<void> saveOwnedCards(Map<String, OwnedCard> ownedCards) async {
    final list = ownedCards.values.map((o) => o.toJson()).toList();
    await _prefs.setString(_ownedCardsKey, jsonEncode(list));
  }

  StaminaState loadStamina() {
    final raw = _prefs.getString(_staminaKey);
    if (raw == null) return StaminaState.initial();
    return StaminaState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStamina(StaminaState stamina) async {
    await _prefs.setString(_staminaKey, jsonEncode(stamina.toJson()));
  }

  int loadTotalOpenCount() => _prefs.getInt(_totalOpenCountKey) ?? 0;

  Future<void> saveTotalOpenCount(int count) async {
    await _prefs.setInt(_totalOpenCountKey, count);
  }

  Set<String> loadUnlockedPackIds() =>
      (_prefs.getStringList(_unlockedPackIdsKey) ?? const []).toSet();

  Future<void> saveUnlockedPackIds(Set<String> packIds) async {
    await _prefs.setStringList(_unlockedPackIdsKey, packIds.toList());
  }
}
