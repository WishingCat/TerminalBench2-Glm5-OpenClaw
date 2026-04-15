# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Benchmark workspace for running **Terminal-Bench 2.0** (89 tasks) using Harbor's OpenClaw agent with the `z-ai/glm-5` model. Harbor source is a local checkout of PR #879 (`harbor-openclaw/`, branch `pr-879-openclaw`).

**Current status**: 40/89 tasks completed (15 PASS, 20 FAIL, 5 ERROR). 49 tasks remain. See `README.md` for full breakdown.

## What's in git vs. local-only

The git repo (`origin` → `github.com:WishingCat/TerminalBench2-Glm5-OpenClaw`) tracks **only results**:
- `jobs/z-ai-glm-5-openclaw-terminal-bench-2.0/` — PASS and FAIL trial dirs (ERROR trials excluded)
- `README.md`, `.gitignore`, `CLAUDE.md`

**Not tracked** (local only): `harbor-openclaw/`, `scripts/`, `results/`, `.venv/`, `AGENTS.md`

## Setup

```bash
source .venv/bin/activate
export OPENAI_API_KEY='...'
export OPENAI_BASE_URL='https://openai.sufy.com/v1'
```

The `.venv` has Harbor installed in editable mode (`pip install -e ./harbor-openclaw openai`).

## Commands

```bash
# Test API connectivity
python scripts/preflight_glm_openai_compatible.py

# Single-task smoke test (1 task in Docker)
bash scripts/run_harbor_preflight.sh

# Full benchmark (all 89 tasks)
bash scripts/run_full_benchmark.sh
# With higher concurrency:
N_CONCURRENT=4 bash scripts/run_full_benchmark.sh

# Summarize results → results/*.md + results/*.csv
bash scripts/summarize_results.sh
```

### Resuming a partial run with `harbor run`

`run_full_benchmark.sh` refuses to resume an existing job directory. To resume, call Harbor directly:

```bash
harbor run \
  --job-name z-ai-glm-5-openclaw-terminal-bench-2.0 \
  --jobs-dir "$(pwd)/jobs" \
  -d terminal-bench@2.0 -a openclaw -m openai/z-ai/glm-5 \
  -n 2 -k 1 -e docker \
  --agent-setup-timeout-multiplier 4 --environment-build-timeout-multiplier 4
```

**Critical**: `--jobs-dir` must use the **absolute path** (not relative `./jobs`), and all CLI args must exactly match the stored `config.json`. Harbor compares configs field-by-field on resume; any mismatch (including `jobs_dir` path format) triggers `FileExistsError`.

When changing config fields (e.g., `n_concurrent_trials`, `environment_build_timeout_multiplier`), you must update both:
1. The job-level `config.json`
2. Every existing trial's `config.json` (`*__*/config.json`) — Harbor uses `TrialConfig` equality during `_init_remaining_trial_configs()` and will crash with `ValueError: list.remove(x): x not in list` if trial configs don't match.

## Architecture

```
.
├── harbor-openclaw/          # Harbor framework source (editable install)
│   ├── src/harbor/
│   │   ├── agents/installed/ # Agent implementations + install-*.sh.j2 templates
│   │   ├── environments/docker/  # Docker compose orchestration
│   │   ├── trial/trial.py    # Trial lifecycle: env start → agent setup → run → verify
│   │   └── job.py            # Job resume logic (config comparison at line 205)
│   └── CLAUDE.md             # Detailed Harbor framework docs
├── scripts/                  # Workflow automation (see Commands above)
├── jobs/                     # Harbor output: one subdir per job, trial dirs inside
│   └── {job-name}/
│       ├── config.json       # Job-level config (must match CLI on resume)
│       └── {task}___{id}/    # Per-trial: config.json, result.json, logs/
└── results/                  # Summarized reports (.md, .csv)
```

### Trial execution flow (per task)

Each trial runs in a fresh Docker container built from the task's Dockerfile:

1. **Environment start** — build or pull task Docker image, `docker compose up`
2. **Agent setup** — uploads and runs `install-openclaw.sh.j2` inside the container (installs Node.js + OpenClaw from scratch every time, typically 2-6 min)
3. **Agent run** — OpenClaw executes the task instruction against GLM-5
4. **Verification** — runs task's `test.sh`, writes reward to `/logs/verifier/reward.txt`

There is no agent caching across trials — OpenClaw is reinstalled for every task because each uses a different Docker image.

### Result structure

Reward is nested: `result['verifier_result']['rewards']['reward']` (not `result['reward']`).

Exception info is at `result['exception_info']['exception_type']` (a dict, not a top-level field).

### Error classification for summaries

- `AgentTimeoutError`, `RewardFileNotFoundError`, `RewardFileEmptyError` — **Failed** (model ran but didn't solve it)
- `AgentSetupTimeoutError`, `EnvironmentStartTimeoutError`, `CancelledError`, `RuntimeError`, `ValueError` — **Error** (infrastructure issue, model never got a chance)

## Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `OPENAI_API_KEY` | Yes | GLM-5 authentication |
| `OPENAI_BASE_URL` | Yes | `https://openai.sufy.com/v1` |
| `N_CONCURRENT` | No | Parallel trials (default: 1) |
| `AGENT_SETUP_TIMEOUT_MULTIPLIER` | No | Multiplier on 360s base (default: 4) |
| `ENVIRONMENT_BUILD_TIMEOUT_MULTIPLIER` | No | Multiplier on Docker build timeout |
| `OPENCLAW_THINKING` | No | e.g., `medium` |
| `OPENCLAW_CONTEXT_WINDOW` | No | e.g., `128000` |
| `OPENCLAW_MAX_TOKENS` | No | e.g., `8192` |

**Never write API keys to files.** Pass them only via shell environment.
