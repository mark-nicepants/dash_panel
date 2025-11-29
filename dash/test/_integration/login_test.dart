@TestOn('browser')
library;

import 'package:dash/src/components/pages/login_page.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/browser_test.dart';

void main() {
  group('Login Page Integration', () {
    testBrowser('renders login form', (tester) async {
      tester.pumpComponent(const LoginPage());

      // Should render the welcome text
      expect(find.text('Welcome back'), findsOneComponent);
      expect(find.text('Sign in to your admin panel'), findsOneComponent);

      // Should render form
      expect(find.tag('form'), findsOneComponent);

      // Should have submit button
      expect(find.text('Sign in'), findsOneComponent);
    });

    testBrowser('can fill in email field', (tester) async {
      tester.pumpComponent(const LoginPage());

      // Find all input fields
      expect(find.tag('input'), findsNComponents(3)); // email, password, remember checkbox

      // Fill in email using the first input
      await tester.input(find.tag('input').first, value: 'test@example.com');

      // The form should still be there
      expect(find.tag('form'), findsOneComponent);
    });

    testBrowser('has remember me checkbox', (tester) async {
      tester.pumpComponent(const LoginPage());

      // Should have remember me text
      expect(find.text('Remember me'), findsOneComponent);
    });

    testBrowser('renders branding section', (tester) async {
      tester.pumpComponent(const LoginPage());

      // Should have the tagline text
      expect(find.text('A modern admin panel framework for Dart. '), findsOneComponent);
      expect(find.text('Build beautiful interfaces with ease.'), findsOneComponent);

      // Should have feature items
      expect(find.text('Type-safe models with automatic migrations'), findsOneComponent);
      expect(find.text('Fluent builder APIs for tables and forms'), findsOneComponent);
      expect(find.text('HTMX-powered server-side rendering'), findsOneComponent);
    });

    testBrowser('renders powered by footer', (tester) async {
      tester.pumpComponent(const LoginPage());

      expect(find.text('Powered by '), findsOneComponent);
      expect(find.text('Dash'), findsOneComponent);
    });

    testBrowser('form has correct method', (tester) async {
      tester.pumpComponent(const LoginPage());

      // Form should use POST method
      final formFinder = find.byComponentPredicate(
        (component) =>
            component is DomComponent && component.tag == 'form' && component.attributes?['method'] == 'post',
        description: 'form with POST method',
      );
      expect(formFinder, findsOneComponent);
    });
  });
}
