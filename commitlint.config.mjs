// Conventional Commits rules (docs/CONSTITUTION.md 6.4, VER-01)

// Legacy web-UI commits already in develop/main; history is not rewritten.
const legacyMessages = new Set([
  'Update README.md', // f2314d5
  'Correct name of Ángel de Jesús López to Torres', // 16687a0
  'Update team member name in README.md', // d0730b0
]);

export default {
  extends: ['@commitlint/config-conventional'],
  ignores: [
    // Dependabot bodies paste release notes with long lines; skip its commits.
    (message) => /^Signed-off-by: dependabot\[bot\]/m.test(message),
    (message) => legacyMessages.has(message.trim()),
  ],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert'],
    ],
    'subject-case': [0],
  },
};
