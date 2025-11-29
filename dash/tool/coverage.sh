#!/bin/bash

# Coverage report generator for Dash
# Filters out UI components (src/components) which require integration testing

set -e

cd "$(dirname "$0")/.."

echo "🧹 Cleaning previous coverage data..."
rm -rf coverage

echo "🧪 Running tests with coverage..."
dart test --coverage=coverage

echo "📊 Formatting coverage data..."
dart pub global run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib

echo "🔧 Filtering out src/components from coverage..."
grep -v "SF:.*src/components" coverage/lcov.info > coverage/lcov.filtered.info || true

echo "📄 Generating HTML report..."
genhtml coverage/lcov.filtered.info -o coverage/html --quiet --ignore-errors range

# Calculate and display coverage summary
TOTAL_LINES=$(grep -c "^DA:" coverage/lcov.filtered.info || echo "0")
HIT_LINES=$(grep "^DA:" coverage/lcov.filtered.info | grep -v ",0$" | wc -l | tr -d ' ')
if [ "$TOTAL_LINES" -gt 0 ]; then
  COVERAGE=$(echo "scale=1; $HIT_LINES * 100 / $TOTAL_LINES" | bc)
  echo ""
  echo "✅ Coverage report generated: coverage/html/index.html"
  echo "📈 Coverage (excluding components): ${COVERAGE}% ($HIT_LINES/$TOTAL_LINES lines)"
else
  echo "⚠️  No coverage data found"
fi

# Open report if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  open coverage/html/index.html
fi
