# Pre-commit Hooks Setup

This repository uses [pre-commit](https://pre-commit.com/) to ensure code
quality, security, and consistency before commits.

## What Are Pre-commit Hooks?

Pre-commit hooks are automated checks that run before you commit code. They help
catch issues early:

- Code formatting problems
- Syntax errors
- Security vulnerabilities
- Large files
- Merge conflicts
- And more!

## Installation

### 1. Install pre-commit

**Using pip (recommended):**

```bash
pip install pre-commit
```

**Using Homebrew (macOS):**

```bash
brew install pre-commit
```

**Using conda:**

```bash
conda install -c conda-forge pre-commit
```

### 2. Install the hooks

From the repository root:

```bash
pre-commit install
```

This installs the git hooks defined in `.pre-commit-config.yaml`.

### 3. Install npm dependencies

The hooks need ESLint and Prettier:

```bash
npm install
```

## What Hooks Are Enabled?

### File Quality Checks

- ✅ **Large files** - Prevents files >1MB from being committed
- ✅ **Case conflicts** - Prevents case-insensitive filename conflicts
- ✅ **Merge conflicts** - Detects unresolved merge conflict markers
- ✅ **JSON/YAML syntax** - Validates configuration files
- ✅ **End of file** - Ensures files end with newline
- ✅ **Trailing whitespace** - Removes trailing whitespace
- ✅ **Line endings** - Enforces LF line endings

### Code Quality

- ✅ **ESLint** - JavaScript linting with auto-fix
- ✅ **Prettier** - Code formatting (JavaScript, JSON, Markdown, YAML)
- ✅ **npm audit** - Security vulnerability scanning
- ✅ **npm test** - Runs test suite for server code changes

### Security

- ✅ **Detect secrets** - Prevents committing API keys, passwords, etc.
- ✅ **Private key detection** - Prevents committing SSH/private keys
- ✅ **No commit to main/master** - Prevents direct commits to main branches

### Shell Scripts

- ✅ **ShellCheck** - Validates bash scripts like `browserquest.sh`

### Markdown

- ✅ **Markdownlint** - Ensures consistent Markdown formatting

### Custom Checks

- ✅ **Server not running** - Ensures server is stopped before committing
- ✅ **Conventional commits** - Enforces commit message format

## Usage

### Automatic (on git commit)

Once installed, hooks run automatically:

```bash
git add .
git commit -m "feat: add new feature"
# Hooks run automatically
```

If any hook fails, the commit is aborted and you'll see what needs to be fixed.

### Manual (run on all files)

Run all hooks on all files:

```bash
pre-commit run --all-files
```

Run a specific hook:

```bash
pre-commit run eslint --all-files
pre-commit run prettier --all-files
```

### Skip hooks (not recommended)

In rare cases, you can skip hooks:

```bash
git commit --no-verify -m "emergency fix"
```

**⚠️ Warning:** Only use this for emergencies!

## Configuration Files

The pre-commit setup includes these configuration files:

- [.pre-commit-config.yaml](.pre-commit-config.yaml) - Main pre-commit
  configuration
- [.eslintrc.json](.eslintrc.json) - ESLint rules for JavaScript
- [.prettierrc.json](.prettierrc.json) - Prettier formatting rules
- [.prettierignore](.prettierignore) - Files to exclude from Prettier
- [.markdownlint.json](.markdownlint.json) - Markdown linting rules

## npm Scripts

You can also run formatters manually:

```bash
# Format all files with Prettier
npm run format

# Check formatting without modifying files
npm run format:check

# Lint JavaScript files with ESLint
npm run lint
```

## Commit Message Format

This repo uses [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements

### Examples

```bash
git commit -m "feat(server): add WebSocket reconnection logic"
git commit -m "fix(client): resolve rendering bug on Safari"
git commit -m "docs: update installation instructions"
git commit -m "test(server): add tests for player connection"
```

## Troubleshooting

### Hook fails with "command not found"

Make sure you've installed pre-commit:

```bash
pip install pre-commit
pre-commit install
```

### ESLint/Prettier not found

Install npm dependencies:

```bash
npm install
```

### Detect-secrets baseline missing

Initialize the secrets baseline:

```bash
detect-secrets scan > .secrets.baseline
```

### Update hooks to latest versions

```bash
pre-commit autoupdate
```

### Remove all hooks

```bash
pre-commit uninstall
```

## Excluded Files

The following are excluded from most hooks:

- `node_modules/`
- `client-build/`
- `coverage/`
- `client/js/lib/` (third-party libraries)
- `server/js/lib/` (third-party libraries)
- `*.log` and `*.pid` files
- Binary files (images, audio, fonts)

## Performance

If hooks are slow, you can:

1. **Run hooks on staged files only** (default behavior)
2. **Skip heavy hooks** temporarily:

   ```bash
   SKIP=npm-test git commit -m "message"
   ```

3. **Disable specific hooks** by commenting them out in
   `.pre-commit-config.yaml`

## CI Integration

Pre-commit hooks also run in CI/CD pipelines. To run them in GitHub Actions:

```yaml
- name: Run pre-commit
  run: |
    pip install pre-commit
    pre-commit run --all-files
```

## Benefits

- 🚀 **Catch errors early** - Before they reach code review
- 🎨 **Consistent formatting** - Automatic code formatting
- 🔒 **Security** - Prevent secrets from being committed
- ✅ **Quality** - Enforces code standards
- ⚡ **Fast feedback** - Issues caught in seconds, not minutes

## Learn More

- [Pre-commit documentation](https://pre-commit.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [ESLint documentation](https://eslint.org/)
- [Prettier documentation](https://prettier.io/)
