import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/features/simulator/presentation/pages/debt_simulator_screen.dart';
import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_bloc.dart';
import 'package:maki_app/features/simulator/domain/repositories/simulator_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/simulator/domain/entities/simulation_result_entity.dart';

class MockSimulatorRepository implements SimulatorRepository {
  @override
  Future<SimulationResultEntity> simulatePayoff({
    required List<DebtEntity> debts,
    required double extraBudget,
    required String strategy,
  }) async {
    return const SimulationResultEntity(
      monthsToFree: 10,
      totalInterestPaid: 1000,
      schedule: [],
    );
  }
}

Widget createWidgetUnderTest(List<DebtEntity> debts) {
  final mockRepo = MockSimulatorRepository();
  return MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<SimulatorBloc>(
      create: (_) => SimulatorBloc(repository: mockRepo),
      child: DebtSimulatorScreen(initialDebts: debts),
    ),
  );
}

void main() {
  testWidgets('silinen borç ekrandan hemen kaldırılır', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(
        const [
          DebtEntity(
            id: 'kart-1',
            name: 'Kredi Kartı',
            balance: 12500,
            interestRate: 4.25,
            minPayment: 2500,
          ),
        ],
      ),
    );

    expect(find.text('Kredi Kartı'), findsOneWidget);
    await tester.tap(find.byTooltip('Borcu sil'));
    await tester.pump();

    expect(find.text('Kredi Kartı'), findsNothing);
    expect(find.textContaining('Henüz borç eklenmedi'), findsOneWidget);
  });

  testWidgets('dar ekranda ödeme stratejisi taşma üretmez', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createWidgetUnderTest(
        const [
          DebtEntity(
            id: 'kredi-1',
            name: 'İhtiyaç Kredisi',
            balance: 50000,
            interestRate: 3.49,
            minPayment: 4200,
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Çığ (En Yüksek Faiz)'), findsOneWidget);
    expect(find.text('Kar Topu (En Düşük Bakiye)'), findsOneWidget);
  });
}
