#!/bin/bash

# 定义颜色
RED='\033[31m'    # 红色
GREEN='\033[32m'  # 绿色
YELLOW='\033[33m' # 黄色
RESET='\033[0m'   # 重置颜色

# Root权限验证
[ $(id -u) -eq 0 ] || {
	echo -e "${RED}\n必须使用Root权限执行!${RESET}"
	exit 1
}

# 检查 ssh-keygen 是否可用
if ! command -v ssh-keygen >/dev/null 2>&1; then
	echo -e "${RED}\n请使用 MT 管理器扩展包环境执行！${RESET}"
	exit 1
fi

# 记录脚本开始的时间戳
START_TIME=$(date +%s)

# 基础目录
SSH_BASE="/data/local/tmp/.ssh"
mkdir -p "$SSH_BASE"

# 输出修改后的欢迎信息
echo -e "${GREEN}\n欢迎使用辅助申请LSPosed内测（Sunset）\nby 酷安Zsunset_暮雨年秋冬${RESET}\n"
echo -e "${YELLOW}频道链接：https://t.me/Zdayvulnerability (需要魔法上网)${RESET}\n"

# 获取当前时间并格式化
current_time=$(date "+%Y年-%m月-%d日 %H时:%M分:%S秒")
echo -e "${GREEN}当前时间: ${current_time}${RESET}\n"

# ========== 多账户管理 ==========
echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] 正在扫描现有账户...${RESET}"

accounts=()          # 存储账户目录路径
account_names=()     # 存储GitHub用户名（目录名）
account_emails=()    # 存储关联邮箱（从公钥注释提取）

# 遍历 SSH_BASE 下的所有子目录
for dir in "$SSH_BASE"/*/; do
    if [ -d "$dir" ]; then
        username=$(basename "$dir")
        pubkey_file="$dir/id_ed25519.pub"
        email="未知"
        if [ -f "$pubkey_file" ]; then
            # 从公钥中提取注释（通常是邮箱）
            comment=$(awk '{print $3}' "$pubkey_file")
            email="$comment"
        fi
        accounts+=("$dir")
        account_names+=("$username")
        account_emails+=("$email")
    fi
done

# 账户选择逻辑
if [ ${#accounts[@]} -eq 0 ]; then
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] 没有找到现有账户，将创建新账户。${RESET}"
    create_new=true
else
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 找到以下账户：${RESET}"
    for i in "${!accounts[@]}"; do
        echo "$((i+1)). ${account_names[$i]} (邮箱: ${account_emails[$i]})"
    done
    echo "n. 创建新账户"
    echo -e -n "${YELLOW}请选择账户序号或输入 'n' 创建新账户: ${RESET}"
    read choice
    if [[ "$choice" == "n" || "$choice" == "N" ]]; then
        create_new=true
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#accounts[@]} ]; then
        selected_index=$((choice-1))
        selected_dir="${accounts[$selected_index]}"
        selected_username="${account_names[$selected_index]}"
        selected_email="${account_emails[$selected_index]}"
        create_new=false
    else
        echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] 无效选择，退出。${RESET}"
        exit 1
    fi
fi

# 创建新账户
if [ "$create_new" = true ]; then
    echo -e -n "${YELLOW}请输入你的 GitHub 用户名: ${RESET}"
    read NEW_USERNAME
    echo -e -n "${YELLOW}请输入你的 GitHub 关联邮箱: ${RESET}"
    read NEW_EMAIL

    NEW_DIR="$SSH_BASE/$NEW_USERNAME"
    mkdir -p "$NEW_DIR"
    KEY_PATH="$NEW_DIR/id_ed25519"

    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 正在为 $NEW_USERNAME 生成 ed25519 密钥对...${RESET}"
    ssh-keygen -t ed25519 -C "$NEW_EMAIL" -f "$KEY_PATH" -N "" -q
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 密钥生成成功。${RESET}"
    else
        echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] 密钥生成失败，请检查。${RESET}"
        exit 1
    fi

    selected_dir="$NEW_DIR"
    selected_username="$NEW_USERNAME"
    selected_email="$NEW_EMAIL"
fi

# 确认所选账户的密钥存在
if [ ! -f "$selected_dir/id_ed25519" ] || [ ! -f "$selected_dir/id_ed25519.pub" ]; then
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] 错误：所选账户的密钥文件不完整。${RESET}"
    exit 1
fi

# 显示当前使用的账户信息
echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 当前使用账户: ${selected_username} (${selected_email})${RESET}"
echo -e "${GREEN}密钥文件: ${selected_dir}/id_ed25519${RESET}\n"

# 显示公钥，提醒用户添加至 GitHub
echo -e "${GREEN}请将以下公钥内容添加到你的 GitHub 账户中（如果尚未添加）：${RESET}\n"
cat "$selected_dir/id_ed25519.pub"
echo

# 输入挑战码
echo -e -n "${YELLOW}请输入挑战码: ${RESET}"
read CHALLENGE_CODE
echo

# 执行签名
echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 正在使用账户 ${selected_username} 的私钥进行签名...${RESET}"
SIGNED_OUTPUT=$(echo -n "${CHALLENGE_CODE}" | ssh-keygen -Y sign -n lsposed -f "$selected_dir/id_ed25519" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 签名成功。${RESET}"
else
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] 签名失败。${RESET}"
fi

echo -e "${GREEN}签名结果: ${RESET}${SIGNED_OUTPUT}\n"

# 计算并显示执行时间
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 脚本运行完成，总耗时: ${ELAPSED_TIME} 秒${RESET}\n"
