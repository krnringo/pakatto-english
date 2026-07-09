/// カードの所持状況(永続化対象)。
///
/// [reviewCount] は同じカードを2枚目以降に引いた回数(=復習回数)。
class OwnedCard {
  OwnedCard({
    required this.cardId,
    required this.count,
    required this.reviewCount,
    required this.firstAcquiredAt,
  });

  final String cardId;
  int count;
  int reviewCount;
  final DateTime firstAcquiredAt;

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'count': count,
        'reviewCount': reviewCount,
        'firstAcquiredAt': firstAcquiredAt.toIso8601String(),
      };

  factory OwnedCard.fromJson(Map<String, dynamic> json) => OwnedCard(
        cardId: json['cardId'] as String,
        count: json['count'] as int,
        reviewCount: json['reviewCount'] as int,
        firstAcquiredAt: DateTime.parse(json['firstAcquiredAt'] as String),
      );
}
