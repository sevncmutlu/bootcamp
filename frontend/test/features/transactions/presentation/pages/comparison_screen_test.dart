import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:maki_app/features/transactions/presentation/pages/comparison_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionBloc extends Mock implements TransactionBloc {}

void main() {
  late MockTransactionBloc bloc;

  setUpAll(() {
    registerFallbackValue(const TransactionState());
  });

  setUp(() {
    bloc = MockTransactionBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  Widget app(TransactionState state) {
    when(() => bloc.state).thenReturn(state);
    return BlocProvider<TransactionBloc>.value(
      value: bloc,
      child: const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ComparisonScreen(),
      ),
    );
  }

  testWidgets('boş durumda yerel karşılaştırma yönlendirmesini gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(app(const TransactionState()));
    await tester.pump();

    expect(find.text('Karşılaştırılacak kayıt yok'), findsOneWidget);
  });

  testWidgets('cari ayın net durumunu ve kategorilerini hesaplar', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      app(
        TransactionState(
          incomes: [
            IncomeEntity(
              title: 'Maaş',
              amount: 30000,
              date: now,
              source: 'Maaş',
            ),
          ],
          expenses: [
            ExpenseEntity(
              title: 'Market',
              amount: 5000,
              date: now,
              category: 'Market',
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Net durum'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Market'), findsOneWidget);
    expect(find.textContaining('25.000'), findsOneWidget);
  });
}
