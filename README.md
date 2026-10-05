# polyrepo

**One Claude Code session across all your repos.** Describe a task, and the agent works out which repos it touches and changes them. You don't need a monorepo, an index to maintain, or to paste context in.

## Why

- **It knows your workspace from the first message.** Every session started in your workspace gets a fresh map of every repo: current branch, what's in flight (★), and the last commit. There's nothing to set up or keep in sync: new clones just show up.
- **It finds the right repos itself.** You say *what* you want, not *where*. The agent picks the repos from the map and their docs, and only asks when it genuinely can't tell.
- **It runs in parallel without collisions.** `/polyrepo:parallel <task>` gives a session its own git worktree per repo, created only for the repos it actually edits. Several sessions can work on the same repos at once, and your checkouts stay untouched.
- **It respects your workflow.** No branching, commit or review conventions are imposed: each repo's own rules and yours apply.
- **It's cheap and safe.** It's local git only (no network) and costs about one line of context per repo, around 1 s for 35 repos. Repo details are read only when needed. Cleanup never discards work without asking you.
- **It's small enough to audit.** One ~120-line POSIX shell script plus markdown. The only dependency is `git`.
- **It makes `AGENTS.md` work too.** Repos that document themselves in `AGENTS.md` instead of `CLAUDE.md` get it loaded automatically.

## How it works

- **Workspace root.** It's the folder you configure, or, with no configuration, any folder that isn't a repo itself and contains 2 or more repos. Starting Claude there adds the workspace rules and the repo map to the session.
- **Inside any repo.** If the repo has an `AGENTS.md` and no `CLAUDE.md`, that `AGENTS.md` is loaded.
- **Parallel mode.** `/polyrepo:parallel <task> [description]` switches the session into its own task folder, `<root>/.tasks/<task>/`, and creates one worktree per repo on first edit. You trigger it yourself; the agent never does.

Requirements: `git` and a POSIX shell. Runs on macOS and Linux.

## Install

```bash
claude plugin marketplace add diego15ag/polyrepo
claude plugin install polyrepo@polyrepo
```

No configuration is needed: the workspace is detected automatically. To pin it to one folder (and disable auto-detection elsewhere), add `--config ws_root=<path>` to the install command, or run `claude plugin configure polyrepo` later.

## Workflows

| Case | How |
|---|---|
| One repo | `cd <root>/<repo> && claude` |
| Several repos | `cd <root> && claude` and describe the task. The agent works out which repos are involved and follows each repo's own conventions. |
| Several repos, in parallel | `cd <root> && claude`, then `/polyrepo:parallel <task>` in each session. Each session works in its own git worktrees under `<root>/.tasks/<task>/`, leaving your checkouts untouched. |
| See diffs | Open `<root>` (or `<root>/.tasks/<task>`) in your editor, or run `git -C <repo> diff`. |

polyrepo doesn't impose a branching, commit or review workflow: that's up to each repo and to you.

## Development

```bash
sh tests/test-ws-map.sh                        # self-contained, no network
claude plugin marketplace add "$PWD"           # local install: edits apply on the next session
claude plugin install polyrepo@polyrepo
```
