import 'package:flutter/material.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/maki_navigation_dock.dart';

class MakiAdaptiveNavigation extends StatelessWidget {
  const MakiAdaptiveNavigation({
    super.key,
    this.scaffoldKey,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.drawer,
    this.floatingActionButton,
  });

  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget? drawer;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // A tablet/phone in landscape still needs the full canvas. The rail
        // only appears once the viewport is genuinely desktop-sized.
        final useRail = constraints.maxWidth >= 960;
        final extended = constraints.maxWidth >= 1280;

        return Scaffold(
          key: scaffoldKey,
          drawer: drawer,
          body: useRail
              ? Row(
                  children: [
                    SafeArea(
                      right: false,
                      child: Container(
                        margin: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          boxShadow: AppShadows.soft(
                            theme.brightness,
                            theme.colorScheme.primary,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: NavigationRail(
                          key: const ValueKey('maki-navigation-rail'),
                          selectedIndex: selectedIndex,
                          onDestinationSelected: onDestinationSelected,
                          extended: extended,
                          labelType: extended
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.selected,
                          groupAlignment: -0.35,
                          minWidth: 72,
                          minExtendedWidth: 210,
                          useIndicator: true,
                          destinations: destinations
                              .map(
                                (destination) => NavigationRailDestination(
                                  icon: destination.icon,
                                  selectedIcon: destination.selectedIcon,
                                  label: Text(destination.label),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    Expanded(child: body),
                  ],
                )
              : body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: useRail
              ? null
              : MakiNavigationDock(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: destinations,
                ),
        );
      },
    );
  }
}
