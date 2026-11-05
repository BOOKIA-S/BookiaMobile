// Conventional Commits rules (docs/CONSTITUTION.md 6.4, VER-01)
export default {
  extends: ['@commitlint/config-conventional'],
  // Dependabot bodies paste release notes with long lines; skip its commits.
  ignores: [(message) => /^Signed-off-by: dependabot\[bot\]/m.test(message)],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'build', 'ci', 'chore', 'revert'],
    ],
    'subject-case': [0],
  },
};
