#!/usr/bin/env bash
# =============================================================================
#  现代化 Vim 配置 —— 卸载脚本
#  用法: bash uninstall.sh
#  作用: 移除本配置部署的文件，并尽量恢复你安装前的 ~/.vimrc 备份。
#  说明: 不会卸载 node/clangd/ripgrep 等系统工具，也不会动 nvm
#        (那些可能被其他程序使用)。如需删除见文末提示。
# =============================================================================
set -uo pipefail

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
info()  { echo -e "${BLUE}==>${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}!${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*" >&2; }

echo "======================================================="
echo "        现代化 Vim 配置 —— 卸载"
echo "======================================================="
echo

# ---- 确认 ----
read -r -p "确定要卸载本 vim 配置吗? [y/N] " ans
case "$ans" in
  y|Y|yes|YES) ;;
  *) info "已取消，未做任何改动。"; exit 0 ;;
esac

# ---------------------------------------------------------------------------
# 1. 删除本配置部署的文件 / 目录
# ---------------------------------------------------------------------------
info "删除配置文件与插件..."
rm -f  "$HOME/.vimrc"                       && ok "删除 ~/.vimrc"
rm -f  "$HOME/.vim/coc-settings.json"       && ok "删除 ~/.vim/coc-settings.json"
rm -rf "$HOME/.vim/plugged"                 && ok "删除 ~/.vim/plugged (所有插件)"
rm -f  "$HOME/.vim/autoload/plug.vim"       && ok "删除 vim-plug"
rm -rf "$HOME/.vim/undodir"                 && ok "删除撤销历史"

# coc.nvim 的扩展与缓存数据
if [ -d "$HOME/.config/coc" ]; then
  rm -rf "$HOME/.config/coc" && ok "删除 ~/.config/coc (coc 扩展数据)"
fi

# ---------------------------------------------------------------------------
# 2. 恢复安装前的 .vimrc 备份 (install.sh 会生成 .backup-时间戳)
# ---------------------------------------------------------------------------
echo
latest_backup="$(ls -1t "$HOME"/.vimrc.backup-* 2>/dev/null | head -1)"
if [ -n "${latest_backup:-}" ]; then
  info "发现旧 .vimrc 备份: $latest_backup"
  read -r -p "是否恢复它为 ~/.vimrc? [y/N] " r
  case "$r" in
    y|Y|yes|YES) mv "$latest_backup" "$HOME/.vimrc" && ok "已恢复 ~/.vimrc" ;;
    *) info "保留备份文件不动，未恢复。" ;;
  esac
else
  info "未发现安装前的 .vimrc 备份 (说明安装时你本来就没有 .vimrc)。"
fi

# ---------------------------------------------------------------------------
# 3. 清理收尾
# ---------------------------------------------------------------------------
# 如果 ~/.vim 已经空了，顺手删掉
if [ -d "$HOME/.vim" ] && [ -z "$(ls -A "$HOME/.vim" 2>/dev/null)" ]; then
  rmdir "$HOME/.vim" && ok "删除空的 ~/.vim 目录"
fi

echo
echo "======================================================="
ok "卸载完成。"
echo "======================================================="
echo
info "以下内容【未】自动删除 (可能被其他程序使用)，如确需删除请手动执行:"
echo "  • nvm 与 Node:      rm -rf ~/.nvm   (并从 ~/.bashrc/~/.zshrc 删掉 nvm 相关几行)"
echo "  • 全局 pyright:     npm uninstall -g pyright"
echo "  • 系统工具:         clangd / ripgrep / fzf —— 用你的包管理器自行卸载"
echo "  • 仍保留的备份:     ls ~/.vimrc.backup-*"
