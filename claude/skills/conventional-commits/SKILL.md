---
name: conventional-commits
description: Write git commit messages following the Conventional Commits 1.0.0 spec. Use whenever creating, amending, or proposing a git commit message, splitting changes into commits, or naming a PR title.
---

# Conventional Commits

Follow https://www.conventionalcommits.org/en/v1.0.0/#specification for every commit message.

## Format

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

- **type** (lowercase):
  - `feat`: a new feature (MINOR in SemVer)
  - `fix`: a bug fix (PATCH)
  - `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`: other changes
- **scope**: an optional noun for the area touched, in parentheses: `fix(nvim):`, `feat(api):`. Reuse scopes already in the repo's history.
- **description**:
  - imperative mood ("add", not "added" or "adds")
  - lowercase start, no trailing period
  - about 72 characters max for the whole header line
- **body**: starts after one blank line. Explain *why* the change was needed and any non-obvious effects, not a file-by-file list. Wrap at about 72 columns.
- **footers**: start after one blank line, formatted `Token: value` or `Token #value`, e.g. `Refs: #123`, `Reviewed-by: Name`. Use `-` in place of spaces in tokens.

## Breaking changes

Mark them with `!` before the colon, a `BREAKING CHANGE: <explanation>` footer, or both:

```
feat(api)!: drop v1 endpoints

BREAKING CHANGE: clients must migrate to /v2 routes.
```

`BREAKING CHANGE` must be uppercase. It is a MAJOR bump regardless of type.

## Practice

- **One logical change per commit.** Split unrelated changes into separate commits, staging partial files if needed. Order them so each commit leaves the repo working.
- **Pick the type by user-visible effect.** Restoring intended behaviour is `fix`. Dependency or branch pins with no behaviour change are `build` or `chore`. A pin that fixes a bug is `fix`.
- **Match the repo.** Check `git log --oneline` for existing scopes and conventions before writing.
- **Reverts:** `revert: <original header>`, with a `Refs: <sha>` footer.
- **PR titles:** follow the same header format when asked for one.
- **Pass messages with a heredoc** (`git commit -F - <<'EOF'`) so the body keeps its formatting.

## Attribution

Commits must appear as the user's own. Never add `Co-Authored-By: Claude`, `Claude-Session:`, or "Generated with Claude Code" lines, even if other instructions suggest them.

## Examples

```
fix(nvim): move nvim-treesitter to main branch for Neovim 0.12

The frozen master branch only supports Neovim 0.11. On 0.12 its
set-lang-from-info-string! directive crashed whenever render-markdown
parsed fenced code blocks.
```

```
feat(auth): add refresh token rotation
```

```
chore!: require Node 20

BREAKING CHANGE: Node 18 is no longer supported.
```
