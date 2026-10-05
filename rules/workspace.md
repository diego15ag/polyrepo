# Multi-repo workspace

You are at the root of a workspace: a folder whose direct children are independent git repos.
The root itself is NOT a git repo. Always target a repo explicitly: `git -C <repo> …`.

## Context
- The map below lists every repo, its current branch and last commit date. ★ = not on its default branch (work in flight) — mention ★ repos to the user at the start.
- Work out which repos a task involves yourself, from this map and the repos' docs and code. Ask only if you genuinely can't tell.
- Before touching a repo, read its `CLAUDE.md` or `AGENTS.md`; if neither exists, read its README and build files.
- If a repo you work in lacks a useful README or CLAUDE.md/AGENTS.md, offer to draft a CLAUDE.md. Leave it untracked and tell the user they can either commit it or keep it local-only by adding it to `.git/info/exclude`.

## Working across repos
- Each repo has its own history, branches and conventions. Follow each repo's own way of working (its docs, CONTRIBUTING, existing branches) and the user's instructions; this workspace imposes none.
- Edits here happen in each repo's shared checkout, so another session working in the same repo at the same time can interfere.

## Parallel work
- For parallel multi-repo work, the user starts the session with `/polyrepo:parallel <task>`, which isolates the session in per-repo git worktrees. It is user-only: you can't see or invoke it, which is expected and does not mean the plugin is missing. If the user wants parallel work, tell them to type it.
- For parallel work inside ONE repo, the user uses `claude --worktree <task>` from that repo.
