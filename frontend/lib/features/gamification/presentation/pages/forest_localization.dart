part of 'forest_screen.dart';

extension _ForestLocalization on ForestScreenState {
  String _getLocalizedTitle(BuildContext context, String key) {
    final catalogTask = DailyChallengeCatalog.fromStorageKey(key);
    if (catalogTask != null) {
      return catalogTask.title(Localizations.localeOf(context).languageCode);
    }
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'challengeCookHome':
        return l10n.challengeCookHome;
      case 'challengeLogThree':
        return l10n.challengeLogThree;
      case 'challengeNoShopping':
        return l10n.challengeNoShopping;
      case 'challengeSaveTen':
        return l10n.challengeSaveTen;
      case 'challengeIncomeAchiever':
        return l10n.challengeIncomeAchiever;
      case 'challengeCoffeeSaver':
        return l10n.challengeCoffeeSaver;
      case 'challengeReceiptMaster':
        return l10n.challengeReceiptMaster;
      case 'challengeSuperSaver':
        return l10n.challengeSuperSaver;
      case 'challengeCommuteSmart':
        return l10n.challengeCommuteSmart;
      case 'challengeEntertainmentControl':
        return l10n.challengeEntertainmentControl;
      case 'challengeSubscriptionAudit':
        return l10n.challengeSubscriptionAudit;
      case 'challengeBudgetGuardian':
        return l10n.challengeBudgetGuardian;
      case 'challengeMicroSaver':
        return l10n.challengeMicroSaver;
      case 'challengeWeeklyReviewer':
      case 'challengeLearnBudget':
        return l10n.challengeWeeklyReviewer;
      case 'challengeFirstRecord':
        return l10n.challengeFirstRecord;
      case 'challengeTwoCategories':
        return l10n.challengeTwoCategories;
      case 'challengeRecordNote':
        return l10n.challengeRecordNote;
      case 'challengePositiveBalance':
        return l10n.challengePositiveBalance;
      case 'challengeGoalContribution':
        return l10n.challengeGoalContribution;
      case 'challengeDailyReview':
        return l10n.challengeDailyReview;
      case 'challengeLowSpend':
        return l10n.challengeLowSpend;
      case 'challengeMixedRecord':
        return l10n.challengeMixedRecord;
      case 'challengeMorningLog':
        return l10n.challengeMorningLog;
      case 'challengeReviewSubs':
        return l10n.challengeSubscriptionAudit;
      case 'challengeMealPrep':
        return l10n.challengeCoffeeSaver;
      case 'challengeWalk':
        return l10n.challengeCommuteSmart;
      default:
        return key;
    }
  }

  String _getLocalizedDesc(BuildContext context, String key) {
    final catalogTask = DailyChallengeCatalog.fromStorageKey(key);
    if (catalogTask != null) {
      return catalogTask.description(
        Localizations.localeOf(context).languageCode,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'challengeCookHomeDesc':
        return l10n.challengeCookHomeDesc;
      case 'challengeLogThreeDesc':
        return l10n.challengeLogThreeDesc;
      case 'challengeNoShoppingDesc':
        return l10n.challengeNoShoppingDesc;
      case 'challengeSaveTenDesc':
        return l10n.challengeSaveTenDesc;
      case 'challengeIncomeAchieverDesc':
        return l10n.challengeIncomeAchieverDesc;
      case 'challengeCoffeeSaverDesc':
        return l10n.challengeCoffeeSaverDesc;
      case 'challengeReceiptMasterDesc':
        return l10n.challengeReceiptMasterDesc;
      case 'challengeSuperSaverDesc':
        return l10n.challengeSuperSaverDesc;
      case 'challengeCommuteSmartDesc':
        return l10n.challengeCommuteSmartDesc;
      case 'challengeEntertainmentControlDesc':
        return l10n.challengeEntertainmentControlDesc;
      case 'challengeSubscriptionAuditDesc':
        return l10n.challengeSubscriptionAuditDesc;
      case 'challengeBudgetGuardianDesc':
        return l10n.challengeBudgetGuardianDesc;
      case 'challengeMicroSaverDesc':
        return l10n.challengeMicroSaverDesc;
      case 'challengeWeeklyReviewerDesc':
      case 'challengeLearnBudgetDesc':
        return l10n.challengeWeeklyReviewerDesc;
      case 'challengeFirstRecordDesc':
        return l10n.challengeFirstRecordDesc;
      case 'challengeTwoCategoriesDesc':
        return l10n.challengeTwoCategoriesDesc;
      case 'challengeRecordNoteDesc':
        return l10n.challengeRecordNoteDesc;
      case 'challengePositiveBalanceDesc':
        return l10n.challengePositiveBalanceDesc;
      case 'challengeGoalContributionDesc':
        return l10n.challengeGoalContributionDesc;
      case 'challengeDailyReviewDesc':
        return l10n.challengeDailyReviewDesc;
      case 'challengeLowSpendDesc':
        return l10n.challengeLowSpendDesc;
      case 'challengeMixedRecordDesc':
        return l10n.challengeMixedRecordDesc;
      case 'challengeMorningLogDesc':
        return l10n.challengeMorningLogDesc;
      case 'challengeReviewSubsDesc':
        return l10n.challengeSubscriptionAuditDesc;
      case 'challengeMealPrepDesc':
        return l10n.challengeCoffeeSaverDesc;
      case 'challengeWalkDesc':
        return l10n.challengeCommuteSmartDesc;
      default:
        return key;
    }
  }

  IconData _challengeIcon(DailyChallengeEntity challenge) {
    final id = challenge.id;
    if (id.contains('receipt')) return Icons.receipt_long_rounded;
    if (id.contains('goal_contribution')) return Icons.flag_rounded;
    if (id.contains('daily_review')) return Icons.calendar_month_rounded;
    if (id.contains('cook_home')) return Icons.home_rounded;
    if (id.contains('coffee')) return Icons.coffee_rounded;
    if (id.contains('commute')) return Icons.directions_walk_rounded;
    if (id.contains('income') || id.contains('positive_balance')) {
      return Icons.trending_up_rounded;
    }
    if (id.contains('category')) return Icons.category_rounded;
    if (id.contains('note')) return Icons.edit_note_rounded;
    if (id.contains('morning')) return Icons.wb_sunny_rounded;
    if (id.contains('shopping')) return Icons.shopping_bag_outlined;
    return Icons.eco_rounded;
  }

  String _routeName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (widget.primaryGoal) {
      'pay_debt' => l10n.floraMyrtleTitle,
      'save_goal' => l10n.floraOakTitle,
      'learn_invest' => l10n.floraTamariskTitle,
      _ => l10n.floraLaurelCherryTitle,
    };
  }
}
