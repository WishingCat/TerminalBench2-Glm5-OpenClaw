# PinkPig97 Remaining42 PASS Tasks

这个目录收纳的是 5 个来自 `remaining42` campaign 的 PASS trial。

这些结果不是原仓库 `z-ai-glm-5-openclaw-terminal-bench-2.0/` 中那 40 个已完成任务的一部分，而是后续在本地持续补跑、并且已经达到 verifier PASS 的交付级 trial，因此单独放在一个 remaining42 supplemental job 目录下，避免与原始批次和上一批 7 个 supplemental trial 混淆。

## Summary

- PASS: 5
- FAIL: 0
- ERROR: 0

## Included tasks

- `constraints-scheduling__PgeVMDU`
- `fix-code-vulnerability__fcXANj3`
- `git-multibranch__4HZ4iZw`
- `sanitize-git-repo__bqJcYjv`
- `sparql-university__ADMEiMy`

## Notes

- 这 5 个 trial 都保留 `config.json`、`result.json`、`trial.log`、`agent/trajectory.json` 和 `verifier/`，可直接复核。
- 这些结果全部来自 `remaining42` lane-based rerun，而不是原始 40-task 单批次运行。
- 这批结果全部为 PASS，因此 `result.json` 中的 reward 都是 `1.0`。
