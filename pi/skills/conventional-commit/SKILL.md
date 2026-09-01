---
name: conventional-commit
description: Write Conventional Commits style commit messages from staged git changes. Use when the user asks to write, craft, or compose a commit message.
---

# Conventional Commit

Generate a commit message following the [Conventional Commits](https://www.conventionalcommits.org/) spec based on the staged diff.

## Steps

1. Read the staged changes:

```
git diff --cached
```

If nothing is staged, check working-tree changes with `git diff` and `git status --short` and suggest staging first.

2. Determine the commit type from the change:
   - `feat` — new feature
   - `fix` — bug fix
   - `docs` — documentation only
   - `style` — formatting, no code change
   - `refactor` — code change that neither fixes a bug nor adds a feature
   - `perf` — performance improvement
   - `test` — adding or fixing tests
   - `chore` — build/tooling maintenance
   - `ci` — CI config changes

3. Write a concise message:

```
<type>(<scope>): <summary>

<body>
```

Rules:
- Summary is imperative, lowercase, no trailing period, ≤ 50 chars.
- Scope is optional; omit if the change spans the whole repo.
- Body explains the "why", one blank line after the summary.

4. Present the message in a fenced code block, then offer to run
   `git commit -m "<summary>" -m "<body>"` if the user approves.

## Example

```
feat(auth): add OAuth2 login flow

Adds authorization-code flow with PKCE for the web client.
Rotates refresh tokens and stores them encrypted at rest.
```
