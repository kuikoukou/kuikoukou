#!/bin/bash

# Kali Linux 一键换源+工具安装脚本
# 集成镜像源切换与安全工具安装功能
# 最后更新：2024年1月

# 检查root权限
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[31m请使用 sudo 运行此脚本！\033[0m"
    exit 1
fi

# ------------------------ 换源部分 ------------------------
echo -e "\n\033[34m[ 正在执行换源操作 ]\033[0m"

# 自动备份源文件
backup_file="/etc/apt/sources.list.$(date +%Y%m%d%H%M%S).bak"
if cp /etc/apt/sources.list "$backup_file"; then
    echo -e "\033[32m原文件已备份至 $backup_file\033[0m"
else
    echo -e "\033[31m备份失败，请检查权限！\033[0m"
    exit 1
fi

# 镜像源选择菜单
echo -e "\n可选镜像源："
echo "1) 阿里云（推荐）"
echo "2) 中科大"
echo "3) 清华大学"
read -p "请选择镜像源 [1-3] (默认1): " mirror_choice
mirror_choice=${mirror_choice:-1}

case $mirror_choice in
    1)
        mirror_url="https://mirrors.aliyun.com/kali"
        ;;
    2)
        mirror_url="https://mirrors.ustc.edu.cn/kali"
        ;;
    3)
        mirror_url="https://mirrors.tuna.tsinghua.edu.cn/kali"
        ;;
    *)
        echo -e "\033[31m无效选择，使用默认阿里云镜像\033[0m"
        mirror_url="https://mirrors.aliyun.com/kali"
        ;;
esac

# 写入新源配置
cat > /etc/apt/sources.list << EOF
# 默认使用https源
deb ${mirror_url} kali-rolling main contrib non-free non-free-firmware
# 源代码镜像
# deb-src ${mirror_url} kali-rolling main contrib non-free non-free-firmware
EOF

# 更新软件源
echo -e "\n\033[33m正在更新软件列表...\033[0m"
if ! apt update -qq; then
    echo -e "\033[31m更新失败，请检查："
    echo "1. 网络连接状态"
    echo "2. 防火墙设置"
    echo "3. 可尝试更换其他镜像源\033[0m"
    exit 1
fi

# ------------------------ 工具安装部分 ------------------------
echo -e "\n\033[34m[ 正在准备工具安装 ]\033[0m"

# 工具套件菜单
echo -e "\n可选工具套件："
echo "1) 核心工具集 [500MB] (基础渗透工具)"
echo "2) 默认工具集 [3GB] (常规渗透工具，推荐)"
echo "3) 完整工具集 [15GB] (所有预装工具)"
echo "4) 无线渗透工具"
echo "5) Web渗透工具"
echo "6) 自定义选择"
read -p "请选择要安装的套件 [1-6] (默认2): " pkg_choice
pkg_choice=${pkg_choice:-2}

case $pkg_choice in
    1) packages="kali-linux-core" ;;
    2) packages="kali-linux-default" ;;
    3) packages="kali-linux-full" ;;
    4) packages="kali-tools-wireless" ;;
    5) packages="kali-tools-web" ;;
    6)
        echo -e "\n可用套件列表："
        apt list kali-tools-* 2>/dev/null | grep -oP 'kali-tools-\w+' | uniq
        read -p "请输入要安装的套件名称（空格分隔多个）: " packages
        ;;
    *)
        echo -e "\033[31m无效选择，安装默认工具集\033[0m"
        packages="kali-linux-default"
        ;;
esac

# 安装确认
echo -e "\n\033[33m即将安装：\033[0m"
echo -e "\033[36m${packages}\033[0m"
read -p "确认安装？[Y/n] " confirm
confirm=${confirm:-Y}

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "\033[33m安装已取消\033[0m"
    exit 0
fi

# 执行安装
echo -e "\n\033[34m[ 开始安装工具 ]\033[0m"
if ! apt install -y $packages; then
    echo -e "\033[31m安装失败，可能原因："
    echo "1. 磁盘空间不足（至少需要20GB剩余空间）"
    echo "2. 网络连接不稳定"
    echo "3. 可尝试重新运行脚本\033[0m"
    exit 1
fi

# 安装后清理
echo -e "\n\033[34m[ 执行清理 ]\033[0m"
apt autoremove -y
apt clean

# 验证安装
echo -e "\n\033[32m安装完成！已安装工具统计：\033[0m"
dpkg -l | grep '^ii' | wc -l

echo -e "\n\033[36m常用工具路径："
echo "----------------------------------------"
echo "Nmap扫描器    : /usr/bin/nmap"
echo "Metasploit    : /usr/share/metasploit-framework"
echo "Wireshark     : /usr/bin/wireshark"
echo "Burp Suite    : /usr/bin/burpsuite"
echo "John破解工具  : /usr/sbin/john"
echo "----------------------------------------\033[0m"

# 创建桌面快捷方式
echo -e "\n\033[33m是否创建桌面快捷方式？[Y/n]\033[0m"
read -p "选择：" shortcut
shortcut=${shortcut:-Y}
if [[ $shortcut =~ ^[Yy]$ ]]; then
    cp /usr/share/applications/kali-*.desktop ~/Desktop/ 2>/dev/null
    echo -e "\033[32m快捷方式已创建到桌面\033[0m"
fi