import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';

String getLocalizedCategoryName(BuildContext context, String categoryName) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return categoryName;

  switch (categoryName.trim().toLowerCase()) {
    case 'market':
    case 'groceries':
    case 'shopping':
    case 'alışveriş':
      return l10n.categoryMarket;
    case 'restoran':
    case 'restaurant':
    case 'dining':
      return l10n.categoryRestaurant;
    case 'kira':
    case 'rent':
      return l10n.categoryRent;
    case 'faturalar':
    case 'bills':
    case 'utilities':
      return l10n.categoryBills;
    case 'ulaşım':
    case 'transport':
    case 'transportation':
      return l10n.categoryTransport;
    case 'eğlence':
    case 'entertainment':
    case 'fun':
      return l10n.categoryEntertainment;
    default:
      return categoryName;
  }
}
