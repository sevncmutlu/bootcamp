import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:maki_app/features/transactions/presentation/pages/receipt_scanner_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_state.dart';

class MockTransactionBloc extends Mock implements TransactionBloc {}
class MockPremiumBloc extends Mock implements PremiumBloc {}

void main() {
  late MockTransactionBloc mockTransactionBloc;
  late MockPremiumBloc mockPremiumBloc;

  setUpAll(() {
    registerFallbackValue(const TransactionState());
    registerFallbackValue(const PremiumState(isPremium: false, isLoading: false));
  });

  setUp(() {
    mockTransactionBloc = MockTransactionBloc();
    when(() => mockTransactionBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockTransactionBloc.close()).thenAnswer((_) async {});
    
    mockPremiumBloc = MockPremiumBloc();
    when(() => mockPremiumBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockPremiumBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionBloc>.value(value: mockTransactionBloc),
        BlocProvider<PremiumBloc>.value(value: mockPremiumBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReceiptScannerScreen(),
      ),
    );
  }

  group('ReceiptScannerScreen UI Tests', () {
    testWidgets('renders initial UI correctly', (tester) async {
      when(() => mockTransactionBloc.state).thenReturn(TransactionState(
        expenses: [],
        incomes: [],
        categories: [CategoryEntity(id: 1, name: 'Food', colorHex: '#FF0000', iconName: 'food')],
      ));
      
      when(() => mockPremiumBloc.state).thenReturn(const PremiumState(
        isPremium: true,
        isLoading: false,
      ));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ReceiptScannerScreen), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget); // camera button
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget); // gallery button
    });
  });
}
