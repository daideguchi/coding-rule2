#!/bin/bash

# =============================================================================
# プラットフォーム検出スクリプト
# OS・アーキテクチャ・パッケージマネージャーを自動検出
# =============================================================================

set -euo pipefail

# OS検出
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                echo "linux-$ID"
            else
                echo "linux"
            fi
            ;;
        CYGWIN*|MINGW*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# アーキテクチャ検出
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        i386|i686)
            echo "x86"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# パッケージマネージャー検出
detect_package_manager() {
    if command -v brew &> /dev/null; then
        echo "brew"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# インストールコマンド生成
get_install_command() {
    local package_manager="$1"
    local package="$2"
    
    case "$package_manager" in
        brew)
            echo "brew install $package"
            ;;
        apt)
            echo "sudo apt-get update && sudo apt-get install -y $package"
            ;;
        dnf)
            echo "sudo dnf install -y $package"
            ;;
        yum)
            echo "sudo yum install -y $package"
            ;;
        pacman)
            echo "sudo pacman -S --noconfirm $package"
            ;;
        zypper)
            echo "sudo zypper install -y $package"
            ;;
        *)
            echo "echo 'Unknown package manager. Please install $package manually.'"
            ;;
    esac
}

# システム情報出力
get_system_info() {
    local os_type=$(detect_os)
    local arch=$(detect_arch)
    local pkg_manager=$(detect_package_manager)
    
    cat <<EOF
{
  "os": "$os_type",
  "arch": "$arch",
  "package_manager": "$pkg_manager",
  "kernel": "$(uname -r)",
  "hostname": "$(hostname)"
}
EOF
}

# メイン処理
main() {
    case "${1:-info}" in
        "os")
            detect_os
            ;;
        "arch")
            detect_arch
            ;;
        "pkg")
            detect_package_manager
            ;;
        "install")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 install <package>"
                exit 1
            fi
            local pkg_manager=$(detect_package_manager)
            get_install_command "$pkg_manager" "$2"
            ;;
        "info")
            get_system_info
            ;;
        *)
            echo "Usage: $0 [os|arch|pkg|install <package>|info]"
            exit 1
            ;;
    esac
}

# 環境変数として利用可能にする
export OS_TYPE=$(detect_os)
export ARCH_TYPE=$(detect_arch)
export PKG_MANAGER=$(detect_package_manager)

# スクリプトが直接実行された場合のみmainを実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi