/// Basic CSS styles for the Dash admin panel.
///
/// This provides minimal styling to make the admin panel functional.
/// In the future, this will be replaced with a proper theming system.
const String dashStyles = '''
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  font-size: 14px;
  line-height: 1.5;
  color: #1f2937;
  background: #f9fafb;
}

/* Login Page */
.login-page {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-container {
  width: 100%;
  max-width: 400px;
  padding: 20px;
}

.login-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  padding: 40px;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-header h1 {
  font-size: 32px;
  font-weight: bold;
  color: #667eea;
  margin-bottom: 8px;
}

.login-header p {
  color: #6b7280;
}

/* Form Styles */
.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  font-weight: 500;
  color: #374151;
}

.form-group input[type="email"],
.form-group input[type="password"],
.form-group input[type="text"] {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

/* Buttons */
.btn-primary,
button[type="submit"] {
  width: 100%;
  padding: 12px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-primary:hover,
button[type="submit"]:hover {
  background: #5568d3;
}

/* Layout */
.dash-layout {
  display: flex;
  min-height: 100vh;
}

.dash-sidebar {
  width: 250px;
  background: #1f2937;
  color: white;
  display: flex;
  flex-direction: column;
}

.dash-logo {
  padding: 20px;
  border-bottom: 1px solid #374151;
}

.dash-logo h2 {
  font-size: 24px;
  font-weight: bold;
  color: #667eea;
}

.dash-nav {
  flex: 1;
  padding: 20px 0;
}

.dash-nav ul {
  list-style: none;
}

.dash-nav li {
  margin-bottom: 4px;
}

.dash-nav li.nav-group-header {
  margin-top: 20px;
  margin-bottom: 8px;
  padding: 8px 20px;
}

.dash-nav li.nav-group-header:first-child {
  margin-top: 0;
}

.dash-nav li.nav-group-header span {
  font-size: 11px;
  text-transform: uppercase;
  font-weight: 600;
  letter-spacing: 0.5px;
  color: #9ca3af;
}

.nav-icon {
  width: 1.25rem;
  height: 1.25rem;
  margin-right: 0.75rem;
  display: inline-block;
  vertical-align: middle;
  flex-shrink: 0;
}

.dash-nav a {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  color: #d1d5db;
  text-decoration: none;
  transition: all 0.2s;
}

.dash-nav a span {
  display: inline-block;
}

.dash-nav a:hover {
  background: #374151;
  color: white;
}

.dash-sidebar-footer {
  padding: 20px;
  border-top: 1px solid #374151;
}

.logout-button {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 10px;
  text-align: center;
  color: #d1d5db;
  text-decoration: none;
  border: 1px solid #374151;
  border-radius: 6px;
  transition: all 0.2s;
  gap: 0.5rem;
}

.logout-button:hover {
  background: #374151;
  color: white;
}

.dash-main {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.dash-header {
  background: white;
  border-bottom: 1px solid #e5e7eb;
  padding: 20px 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dash-header h1 {
  font-size: 24px;
  font-weight: 600;
  color: #1f2937;
}

.dash-content {
  flex: 1;
  padding: 30px;
}

/* Dashboard */
.dashboard-widgets {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.widget-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  padding: 20px;
}

.widget-card h3 {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 12px;
  color: #1f2937;
}

.widget-card ul {
  list-style: none;
}

.widget-card li {
  padding: 8px 0;
  border-bottom: 1px solid #f3f4f6;
}

.widget-card li:last-child {
  border-bottom: none;
}

/* Resource Views */
.resource-content {
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  padding: 20px;
}

.resource-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #e5e7eb;
}

.resource-header h2 {
  font-size: 20px;
  font-weight: 600;
  color: #1f2937;
}

.resource-header .btn-primary {
  width: auto;
  padding: 8px 16px;
}
''';
