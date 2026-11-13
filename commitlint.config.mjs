// Conventional Commits rules (docs/CONSTITUTION.md 6.4, VER-01)
export default {
  extends: ['@commitlint/config-conventional'],
  ignores: [
    // Dependabot bodies paste release notes with long lines; skip its commits.
    (message) => /^Signed-off-by: dependabot\[bot\]/m.test(message),
    // Legacy web-UI commit f2314d5 already in develop; history is not rewritten.
    (message) => message.trim() === 'Update README.md',
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
