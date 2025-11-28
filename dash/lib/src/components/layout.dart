import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/plugin/navigation_item.dart';
import 'package:dash/src/plugin/render_hook.dart';
import 'package:dash/src/resource.dart';
import 'package:jaspr/jaspr.dart';

/// Base layout component for authenticated pages in the admin panel.
///
/// Provides the standard admin layout with:
/// - Sidebar navigation
/// - Top header with user menu
/// - Main content area
/// - Plugin render hooks
class DashLayout extends StatelessComponent {
  final Component child;
  final String title;
  final String basePath;
  final List<Resource> resources;
  final List<NavigationItem> navigationItems;
  final RenderHookRegistry? renderHooks;

  const DashLayout({
    required this.child,
    required this.title,
    required this.basePath,
    required this.resources,
    this.navigationItems = const [],
    this.renderHooks,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex min-h-screen bg-gray-900', [
      // Sidebar
      aside(classes: 'w-64 bg-gray-800 text-white flex flex-col', [
        div(classes: 'p-6 border-b border-gray-700 flex justify-center', [
          img(src: '$basePath/assets/img/logo_square.png', alt: 'Dash Logo', classes: 'h-14'),
        ]),
        nav(classes: 'flex-1 py-6', [
          ul(classes: 'space-y-1', [
            li([
              a(
                href: basePath,
                classes:
                    'flex items-center gap-3 px-6 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors',
                [
                  const Heroicon(HeroIcons.home),
                  span([text('Dashboard')]),
                ],
              ),
            ]),
            // Render hook: sidebar nav start
            ...?renderHooks?.render(RenderHook.sidebarNavStart),
            // Dynamically generate grouped resource navigation
            ..._buildGroupedNavigation(),
            // Render hook: sidebar nav end
            ...?renderHooks?.render(RenderHook.sidebarNavEnd),
          ]),
        ]),
        // Render hook: sidebar footer
        ...?renderHooks?.render(RenderHook.sidebarFooter),
        // Logout button
        div(classes: 'p-6 border-t border-gray-700', [
          a(
            href: '$basePath/logout',
            classes:
                'flex items-center justify-center gap-2 px-4 py-2.5 text-gray-300 border border-gray-700 rounded-lg hover:bg-gray-700 hover:text-white transition-all',
            [
              const Heroicon(HeroIcons.arrowRightOnRectangle),
              span([text('Logout')]),
            ],
          ),
        ]),
      ]),
      // Main content
      div(classes: 'flex-1 flex flex-col', [
        main_(classes: 'flex-1 p-8', [
          // Render hook: content before
          ...?renderHooks?.render(RenderHook.contentBefore),
          child,
          // Render hook: content after
          ...?renderHooks?.render(RenderHook.contentAfter),
        ]),
      ]),
    ]);
  }

  /// Builds grouped navigation items from resources and plugin navigation items.
  List<Component> _buildGroupedNavigation() {
    final navigationResources = resources.where((resource) => resource.shouldRegisterNavigation).toList()
      ..sort((a, b) => a.navigationSort.compareTo(b.navigationSort));

    // Filter visible plugin navigation items
    final visibleNavItems = navigationItems.where((item) => item.isVisible).toList()
      ..sort((a, b) => a.getSort.compareTo(b.getSort));

    // Group resources by navigationGroup
    final groupedResources = <String, List<Resource>>{};
    for (final resource in navigationResources) {
      final group = resource.navigationGroup ?? 'Main';
      groupedResources.putIfAbsent(group, () => []).add(resource);
    }

    // Group plugin navigation items
    final groupedNavItems = <String, List<NavigationItem>>{};
    for (final item in visibleNavItems) {
      groupedNavItems.putIfAbsent(item.getGroup, () => []).add(item);
    }

    // Merge group names (resources first, then plugin items)
    final allGroups = <String>{...groupedResources.keys, ...groupedNavItems.keys};

    // Build navigation items for each group
    final items = <Component>[];
    for (final groupName in allGroups) {
      final groupResources = groupedResources[groupName] ?? [];
      final groupNavItems = groupedNavItems[groupName] ?? [];

      // Skip empty groups
      if (groupResources.isEmpty && groupNavItems.isEmpty) continue;

      // Add group header
      items.add(
        li(classes: 'mt-6 first:mt-0 mb-2 px-6', [
          span(classes: 'text-xs uppercase font-semibold tracking-wider text-gray-500', [text(groupName)]),
        ]),
      );

      // Add resources in this group
      for (final resource in groupResources) {
        items.add(
          li([
            a(
              href: '$basePath/resources/${resource.slug}',
              classes:
                  'flex items-center gap-3 px-6 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors',
              [
                resource.iconComponent,
                span([text(resource.label)]),
              ],
            ),
          ]),
        );
      }

      // Add plugin navigation items in this group
      for (final navItem in groupNavItems) {
        final resolvedUrl = navItem.resolveUrl(basePath);
        final targetAttr = navItem.shouldOpenInNewTab ? {'target': '_blank', 'rel': 'noopener noreferrer'} : null;

        items.add(
          li([
            a(
              href: resolvedUrl,
              classes:
                  'flex items-center gap-3 px-6 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors',
              attributes: targetAttr,
              [
                if (navItem.getIcon != null) Heroicon(navItem.getIcon!),
                span([text(navItem.label)]),
              ],
            ),
          ]),
        );
      }
    }

    return items;
  }
}
