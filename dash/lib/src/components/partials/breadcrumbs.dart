import 'package:jaspr/jaspr.dart';

class BreadCrumbs extends StatelessComponent {
  final List<BreadCrumbItem> items;

  const BreadCrumbs({required this.items, super.key});

  @override
  Component build(BuildContext context) {
    return nav(classes: 'text-sm', [
      ol(classes: 'flex items-center gap-2', [
        for (int i = 0; i < items.length; i++) ...[
          li(classes: 'inline-flex', [
            if (items[i].url != null)
              a(href: items[i].url!, classes: 'text-gray-400 hover:text-gray-200 transition-colors', [
                text(items[i].label),
              ])
            else
              span(classes: 'text-gray-200', [text(items[i].label)]),
          ]),
          if (i < items.length - 1) li(classes: 'text-gray-600 select-none', [text('›')]),
        ],
      ]),
    ]);
  }
}

class BreadCrumbItem {
  final String label;
  final String? url;

  const BreadCrumbItem({required this.label, this.url});
}
