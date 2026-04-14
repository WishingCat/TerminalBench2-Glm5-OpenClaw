# PinkPig97 Additional Completed Tasks

这个目录收纳的是 7 个补充 trial，它们不属于原仓库 `z-ai-glm-5-openclaw-terminal-bench-2.0/` 中那 40 个已完成任务。

这些结果来自本地多次独立补跑，并统一筛选为“至少具备 `result.json`、`agent/trajectory.json`、`verifier/`”的可复核产物，因此单独放在一个 supplemental job 目录下，避免与原作者的单次批跑混淆。

## Summary

- PASS: 5
- FAIL: 2
- ERROR: 0

## Included tasks

- `git-leak-recovery__fgTmYgL`
- `install-windows-3.11__UKXuJS7`
- `large-scale-text-editing__m6FG8kf`
- `nginx-request-logging__BvRHNWt`
- `openssl-selfsigned-cert__hbBzjc2`
- `regex-log__CndMfJu`
- `vulnerable-secret__y8y2RNZ`

## Notes

- 这些 trial 的目录结构与原仓库总体一致，均保留 `config.json`、`result.json`、`trial.log`、`agent/trajectory.json` 和 `verifier/`。
- 因为来源于不同本地 runner 版本，部分 trial 不包含 `agent/openclaw-output.txt` 或 `agent/openclaw-session.jsonl`。
- `install-windows-3.11__UKXuJS7` 的 `result.json` 缺少 phase-level timestamps，但 reward / verifier 输出完整，可正常归类为 FAIL。
