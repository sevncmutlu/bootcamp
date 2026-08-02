import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/coach/data/datasources/local_coach_engine.dart';

void main() {
  test('borç planını backend ve oturum olmadan yanıtlar', () {
    final engine = LocalCoachEngine();

    final answer = engine.respond(
      question: 'Borçlarım için bir ödeme planı oluşturalım.',
      sessionId: 'session-1',
    );

    expect(answer, contains('Borçlarının kalan tutarını'));
    expect(answer, contains('Çığ'));
  });

  test('rota bağlamı yerine kullanıcının açık sorusunu önceler', () {
    final engine = LocalCoachEngine();

    final answer = engine.respond(
      question:
          'Ana finans rotası: Hedef Rotası. Öncelik: hedef katkısı.\n'
          'Kullanıcının sorusu: Bütçeme uygun bir tasarruf önerisi ver.',
      sessionId: 'session-2',
    );

    expect(answer, contains('Birikimi ay sonunda kalana bırakma'));
    expect(answer, isNot(contains('Hedef Rotası kartına')));
  });

  test('oturum içindeki son finans konusunu takip sorusunda hatırlar', () {
    final engine = LocalCoachEngine();
    engine.respond(
      question: 'Borçlarımı kapatmak istiyorum.',
      sessionId: 'session-3',
    );

    final answer = engine.respond(
      question: 'Hangisi benim için daha iyi?',
      sessionId: 'session-3',
    );

    expect(answer, contains('Çığ'));
    expect(answer, contains('Kar Topu'));
  });
}
