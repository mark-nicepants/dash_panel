/** @type {import('tailwindcss').Config} */
export default {
  content: {
    files: [
      {
        base: './lib',
        pattern: '**/*.dart',
        negated: [],
      },
      {
        base: '../dash_example/lib',
        pattern: '**/*.dart',
        negated: [],
      },
    ],
  },
}
