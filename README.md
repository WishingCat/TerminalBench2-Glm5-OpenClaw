# Terminal-Bench 2.0 Evaluation: GLM-5 + OpenClaw

使用 [Harbor](https://github.com/laude-institute/harbor) 框架在 [Terminal-Bench 2.0](https://github.com/laude-institute/terminal-bench) (89 题) 上评测 **z-ai/glm-5** 模型，Agent 为 OpenClaw。

## 评测概况

| 指标 | 数值 |
|------|------|
| 模型 | z-ai/glm-5 (via OpenAI-compatible API) |
| Agent | OpenClaw |
| 基准 | Terminal-Bench 2.0 (89 tasks) |
| 已完成 | 40 / 89 |
| 运行环境 | macOS ARM (Docker + Rosetta amd64 emulation) |
| 并发数 | 2 |
| 日期 | 2026-04-13 ~ 2026-04-14 |

## 结果汇总

| 分类 | 数量 | 说明 |
|------|------|------|
| PASS | 15 | 模型成功完成任务 (reward=1.0) |
| FAIL | 20 | 模型运行但未通过验证 (reward=0.0 或 verifier 无输出) |
| ERROR | 5 | 基础设施问题，模型未获得公平的尝试机会 |
| 未运行 | 49 | 尚未执行 |

**通过率 (全部已完成)**: 15 / 40 = **37.5%**

**通过率 (排除基础设施错误)**: 15 / 35 = **42.9%**

## 详细结果

### PASS (15)

| 任务 | Agent 用时 | 总用时 | 备注 |
|------|-----------|--------|------|
| cobol-modernization | 15m00s | 20m57s | AgentTimeoutError (超时但已完成) |
| configure-git-webserver | 14m59s | 21m06s | AgentTimeoutError (超时但已完成) |
| crack-7z-hash | 8m34s | 15m13s | |
| custom-memory-heap-crash | 6m03s | 13m08s | |
| fix-git | 1m41s | 23m37s | |
| largest-eigenval | 9m37s | 15m25s | |
| log-summary-date-ranges | 1m51s | 7m35s | |
| merge-diff-arc-agi-task | 6m27s | 12m30s | |
| modernize-scientific-stack | 1m04s | 7m08s | |
| multi-source-data-merger | 2m02s | 8m09s | |
| password-recovery | 14m59s | 21m05s | AgentTimeoutError (超时但已完成) |
| portfolio-optimization | 2m21s | 8m57s | |
| prove-plus-comm | 1m11s | 7m25s | |
| pypi-server | 15m00s | 20m44s | AgentTimeoutError (超时但已完成) |
| pytorch-model-cli | 12m45s | 20m05s | |

### FAIL (20)

| 任务 | Agent 用时 | 总用时 | 备注 |
|------|-----------|--------|------|
| adaptive-rejection-sampler | 3m01s | 9m21s | |
| break-filter-js-from-html | 20m00s | 26m22s | AgentTimeoutError |
| caffe-cifar-10 | 6m41s | 13m15s | |
| chess-best-move | 1m12s | 7m18s | |
| db-wal-recovery | 4m39s | 20m21s | |
| distribution-search | 5m50s | 11m40s | |
| feal-linear-cryptanalysis | 6m10s | 18m13s | |
| gpt2-codegolf | 15m00s | 22m13s | AgentTimeoutError |
| headless-terminal | 2m11s | 13m52s | |
| llm-inference-batching-scheduler | 1m58s | 7m50s | |
| mteb-retrieve | 1m51s | 28m50s | |
| overfull-hbox | 5m00s | 30m03s | RewardFileNotFoundError |
| path-tracing | 22m26s | 28m09s | RewardFileNotFoundError |
| path-tracing-reverse | 21m45s | 27m28s | RewardFileNotFoundError |
| polyglot-rust-c | 14m59s | 37m28s | AgentTimeoutError |
| regex-chess | 10m41s | 16m29s | |
| reshard-c4-data | 14m40s | 23m33s | |
| torch-tensor-parallelism | 1m25s | 12m38s | |
| winning-avg-corewars | 20m10s | 25m35s | RewardFileNotFoundError |
| write-compressor | 4m41s | 11m42s | |

### ERROR (5) - 基础设施问题

| 任务 | 错误类型 | 总用时 | 原因 |
|------|---------|--------|------|
| build-pov-ray | CancelledError | 12m06s | 手动终止 Harbor 时被取消 |
| compile-compcert | RuntimeError | 11m25s | apt-get 网络故障 (Connection failed) |
| hf-model-inference | EnvironmentStartTimeoutError | 80m01s | Docker 镜像过大，拉取超时 |
| qemu-startup | CancelledError | 28m48s | 手动终止 Harbor 时被取消 |
| schemelike-metacircular-eval | AgentSetupTimeoutError | 24m11s | npm install 超时 (Rosetta 模拟慢) |

## 错误分类规则

- **PASS**: reward = 1.0
- **FAIL**: 模型有运行机会但未通过
  - reward = 0.0 (验证未通过)
  - AgentTimeoutError (模型超时但未解决)
  - RewardFileNotFoundError / RewardFileEmptyError (验证器无输出)
- **ERROR**: 基础设施故障，模型未获得公平机会
  - EnvironmentStartTimeoutError (Docker 镜像拉取/启动超时)
  - AgentSetupTimeoutError (OpenClaw 安装超时)
  - CancelledError (被手动取消)
  - RuntimeError (网络/系统故障)

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
- 4 个 PASS 任务虽触发了 AgentTimeoutError，但在超时前已完成答题并通过验证
- 4 个 FAIL 任务因 RewardFileNotFoundError 失败，可能是验证脚本执行异常
- 49 个任务尚未运行，后续可通过 `harbor run` 的 resume 功能继续
