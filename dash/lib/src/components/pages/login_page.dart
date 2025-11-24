import 'package:jaspr/jaspr.dart';

/// Login page component for the admin panel.
class LoginPage extends StatelessComponent {
  final String basePath;
  const LoginPage({super.key, this.basePath = '/admin'});

  @override
  Component build(BuildContext context) {
    return div(classes: 'login-page', [
      div(classes: 'login-container', [
        div(classes: 'login-card', [
          // Logo and title
          div(classes: 'login-header', [
            h1([text('DASH')]),
            p([text('Admin Panel Login')]),
          ]),
          // Login form
          form(action: '$basePath/login', method: FormMethod.post, [
            div(classes: 'form-group', [
              label(attributes: {'for': 'email'}, [text('Email')]),
              input(
                type: InputType.email,
                id: 'email',
                name: 'email',
                attributes: {'placeholder': 'admin@example.com', 'required': 'true'},
              ),
            ]),
            div(classes: 'form-group', [
              label(attributes: {'for': 'password'}, [text('Password')]),
              input(
                type: InputType.password,
                id: 'password',
                name: 'password',
                attributes: {'placeholder': '••••••••', 'required': 'true'},
              ),
            ]),
            div(classes: 'form-group', [
              label([input(type: InputType.checkbox, name: 'remember'), text(' Remember me')]),
            ]),
            button(type: ButtonType.submit, classes: 'btn-primary', [text('Login')]),
          ]),
        ]),
      ]),
    ]);
  }
}
