# Terminal-Bench 2.0 Evaluation: GLM-5 + OpenClaw

使用 [Harbor](https://github.com/laude-institute/harbor) 框架在 [Terminal-Bench 2.0](https://github.com/laude-institute/terminal-bench) (89 题) 上评测 **z-ai/glm-5** 模型，Agent 为 OpenClaw。

## 评测概况

| 指标 | 数值 |
|------|------|
| 模型 | z-ai/glm-5 (via OpenAI-compatible API) |
| Agent | OpenClaw |
| 基准 | Terminal-Bench 2.0 (89 tasks) |
| 已完成 | 89 / 89 |
| 运行环境 | macOS ARM (Docker + Rosetta amd64 emulation) |
| 并发数 | 2 |
| 日期 | 2026-04-13 ~ 2026-04-16 |

## 结果汇总

| 分类 | 数量 | 说明 |
|------|------|------|
| PASS | 37 | 模型成功完成任务 (reward=1.0) |
| FAIL | 52 | 模型运行但未通过验证 (reward=0.0 或 verifier 无输出) |

**通过率**: 37 / 89 = **41.6%**

## 详细结果

### PASS (37)

| 任务 | Agent 用时 | 总用时 | 备注 |
|------|-----------|--------|------|
| bn-fit-modify | 6m05s | 10m58s | |
| build-pmars | 6m39s | 11m41s | |
| cobol-modernization | 15m00s | 20m57s | AgentTimeoutError (超时但已完成) |
| code-from-image | 4m29s | 8m20s | |
| compile-compcert | 37m06s | 40m26s | |
| configure-git-webserver | 14m59s | 21m06s | AgentTimeoutError (超时但已完成) |
| constraints-scheduling | 3m00s | 6m10s | |
| crack-7z-hash | 8m34s | 15m13s | |
| custom-memory-heap-crash | 6m03s | 13m08s | |
| financial-document-processor | 6m39s | 10m52s | |
| fix-code-vulnerability | 5m07s | 8m51s | |
| fix-git | 1m41s | 23m37s | |
| fix-ocaml-gc | 42m01s | 64m40s | |
| hf-model-inference | 2m15s | 11m05s | |
| kv-store-grpc | 15m00s | 18m29s | AgentTimeoutError (超时但已完成) |
| large-scale-text-editing | 11m41s | 16m39s | |
| largest-eigenval | 9m37s | 15m25s | |
| log-summary-date-ranges | 1m51s | 7m35s | |
| mailman | 30m00s | 34m26s | AgentTimeoutError (超时但已完成) |
| mcmc-sampling-stan | 14m57s | 20m19s | |
| merge-diff-arc-agi-task | 6m27s | 12m30s | |
| modernize-scientific-stack | 1m04s | 7m08s | |
| multi-source-data-merger | 2m02s | 8m09s | |
| nginx-request-logging | 1m57s | 6m11s | |
| password-recovery | 14m59s | 21m05s | AgentTimeoutError (超时但已完成) |
| portfolio-optimization | 2m21s | 8m57s | |
| prove-plus-comm | 1m11s | 7m25s | |
| pypi-server | 15m00s | 20m44s | AgentTimeoutError (超时但已完成) |
| pytorch-model-cli | 12m45s | 20m05s | |
| pytorch-model-recovery | 8m18s | 27m49s | |
| regex-log | 5m38s | 9m46s | |
| sanitize-git-repo | 4m22s | 8m48s | |
| sparql-university | 5m21s | 9m53s | |
| sqlite-db-truncate | 8m11s | 12m19s | |
| sqlite-with-gcov | 15m37s | 20m47s | AgentTimeoutError (超时但已完成) |
| tune-mjcf | 9m27s | 13m49s | |
| vulnerable-secret | 2m40s | 7m08s | |

### FAIL (52)

| 任务 | Agent 用时 | 总用时 | 备注 |
|------|-----------|--------|------|
| adaptive-rejection-sampler | 3m01s | 9m21s | |
| break-filter-js-from-html | 20m00s | 26m22s | AgentTimeoutError |
| build-cython-ext | 15m00s | 19m26s | AgentTimeoutError |
| build-pov-ray | 16m12s | 19m12s | |
| caffe-cifar-10 | 6m41s | 13m15s | |
| cancel-async-tasks | 0m55s | 5m16s | |
| chess-best-move | 1m12s | 7m18s | |
| circuit-fibsqrt | 20m59s | 25m09s | |
| count-dataset-tokens | 8m03s | 11m44s | |
| db-wal-recovery | 4m39s | 20m21s | |
| distribution-search | 5m50s | 11m40s | |
| dna-assembly | 10m40s | 15m52s | |
| dna-insert | 3m08s | 14m27s | |
| extract-elf | 14m59s | 19m10s | |
| extract-moves-from-video | 27m11s | 31m26s | |
| feal-differential-cryptanalysis | 30m00s | 39m39s | AgentTimeoutError |
| feal-linear-cryptanalysis | 6m10s | 18m13s | |
| filter-js-from-html | 1m36s | 5m54s | |
| gcode-to-text | 2m39s | 5m30s | |
| git-leak-recovery | 1m51s | 6m02s | |
| git-multibranch | 5m06s | 8m08s | |
| gpt2-codegolf | 15m00s | 22m13s | AgentTimeoutError |
| headless-terminal | 2m11s | 13m52s | |
| install-windows-3.11 | 60m00s | 66m37s | AgentTimeoutError |
| llm-inference-batching-scheduler | 1m58s | 7m50s | |
| make-doom-for-mips | 12m03s | 16m59s | |
| make-mips-interpreter | 4m56s | 9m58s | |
| model-extraction-relu-logits | 2m29s | 6m40s | |
| mteb-leaderboard | 34m54s | 40m21s | |
| mteb-retrieve | 1m51s | 28m50s | |
| openssl-selfsigned-cert | 2m26s | 10m17s | |
| overfull-hbox | 5m00s | 30m03s | RewardFileNotFoundError |
| path-tracing | 22m26s | 28m09s | RewardFileNotFoundError |
| path-tracing-reverse | 21m45s | 27m28s | RewardFileNotFoundError |
| polyglot-c-py | 4m04s | 8m38s | |
| polyglot-rust-c | 14m59s | 37m28s | AgentTimeoutError |
| protein-assembly | 20m24s | 24m11s | |
| qemu-alpine-ssh | 2m54s | 6m31s | |
| qemu-startup | 14m59s | 18m10s | AgentTimeoutError |
| query-optimize | 11m58s | 21m43s | |
| raman-fitting | 7m09s | 11m02s | |
| regex-chess | 10m41s | 16m29s | |
| reshard-c4-data | 14m40s | 23m33s | |
| rstan-to-pystan | 19m18s | 21m44s | |
| sam-cell-seg | 5m18s | 11m49s | |
| schemelike-metacircular-eval | 2m07s | 5m24s | |
| torch-pipeline-parallelism | 14m59s | 24m09s | AgentTimeoutError |
| torch-tensor-parallelism | 1m25s | 12m38s | |
| train-fasttext | 60m00s | 92m46s | AgentTimeoutError |
| video-processing | 2m42s | 18m37s | |
| winning-avg-corewars | 20m10s | 25m35s | RewardFileNotFoundError |
| write-compressor | 4m41s | 11m42s | |

## 错误分类规则

- **PASS**: reward = 1.0
- **FAIL**: 模型有运行机会但未通过
  - reward = 0.0 (验证未通过)
  - AgentTimeoutError (模型超时但未解决)
  - RewardFileNotFoundError / RewardFileEmptyError (验证器无输出)

## 目录结构

```
jobs/z-ai-glm-5-openclaw-terminal-bench-2.0/
├── config.json                        # Job 配置
├── result.json                        # Job 级汇总
├── job.log                            # 运行日志
└── {task-name}__{id}/                 # 每个 trial 的结果
    ├── config.json                    # Trial 配置
    ├── result.json                    # Trial 结果 (reward, timing, exception)
    ├── trial.log                      # Trial 日志
    ├── agent/                         # Agent 执行记录
    │   ├── setup/                     # OpenClaw 安装日志
    │   ├── openclaw-output.txt        # Agent 输出
    │   ├── openclaw-session.jsonl     # Agent 会话记录
    │   └── command-*/                 # Agent 执行的命令及输出
    └── verifier/                      # 验证结果
        ├── reward.txt                 # 分数 (0.0 或 1.0)
        ├── test-stdout.txt            # 测试输出
        └── ctrf.json                  # 结构化测试报告
```

## 运行配置

```json
{
  "model": "openai/z-ai/glm-5",
  "agent": "openclaw",
  "n_concurrent_trials": 2,
  "timeout_multiplier": 1.0,
  "agent_setup_timeout_multiplier": 4.0,
  "environment_build_timeout_multiplier": 4.0
}
```

## 备注

- 所有任务在 macOS ARM 上通过 Docker Desktop (Rosetta amd64 emulation) 运行，Agent 安装耗时较长 (5-24 分钟)
- 8 个 PASS 任务虽触发了 AgentTimeoutError，但在超时前已完成答题并通过验证
- 4 个 FAIL 任务因 RewardFileNotFoundError 失败，可能是验证脚本执行异常
- 首轮运行有 8 个 ERROR（基础设施问题），重跑后全部消除：3 个转为 PASS，5 个转为 FAIL
