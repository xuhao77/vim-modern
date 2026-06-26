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
command -v vim >/dev/null 2>&1 || { err "未找到 vim，请先安装 vim (脚本会在后面尝试升级到 9.2.0338+)"; exit 1; }
VIM_VER="$(vim --version | head -1)"
info "检测到: $VIM_VER"

# ---------------------------------------------------------------------------
# 1. 安装依赖工具 (git / curl / node / clangd / ripgrep / fzf / pyright)
# ---------------------------------------------------------------------------
install_mac_deps() {
  if ! command -v brew >/dev/null 2>&1; then
    err "未找到 Homebrew。请先安装: https://brew.sh"; exit 1
  fi
  # 注意: node 不在这里装，统一交给 nvm (见 ensure_node_via_nvm)
  local pkgs=()
  command -v git  >/dev/null 2>&1 || pkgs+=(git)
  command -v curl >/dev/null 2>&1 || pkgs+=(curl)
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

# 决定如何获取 root 权限:
#   - 已经是 root (id=0)      -> 不需要任何前缀，直接装
#   - 普通用户且有 sudo       -> 用 sudo
#   - 普通用户且无 sudo       -> 无法装系统包，返回失败让上层走降级方案
SUDO=""
detect_privilege() {
  if [ "$(id -u)" -eq 0 ]; then
    SUDO=""                       # 你就是 root，无需 sudo
    info "当前是 root 用户，直接安装系统包"
  elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
    info "当前是普通用户，使用 sudo 安装系统包"
  else
    return 1                      # 既不是 root 又没 sudo
  fi
}

install_linux_deps() {
  if ! detect_privilege; then
    warn "当前既非 root 又无 sudo，无法用系统包管理器安装依赖。"
    warn "将尝试用户级降级方案 (见函数 install_user_level_deps)。"
    install_user_level_deps
    return
  fi

  # 注意: node 不在这里装，统一交给 nvm (见 ensure_node_via_nvm)，
  # 因为发行版自带的 nodejs 往往太旧 (< 20)，会导致 coc 报 "crypto is not defined"。
  if command -v apt-get >/dev/null 2>&1; then
    info "通过 apt 安装依赖..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y git curl build-essential clangd ripgrep fzf
  elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y git curl clang-tools-extra ripgrep fzf
  elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y git curl clang-tools-extra ripgrep fzf
  elif command -v pacman >/dev/null 2>&1; then
    $SUDO pacman -Sy --noconfirm git curl clang ripgrep fzf
  elif command -v apk >/dev/null 2>&1; then
    # Alpine (常见于 Docker 容器，且容器里通常就是 root)
    $SUDO apk add --no-cache git curl clang-extra-tools ripgrep fzf build-base
  elif command -v zypper >/dev/null 2>&1; then
    $SUDO zypper install -y git curl clang-tools ripgrep fzf
  else
    warn "未识别的包管理器，请手动确保已安装: git curl clangd ripgrep fzf"
  fi
}

# 无 root 无 sudo 时的降级方案: 优先用 conda，其次提示手动
install_user_level_deps() {
  # node 仍由 nvm 负责，这里只补 clangd/ripgrep/fzf
  if command -v conda >/dev/null 2>&1; then
    info "检测到 conda，尝试用 conda 安装到当前环境 (无需 root)..."
    conda install -y -c conda-forge clangd ripgrep fzf || \
      warn "conda 安装部分失败，请检查上面的输出"
  else
    err "无法自动安装系统依赖。请联系管理员安装，或自行用以下任一方式 (都不需要 root):"
    echo "  • conda:  conda install -c conda-forge clangd ripgrep fzf"
    echo "  • 预编译二进制: 把 clangd / rg / fzf 下载到 ~/bin 并加入 PATH"
    echo "  脚本会继续部署 vim 配置，但 LSP/搜索功能在依赖装好前不可用。"
  fi
}

case "$OS" in
  Darwin) install_mac_deps ;;
  Linux)  install_linux_deps ;;
  *) warn "未知系统 $OS，跳过依赖自动安装" ;;
