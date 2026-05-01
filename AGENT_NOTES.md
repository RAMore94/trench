# Notes for Claude agents working on this repo

If you are a Claude Code instance (cloud agent, IDE assistant, web Claude, anything) about to touch this repo, **read this first**. It will save you and the human a lot of pain.

## What this repo is

Single-file HTML browser game — `trench.html` (~2100 lines). A campaign-driven war simulator: tactical battles + strategic map of historical Europe. The full design lives in `design_doc.txt`. Recent build history is in `changelog.txt`. The whole game is in one HTML file by design — **do not split it into multiple files** unless the human explicitly asks.

The human (Aaron, owner: RAMore94) develops this from a Windows desktop. He uses Claude in multiple places (desktop CLI, work machine without desktop access, etc.), so different Claude instances may end up touching this repo without realizing other instances exist.

## The 3-agent daily system

A scheduled-routine pipeline runs every day in Anthropic's cloud, handing off via files in `daily-todo/`:

| Time (MDT) | Agent    | Reads                                   | Writes                                  |
|------------|----------|-----------------------------------------|-----------------------------------------|
| 7:00 AM    | Planner  | design_doc, changelog, trench.html      | `daily-todo/YYYY-MM-DD-todo.md`         |
| 11:00 AM   | Executor | today's todo file, trench.html          | edits trench.html, `YYYY-MM-DD-done.md` |
| 1:00 PM    | Reviewer | today's todo + done + git diff          | auto-fixes trench.html, `…-review.md`   |

Each agent commits and pushes its output. The next agent pulls before starting, so files are the handoff mechanism. **If you commit work outside this pipeline, push it to GitHub** so the next morning's Planner sees it — otherwise it'll get lost when local resets to remote (which has happened).

## Conventions to respect

1. **Don't reset or revert work you didn't author** without checking git log and (ideally) asking. The Planner's TODO and the Executor's edits look "unexpected" from a cold start, but they're intentional. Same for any uncommitted local changes — they may be the human's in-progress work.
2. **Single-file architecture.** All game code stays in `trench.html`. No new JS/CSS files, no build step, no dependencies. The whole game must open in a browser by double-clicking the file.
3. **Preserve the `G` global state object** and the `setPhase()` phase router. They're load-bearing — the campaign layer, recruitment, battle, and results all coordinate through them.
4. **Commit early, push always.** If you make changes and don't push, the next agent (or the human's local pull) will see stale state. Lost work has already burned a day on this repo.
5. **Don't add comments explaining what code does** — the human prefers terse code. Only add comments for non-obvious *why*.
6. **No emoji in code or commit messages** unless explicitly requested.

## Phased roadmap (current state)

We're between v3.0 (campaign vertical slice — done) and v3.1 (gaps to fix). The known v3.1 gaps the Planner draws from:

- **Undefended region capture** — `endWeek()` should flip ownership when an army moves into an empty enemy region. Currently only handles army-vs-army battles.
- **Prussia doesn't rebuild** — once the AI's army is destroyed, no new ones spawn. Should spawn one at Berlin each new season.
- **Campaign continuation** — after a battle win, player army should stay on the map and keep marching to the next objective region.

Then Phase 1 leftovers (auto-resolve UI, fatigue, weather, fortifications) → Phase 1.5 (equipment system) → Phase 2 (deeper economy).

## If something seems off

- **No `daily-todo/YYYY-MM-DD-todo.md` for today?** The Planner didn't fire or its push failed. Check https://claude.ai/code/routines/ for run status. Don't generate a TODO yourself unless asked.
- **Local files don't match GitHub?** Run `git status` and `git log -5` before assuming anything was lost. The human may be mid-edit.
- **Agent commits missing from GitHub?** Push from the cloud agent likely failed (auth, network). Surface this to the human; do not silently retry from your side.

## Repo info

- GitHub: https://github.com/RAMore94/trench
- Default branch: `master`
- The 3 daily routines belong to the human's claude.ai account; they can be viewed/edited at https://claude.ai/code/routines/

Last updated: 2026-04-27
