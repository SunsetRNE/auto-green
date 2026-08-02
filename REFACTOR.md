# auto-green 重构设计文档

> 本文档记录 2026-08-02 对 auto-green 仓库的重构设计、动机与实施内容，供后续维护参考。

## 一、项目定位

auto-green 是一个基于 GitHub Actions 的**贡献图自动化工具**，通过自动/定时/回填生成 git 提交，
使 GitHub 个人贡献图保持活跃（"绿化"），并支持按图案码在贡献图上绘制图案。

## 二、原仓库问题清单

| # | 问题 | 严重度 | 说明 |
|---|------|--------|------|
| 1 | `green-wall.yml` 第 719 行 `- name:` 缩进错误 | 🔴 致命 | YAML 解析失败，整个工作流无法运行 |
| 2 | `backfill.yml` 与 `backfill-contributions.yml` 高度重复 | 🟠 高 | 90% 逻辑相同，双份维护成本高 |
| 3 | `backfill.yml` 硬编码作者身份 | 🟠 高 | `SunsetRNE` / `z100o190zgxc@163.com` 写死，不可复用 |
| 4 | 日志文件命名不统一 | 🟡 中 | `activity.log` 与 `backfill.log` 并存 |
| 5 | `green-wall.yml` 缺少 `jq` 安装保障 | 🟡 中 | 依赖 runner 预装，环境变化时易碎 |
| 6 | 无 `.gitignore` | 🟡 中 | 无法排除临时/敏感文件 |
| 7 | README 仅一句话 | 🟡 中 | 无使用说明、无参数文档 |
| 8 | 中文目录/长文件名 | 🟢 低 | `辅助申请/辅助申请LSPosed内测（Sunset）.sh` 不便移植 |

## 三、重构设计

### 3.1 目标
- **单一职责**：一个工作流只做一件事，删掉重复实现
- **可复用**：作者身份全部参数化，不硬编码
- **健壮性**：所有 YAML 通过语法校验，依赖显式安装
- **可读性**：英文规范命名 + 完整中文注释 + 统一文档

### 3.2 目标结构

```
auto-green/
├── README.md                     # 完整使用文档
├── REFACTOR.md                   # 本文档
├── .gitignore                    # 排除临时文件
├── activity.log                  # 唯一活动日志
├── tools/
│   └── lsposed-apply.sh          # LSPosed 内测申请辅助脚本（规范化命名）
└── .github/workflows/
    ├── auto-commit.yml           # 每日定时自动提交（保留优化）
    ├── backfill.yml              # 过去日期回填（合并原两份）
    └── green-wall.yml            # 绿墙图案（修复 YAML + 逻辑）
```

### 3.3 各文件设计

#### `auto-commit.yml`
- 保留 `schedule cron: '30 0 * * *'` + `workflow_dispatch`
- 使用 bot 身份提交，追加 `activity.log`，`git pull --rebase` 后推送
- 仅跟踪 `activity.log`，避免误提交

#### `backfill.yml`（合并原 backfill 与 backfill-contributions）
- 输入参数统一：
  - `github_username`：用于"从账号创建开始"模式
  - `verified_email`：作者邮箱（用于精确匹配已有提交）
  - `git_author_name`：提交者名称（默认取用户名）
  - `start_date` / `end_date`：日期范围（可选，自动计算默认值）
  - `from_account_creation`：从账号创建日期开始
  - `dry_run` / `force_push`：测试与强制推送开关
- 检查已有提交：`git log --author=<email> --after --before` 精确匹配（比原版按全部作者更准确）
- 日志统一写入 `activity.log`
- 显式安装 `jq`

#### `green-wall.yml`
- **修复 YAML 缩进**，通过 `actionlint`/`python yaml` 校验
- 三种模式：过去回填 / 未来重复 / 未来图案
- 颜色级别：浅绿(1-3) / 中绿(4-6) / 深绿(7-9) / 更深绿(10-15) / 随机 / 空白
- 修复"目标空白但已有提交"的推迟逻辑（未来模式推迟、过去模式跳过）
- 显式安装 `jq`

#### `tools/lsposed-apply.sh`
- 原 `辅助申请/辅助申请LSPosed内测（Sunset）.sh` 原样迁移（仅路径变更）
- 用途：为 LSPosed 内测申请生成 ed25519 密钥并完成挑战码签名

## 四、实施清单

- [x] 修正 `green-wall.yml` YAML 语法
- [x] 合并 backfill 工作流为单一 `backfill.yml`
- [x] 作者身份参数化（移除硬编码）
- [x] 统一日志文件为 `activity.log`
- [x] 显式安装 `jq`
- [x] 新增 `.gitignore`
- [x] 脚本迁移至 `tools/` 并规范命名
- [x] 重写 README，新增 REFACTOR.md
- [x] YAML 语法校验通过
- [x] 提交并推送远端（覆盖）

## 五、后续建议（非本次范围）

- 可考虑用 `actions/checkout@v5` 升级全部 checkout
- 可将绿色图案模式抽成独立 Python 脚本，便于本地预览图案
- 贡献图风控提示：高频未来提交可能触发 GitHub 风控，建议 `delay_strategy` 至少"轻度"