esac

# ---------------------------------------------------------------------------
# 1a. 确保 Vim 版本足够新 (顶栏鼠标点击需要 statusline_click，Vim 9.2.0338+)
#     发行版自带的 vim 往往太旧 (Ubuntu 24.04 锁在 9.1.0016，apt 升不上去)，
#     缺 statusline_click 时 airline 的 buffer 标签点不动。这里在版本不够时
#     从 vim/vim 源码编译一个新版到用户目录 (~/.local)，不覆盖系统 vim。
#
#     关于剪贴板: 本配置的复制走 OSC52 插件 (vim-oscyank)，靠 vimrc 里
#     `if !has('clipboard')` 的分支自动镜像 y 到本地剪贴板。所以这里
#     **故意不编入 +clipboard/+X11** —— 一旦编进去 has('clipboard') 变 1，
#     那段 OSC52 自动镜像就被关掉了，反而不符合预期。
# ---------------------------------------------------------------------------
VIM_MIN_PATCH=338          # 顶栏点击所需的最低 9.2 补丁号
VIM_PREFIX="$HOME/.local"  # 源码编译安装到用户目录，无需写 /usr

# 当前 vim 是否已支持顶栏点击 (statusline_click)。用 vim 自己判断最准，
# 不去解析版本字符串 (补丁号格式各异，容易判错)。
vim_supports_tabclick() {
  vim -es -u NONE -N \
    -c 'if has("statusline_click") || has("tablineat") | cquit 0 | else | cquit 1 | endif' \
    </dev/null >/dev/null 2>&1
}

build_vim_from_source() {
  # 编译依赖。Neovim 不在此列 —— 我们要的是新版 Vim 本身。
  if [ "$OS" = "Darwin" ]; then
    command -v brew >/dev/null 2>&1 && brew install ncurses >/dev/null 2>&1 || true
  else
    # 需要 root/sudo 才能装编译依赖；detect_privilege 已在前面设置好 $SUDO
    if detect_privilege 2>/dev/null; then
      if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get install -y git make gcc libncurses-dev >/dev/null 2>&1 || \
          $SUDO apt-get install -y git make gcc libncurses5-dev >/dev/null 2>&1 || true
      elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y git make gcc ncurses-devel >/dev/null 2>&1 || true
      elif command -v yum >/dev/null 2>&1; then
        $SUDO yum install -y git make gcc ncurses-devel >/dev/null 2>&1 || true
      elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -Sy --noconfirm git make gcc ncurses >/dev/null 2>&1 || true
      elif command -v apk >/dev/null 2>&1; then
        $SUDO apk add --no-cache git make gcc musl-dev ncurses-dev >/dev/null 2>&1 || true
      elif command -v zypper >/dev/null 2>&1; then
        $SUDO zypper install -y git make gcc ncurses-devel >/dev/null 2>&1 || true
      fi
    else
      warn "无 root/sudo，跳过编译依赖安装；若缺 ncurses-dev 编译会失败。"
    fi
  fi

  local src="$HOME/.cache/vim-build"
  info "获取 vim 源码到 $src (浅克隆)..."
  rm -rf "$src"
  if ! git clone --depth 1 https://github.com/vim/vim.git "$src" >/dev/null 2>&1; then
    err "克隆 vim 源码失败 (网络问题?)，跳过升级，继续用现有 vim。"
    return 1
  fi

  info "编译 Vim 到 $VIM_PREFIX (几分钟，请耐心)..."
  # 不带 GUI / X11 / clipboard：保持 has('clipboard')==0 以走 OSC52 插件方案。
  # 编入 python3 是为了将来需要 (coc 不依赖它，但有备无患)。
  # 用 `|| rc=$?` 捕获返回码：否则子shell 失败会在 set -e 下直接终止整个脚本。
  local rc=0
  ( cd "$src" && \
    ./configure --prefix="$VIM_PREFIX" \
      --with-features=huge \
      --enable-multibyte \
      --enable-python3interp=dynamic \
      --disable-gui \
      --without-x \
      >/dev/null 2>&1 && \
    make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)" >/dev/null 2>&1 && \
    make install >/dev/null 2>&1 ) || rc=$?

  if [ $rc -ne 0 ] || [ ! -x "$VIM_PREFIX/bin/vim" ]; then
    err "Vim 编译失败。请检查是否缺少编译依赖 (gcc/make/ncurses-dev)。"
    err "源码在 $src，可手动进入排查。继续用现有 vim。"
    return 1
  fi

  # 确保新 vim 在 PATH 里。把 ~/.local/bin 写进 shell 启动文件 (若还没有)。
  export PATH="$VIM_PREFIX/bin:$PATH"
  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc_file" ] || continue
    if ! grep -q '/.local/bin' "$rc_file" 2>/dev/null; then
      printf '\n# 新版 Vim (源码编译) 优先\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc_file"
    fi
  done
  ok "Vim 已升级: $("$VIM_PREFIX/bin/vim" --version | head -1)"
  warn "新 vim 装在 $VIM_PREFIX/bin —— 若 'which vim' 仍指向旧版，请重开终端或 source 你的 shell 配置。"
}

