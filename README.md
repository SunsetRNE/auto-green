# auto-green 🟢

基于 GitHub Actions 的**贡献图自动化工具**：自动提交、历史回填、绿墙图案，让贡献图保持活跃。

> 绿色，用于提交贡献

## ✨ 功能总览

| 工作流 | 触发方式 | 功能 |
|--------|----------|------|
| [`auto-commit.yml`](.github/workflows/auto-commit.yml) | 每日定时 / 手动 | 每天自动追加一条提交，保持贡献图每日有绿点 |
| [`backfill.yml`](.github/workflows/backfill.yml) | 手动（Actions 页面） | 按日期范围**回填**缺失日期的提交，可自定义作者与日期区间 |
| [`green-wall.yml`](.github/workflows/green-wall.yml) | 手动（Actions 页面） | **绿墙/图案模式**：过去填充、未来重复、按图案码绘制贡献图 |

辅助工具：

| 脚本 | 用途 |
|------|------|
| [`tools/lsposed-apply.sh`](tools/lsposed-apply.sh) | LSPosed 内测申请辅助：多账户 ed25519 密钥管理 + 挑战码签名（需 root + ssh-keygen 环境） |

## 🚀 快速开始

### 1. 每日自动提交（最简单）

1. Fork 本仓库（或在 Actions 页启用工作流）
2. 无需任何配置，`auto-commit.yml` 每天 **UTC 00:30（北京时间 08:30）** 自动运行
3. 也可在 **Actions → Auto Commit → Run workflow** 手动触发

### 2. 回填历史贡献

在 **Actions → Backfill Contributions → Run workflow** 填写参数：

| 参数 | 必填 | 说明 |
|------|------|------|
| `github_username` | 选填 | 用于"从账号创建开始"模式 |
| `verified_email` | ✅ | 已在 GitHub 验证的邮箱（**未验证不计入贡献图**） |
| `git_author_name` | 选填 | 提交者名称，默认用用户名 |
| `start_date` | 选填 | 开始日期 `YYYY-MM-DD`，默认 1 年前 |
| `end_date` | 选填 | 结束日期 `YYYY-MM-DD`，默认昨天 |
| `from_account_creation` | 选填 | 从账号创建日期开始（忽略 start_date） |
| `dry_run` | 选填 | 干运行，只检查不提交 |
| `force_push` | 选填 | 强制推送 `--force-with-lease`（慎用） |

### 3. 绿墙图案

在 **Actions → 智能绿墙-图案完全体 → Run workflow** 填写参数：

| 参数 | 说明 |
|------|------|
| `git_user_name` / `git_user_email` | 提交作者（邮箱需已验证） |
| `mode` | 三种模式：**过去提交填充** / **未来重复提交** / **未来图案提交** |
| `color_level` | 深浅：浅绿(1-3) / 中绿(4-6) / 深绿(7-9) / 更深绿(10-15) / 随机 / 空白 |
| `pattern_code` | 图案码：`0`=空白，`1`=浅绿，`2`=中绿，`3`=深绿，`4`=更深绿；多行输入自动拼接 |
| `delay_strategy` | 提交速度延缓策略（无/轻度/中度/重度），**建议至少"轻度"避免风控** |
| `dry_run` / `force_push` | 测试 / 强制推送开关 |

**图案码示例**（7x7 爱心 → 未来图案模式）：

```
1111111
1222221
1233321
1234321
1233321
1222221
1111111
```

## ⚠️ 注意事项

- **邮箱验证**：提交作者邮箱必须在 https://github.com/settings/emails 中验证，否则贡献不计入
- **未来提交**：提交日期在未来会被计入"未来贡献"并随日期推进显示，但**高频批量提交可能触发 GitHub 风控**，建议配合 `delay_strategy` 使用
- **强制推送**：`force_push` 会重写历史，仅限仓库唯一作者时使用
- **贡献刷新**：贡献图更新可能有几分钟到一小时延迟

## 📁 目录结构

```
auto-green/
├── README.md              # 本文档
├── REFACTOR.md            # 重构设计文档
├── activity.log           # 活动日志（自动提交写入）
├── .gitignore
├── tools/
│   └── lsposed-apply.sh   # LSPosed 内测申请辅助脚本
└── .github/workflows/
    ├── auto-commit.yml    # 每日自动提交
    ├── backfill.yml       # 历史回填
    └── green-wall.yml     # 绿墙图案
```

## 📜 许可

本项目仅供学习与个人使用。请合理使用，遵守 GitHub 服务条款，避免滥用自动化功能。