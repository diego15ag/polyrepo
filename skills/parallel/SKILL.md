---
name: parallel
description: Run this multi-repo task in an isolated task folder with git worktrees, so other sessions can work in parallel.
disable-model-invocation: true
argument-hint: <task-name> [task description]
---
For THIS session, override the default multi-repo flow. Never edit files or switch branches in `<ROOT>/<repo>`. Keep every message to the user short.

1. Arguments: `$ARGUMENTS`. The first word is the task name (if empty, ask for one); anything after it is the task. Task folder: `<ROOT>/.tasks/<task>/` (if it exists, ask for another name).
   If no task was given, create nothing, never infer work from the name, and reply only: "Parallel mode on (`<task>`). What's the task?"
2. Work out which repos the task involves yourself, from the workspace map and the repos' docs and code. Ask only if you genuinely can't tell.
3. Read freely from the main checkouts. Create a worktree only right before your first edit to a repo:
   `git -C <ROOT>/<repo> fetch origin <default>`
   `git -C <ROOT>/<repo> worktree add <ROOT>/.tasks/<task>/<repo> -b <task> origin/<default>`
   (git needs a branch per worktree; `<task>` is just its local name.) From then on, work on that repo only inside its worktree. Install dependencies there if needed.
4. How the work is integrated (commits, merge requests, pushing to trunk…) follows the repo's conventions and the user's instructions, not this skill.
5. When done: one line per repo with what changed, the task folder path, and one review command (`git -C <worktree> diff`). End with one line: "Want me to clean up when you're done?" Show the cleanup commands only if the user asks for them.
   Cleanup = `git -C <ROOT>/<repo> worktree remove <ROOT>/.tasks/<task>/<repo>` per repo, `git -C <ROOT>/<repo> branch -D <task>`, then remove the empty task folder. Run it only after the user explicitly says yes.
   **`--force` and `branch -D` on unmerged commits always need their own yes**, after you name exactly what would be lost, even if the user already asked to clean up or discard.