ensure_modern_vim() {
  if vim_supports_tabclick; then
    ok "当前 Vim 已支持顶栏鼠标点击 (statusline_click)，无需升级"
    return
  fi
  warn "当前 Vim 不支持顶栏鼠标点击 (需 Vim 9.2.0${VIM_MIN_PATCH}+)，将从源码编译升级。"
  build_vim_from_source || warn "Vim 升级未完成，顶栏点击暂不可用；其余功能不受影响。"
}

ensure_modern_vim

# ---------------------------------------------------------------------------
# 1b. Node.js —— 始终用 nvm 安装/管理 (用户级，无需 root)
#     coc.nvim 需要 Node 20+，否则会报 "crypto is not defined"。
#     发行版自带的 nodejs 经常太旧，所以统一交给 nvm 来保证版本。
# ---------------------------------------------------------------------------
NODE_MIN_MAJOR=20          # coc.nvim 要求的最低主版本
NODE_TARGET=20             # nvm 要安装的目标版本
NVM_VERSION="v0.40.1"

node_major() { node -v 2>/dev/null | sed 's/^v//; s/\..*//'; }

load_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  # nvm.sh 不存在是正常情况(还没装)，不能让函数返回非 0，
  # 否则在 set -e 下会导致脚本静默退出。
  return 0
}

ensure_node_via_nvm() {
  # 已有满足要求的 node 就跳过 (例如 macOS 上 brew 的新版 node、或已装过 nvm)
  if command -v node >/dev/null 2>&1 && [ "$(node_major)" -ge "$NODE_MIN_MAJOR" ] 2>/dev/null; then
    ok "Node 版本满足要求: $(node -v)"
    return
  fi

  if command -v node >/dev/null 2>&1; then
    warn "当前 Node 版本过旧 ($(node -v))，coc.nvim 需要 >= v${NODE_MIN_MAJOR}。改用 nvm 安装新版。"
  else
    info "未检测到 Node，使用 nvm 安装 (无需 root)..."
  fi

  # 安装 nvm (若尚未安装)
  load_nvm
  if ! command -v nvm >/dev/null 2>&1; then
    info "安装 nvm ${NVM_VERSION} ..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    load_nvm
  fi

  if ! command -v nvm >/dev/null 2>&1; then
    err "nvm 安装失败 (可能是网络问题)。请手动安装 Node 20+ 后重新运行本脚本。"
    return 1
  fi

  info "通过 nvm 安装 Node ${NODE_TARGET} ..."
  nvm install "$NODE_TARGET"
  nvm alias default "$NODE_TARGET"
  nvm use default
  ok "Node 就绪: $(node -v)  (npm $(npm -v))"
}

ensure_node_via_nvm

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
