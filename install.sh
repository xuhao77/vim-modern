#!/usr/bin/env bash
# =============================================================================
#  现代化 Vim 一键部署脚本  (macOS / Linux)
#  用途: C++ / CUDA / Python 开发
#  用法: bash install.sh
# =============================================================================
set -euo pipefail

# ---- 颜色输出 ----
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
info()  { echo -e "${BLUE}==>${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}!${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "======================================================="
echo "      现代化 Vim 部署  ——  C++ / CUDA / Python"
echo "======================================================="

# ---------------------------------------------------------------------------
# 0. 基本检查
# ---------------------------------------------------------------------------
command -v vim >/dev/null 2>&1 || { err "未找到 vim，请先安装 vim 8.2+ / 9.x"; exit 1; }
VIM_VER="$(vim --version | head -1)"
info "检测到: $VIM_VER"

# ---------------------------------------------------------------------------
# 1. 安装依赖工具 (git / curl / node / clangd / ripgrep / fzf / pyright)
# ---------------------------------------------------------------------------
install_mac_deps() {
  if ! command -v brew >/dev/null 2>&1; then
    err "未找到 Homebrew。请先安装: https://brew.sh"; exit 1
  fi
  local pkgs=()
  command -v git  >/dev/null 2>&1 || pkgs+=(git)
  command -v curl >/dev/null 2>&1 || pkgs+=(curl)
  command -v node >/dev/null 2>&1 || pkgs+=(node)
  command -v rg   >/dev/null 2>&1 || pkgs+=(ripgrep)
  command -v fzf  >/dev/null 2>&1 || pkgs+=(fzf)
  # clangd: macOS 自带 /usr/bin/clangd (Apple)，若无则装 llvm
  command -v clangd >/dev/null 2>&1 || pkgs+=(llvm)
  if [ ${#pkgs[@]} -gt 0 ]; then
    info "通过 brew 安装: ${pkgs[*]}"
    brew install "${pkgs[@]}"
  else
    ok "依赖工具已齐全"
  fi
}

install_linux_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    info "通过 apt 安装依赖 (需要 sudo)"
    sudo apt-get update -qq
    sudo apt-get install -y git curl build-essential clangd ripgrep fzf
    # node: 用 nodesource 或系统包
    command -v node >/dev/null 2>&1 || sudo apt-get install -y nodejs npm
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y git curl clang-tools-extra ripgrep fzf nodejs npm
  else
    warn "未识别的 Linux 发行版，请手动确保已安装: git curl node clangd ripgrep fzf"
  fi
}

case "$OS" in
  Darwin) install_mac_deps ;;
  Linux)  install_linux_deps ;;
  *) warn "未知系统 $OS，跳过依赖自动安装" ;;
esac

# pyright (Python LSP) 通过 npm 全局安装；coc-pyright 也会自带，这里可选
if command -v npm >/dev/null 2>&1; then
  command -v pyright >/dev/null 2>&1 || { info "安装 pyright (Python LSP)"; npm install -g pyright >/dev/null 2>&1 || warn "pyright 安装失败，coc-pyright 仍可独立工作"; }
fi

ok "依赖检查完成"

# ---------------------------------------------------------------------------
# 2. 备份旧配置
# ---------------------------------------------------------------------------
STAMP="$(date +%Y%m%d-%H%M%S)"
backup() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    mv "$target" "${target}.backup-${STAMP}"
    warn "已备份 $target -> ${target}.backup-${STAMP}"
  fi
}
info "备份已存在的配置..."
backup "$HOME/.vimrc"
mkdir -p "$HOME/.vim"
backup "$HOME/.vim/coc-settings.json"

# ---------------------------------------------------------------------------
# 3. 安装 vim-plug (插件管理器)
# ---------------------------------------------------------------------------
PLUG_PATH="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$PLUG_PATH" ]; then
  info "安装 vim-plug..."
  curl -fLo "$PLUG_PATH" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  ok "vim-plug 已安装"
else
  ok "vim-plug 已存在"
fi

# ---------------------------------------------------------------------------
# 4. 复制配置文件
# ---------------------------------------------------------------------------
info "部署配置文件..."
cp "$SCRIPT_DIR/vimrc"             "$HOME/.vimrc"
cp "$SCRIPT_DIR/coc-settings.json" "$HOME/.vim/coc-settings.json"
mkdir -p "$HOME/.vim/undodir"
ok "已写入 ~/.vimrc 和 ~/.vim/coc-settings.json"

# ---------------------------------------------------------------------------
# 5. 安装插件 (非交互式)
# ---------------------------------------------------------------------------
info "安装 vim 插件 (首次较慢，请耐心等待)..."
vim -Es -u "$HOME/.vimrc" +PlugInstall +qall || true
ok "插件安装完成"

# ---------------------------------------------------------------------------
# 6. 安装 coc 语言服务扩展
# ---------------------------------------------------------------------------
info "安装 coc 扩展 (clangd / pyright 等)..."
vim -Es -u "$HOME/.vimrc" +"CocInstall -sync coc-clangd coc-pyright coc-json coc-snippets coc-highlight coc-pairs" +qall || true
ok "coc 扩展安装完成"

# ---------------------------------------------------------------------------
# 7. 字体提示
# ---------------------------------------------------------------------------
echo
echo "======================================================="
ok   "部署完成! 🎉"
echo "======================================================="
echo
warn "为了正确显示图标和状态栏箭头，请安装一个 Nerd Font 字体并在终端中启用："
if [ "$OS" = "Darwin" ]; then
  echo "    brew install --cask font-jetbrains-mono-nerd-font"
else
  echo "    https://www.nerdfonts.com/font-downloads  (推荐 JetBrainsMono Nerd Font)"
fi
echo "    然后在 终端/iTerm2 偏好设置 里把字体改成 'JetBrainsMono Nerd Font'"
echo
info "现在运行 'vim' 开始使用。详细用法见 README.md"
info "C/C++ 项目记得在根目录生成 compile_commands.json (见 README 第 6 节)"
