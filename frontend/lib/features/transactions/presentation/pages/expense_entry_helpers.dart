part of 'expense_entry_screen.dart';

extension _ExpenseEntryHelpers on _ExpenseEntryScreenState {
  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'receipt':
        return Icons.receipt_long_outlined;
      case 'directions_bus':
        return Icons.directions_bus_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  IconData _getIncomeSourceIcon(String source) {
    switch (source.toLowerCase()) {
      case 'salary':
      case 'maaş':
        return Icons.work_outline;
      case 'freelance':
      case 'ek gelir':
        return Icons.laptop_chromebook_outlined;
      case 'investment':
      case 'yatırım':
        return Icons.trending_up_rounded;
      case 'rent':
      case 'kira':
        return Icons.real_estate_agent_outlined;
      case 'bonus':
      case 'prim':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _getLocalizedIncomeSource(BuildContext context, String source) {
    final l10n = AppLocalizations.of(context)!;
    switch (source.toLowerCase()) {
      case 'salary':
      case 'maaş':
        return l10n.sourceSalary;
      case 'freelance':
      case 'ek gelir':
        return l10n.sourceFreelance;
      case 'investment':
      case 'yatırım':
        return l10n.sourceInvestment;
      case 'rent':
      case 'kira':
        return l10n.sourceRent;
      case 'bonus':
      case 'prim':
        return l10n.sourceBonus;
      case 'other':
      case 'diğer':
        return l10n.sourceOther;
      default:
        return source;
    }
  }

  Color _parseHexColor(String hexStr) {
    try {
      final cleanHex = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
