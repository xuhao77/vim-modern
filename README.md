# 现代化 Vim 配置 —— C++ / CUDA / Python 开发指南

这是一套面向 **C++ / CUDA / Python** 的现代化 Vim 配置。它在 Vim 里提供接近
VSCode 的体验：智能补全、定义跳转、错误提示、文件树、模糊搜索、Git 集成等。

> 本文档面向 **Vim 新手**，每个常用操作都有说明。建议先看完第 1～4 节就能上手。

---

## 目录
1. [一键安装](#1-一键安装)
2. [安装后第一件事：装字体](#2-安装后第一件事装字体)
3. [Vim 极速入门（新手必读）](#3-vim-极速入门新手必读)
4. [本配置的核心快捷键](#4-本配置的核心快捷键)
5. [按语言看：C++ / CUDA / Python 怎么用](#5-按语言看)
6. [让代码跳转/补全更准：compile_commands.json](#6-让-clangd-找到头文件)
7. [常见问题排查](#7-常见问题排查)
8. [卸载 / 恢复](#8-卸载--恢复)
9. [配置里都装了什么](#9-配置清单)

---

## 1. 一键安装

在终端里执行：

```bash
cd ~/vim-modern
bash install.sh
```

脚本会自动完成：
- 检查并安装依赖（git / curl / node / clangd / ripgrep / fzf / pyright）
- 备份你已有的 `~/.vimrc`（如果有的话，不会丢）
- 安装插件管理器 vim-plug
- 复制配置文件到 `~/.vimrc` 和 `~/.vim/coc-settings.json`
- 自动安装所有插件
- 自动安装 LSP 语言服务（clangd / pyright）

整个过程大约 2～5 分钟（取决于网速）。完成后直接运行 `vim` 即可。

> **如果某些下载因为网络失败**：重新运行 `bash install.sh` 即可，脚本是可重复执行的。

---

## 2. 安装后第一件事：装字体

状态栏的箭头和文件树的图标需要 **Nerd Font** 字体才能正常显示，否则会看到乱码方块。

macOS：
```bash
brew install --cask font-jetbrains-mono-nerd-font
```

然后在终端里启用：
- **系统自带「终端」**：偏好设置 → 描述文件 → 文本 → 字体 → 选 `JetBrainsMono Nerd Font`
- **iTerm2**：Settings → Profiles → Text → Font → 选 `JetBrainsMono Nerd Font`
- **VS Code 内置终端**：设置里搜 `terminal.integrated.fontFamily`，填 `JetBrainsMono Nerd Font`

> 不装字体也能用，只是图标显示成方块，不影响功能。

---

## 3. Vim 极速入门（新手必读）

Vim 有几种「模式」，这是它和普通编辑器最大的区别：

| 模式 | 作用 | 如何进入 |
|------|------|----------|
| **普通模式 (Normal)** | 移动光标、执行命令（默认模式） | 按 `Esc` 回到这里 |
| **插入模式 (Insert)** | 打字输入文本 | 按 `i` |
| **可视模式 (Visual)** | 选中文本 | 按 `v` |
| **命令模式 (Command)** | 输入 `:` 开头的命令 | 按 `:` |

### 最少必须记住的操作

```
i           进入插入模式开始打字
Esc         回到普通模式（迷路了就按它）
:w  回车    保存
:q  回车    退出
:wq 回车    保存并退出
:q! 回车    不保存强制退出
```

### 移动光标（普通模式下）
```
h j k l     左 下 上 右（也可以用方向键）
w / b       下一个/上一个单词
0 / $       行首 / 行尾
gg / G      文件开头 / 文件结尾
5j          向下移动 5 行（数字+方向）
Ctrl+d/u    向下/上翻半屏
```

### 编辑（普通模式下）
```
dd          删除一整行（也是剪切）
yy          复制一整行
p           粘贴
u           撤销
Ctrl+r      重做
x           删除光标处字符
o           在下方新建一行并进入插入模式
```

> **本配置已开启鼠标和系统剪贴板**：你可以直接用鼠标点击、拖动选择，
> 复制粘贴也和系统通用（`y` 复制的内容能粘到别的软件）。新手过渡期很友好。

---

## 4. 本配置的核心快捷键

> **Leader 键 = 空格键**。下面写的「空格」就是按一下空格键当前缀。
> 写法约定：`空格 e` 表示先按空格再按 e；`Ctrl+e` 表示同时按。

### 文件 / 窗口
| 快捷键 | 功能 |
|--------|------|
| `空格 e` | 打开/关闭左侧**文件树** |
| `空格 nf` | 在文件树中定位当前文件 |
| `空格 空格` | **模糊查找文件**（输入文件名片段即可） |
| `空格 /` | **全局搜索内容**（在所有文件里搜关键字） |
| `空格 b` | 在打开的 buffer 间查找切换 |
| `空格 w` | 保存 |
| `空格 q` | 退出 |
| `Tab` / `Shift+Tab` | 切换到下一个/上一个文件 |
| `Ctrl+h/j/k/l` | 在分屏窗口间跳转 |

### 代码智能（LSP，最常用）
| 快捷键 | 功能 |
|--------|------|
| `gd` | **跳转到定义** |
| `gr` | 查找所有**引用** |
| `gy` | 跳转到类型定义 |
| `gi` | 跳转到实现 |
| `K` （大写） | 显示**悬浮文档**（函数签名/注释） |
| `空格 rn` | **重命名**符号（所有引用一起改） |
| `空格 ca` | **代码操作 / 快速修复**（如自动补头文件、修错） |
| `空格 F` | **格式化**整个文件 |
| `]g` / `[g` | 跳到下一个/上一个**错误或警告** |
| `空格 d` | 列出当前文件所有诊断（错误列表） |
| `空格 o` | 文件**大纲**（函数/类列表） |
| `空格 s` | 全局**符号搜索** |

### 补全菜单（插入模式打字时）
| 快捷键 | 功能 |
|--------|------|
| `Tab` / `Shift+Tab` | 在补全候选里上下选择 |
| `回车` | 确认选中的补全 |
| `Ctrl+空格` | 手动触发补全 |

### 编辑增强
| 快捷键 | 功能 |
|--------|------|
| `gcc` | 注释/取消注释当前行 |
| `gc`（可视模式） | 注释选中的多行 |
| `Alt+j` / `Alt+k` | 把当前行上下移动 |
| `cs"'` | 把包围的 `"` 换成 `'`（vim-surround） |
| `空格 回车` | 清除搜索高亮 |

### 一键编译运行（单文件快速测试）
| 快捷键 | 功能 |
|--------|------|
| `空格 rc` | 在 C++ 文件里：用 g++ 编译并运行 |
| `空格 rc` | 在 Python 文件里：用 python3 运行 |
| `空格 rc` | 在 CUDA(.cu) 文件里：用 nvcc 编译并运行 |

---

## 5. 按语言看

### C++
- 打开任意 `.cpp/.h/.hpp` 文件，clangd 会自动启动。
- 补全、`gd` 跳转、`gr` 找引用、`K` 看文档全部可用。
- 报红的地方按 `空格 ca` 常常能一键修复（补头文件、加 `;` 等）。
- **大型项目务必看第 6 节**生成 `compile_commands.json`，否则 clangd 找不到
  你的头文件，会满屏报红。

### CUDA
- `.cu / .cuh` 文件会自动识别为 cuda 类型并高亮（vim-cuda-syntax 提供）。
- clangd 也支持 CUDA：`coc-settings.json` 里已配置 `--cuda-gpu-arch=sm_75`。
  如果你的显卡架构不同（如 sm_80 / sm_90），改这个数字即可。
- `空格 rc` 会调用 `nvcc` 编译运行（需要已安装 CUDA Toolkit）。

### Python
- 打开 `.py` 文件，pyright 自动启动，提供补全、类型检查、跳转。
- 建议在项目里使用虚拟环境；pyright 会读取你的 `python` 解释器。
- `空格 rc` 直接用 `python3` 运行当前文件。
- 想格式化代码可装 black：`pip install black`，然后 `空格 F` 即可格式化
  （或在 coc-settings.json 里把 `formatOnSave` 改成 true 实现保存即格式化）。

---

## 6. 让 clangd 找到头文件

clangd（C++/CUDA 的智能引擎）需要知道你的**编译参数和头文件路径**。
方法是在项目根目录提供一个 `compile_commands.json`。

### 如果你用 CMake（最常见）
在 CMake 配置时加一个参数：
```bash
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
# 然后把生成的文件链接到项目根目录
ln -s build/compile_commands.json .
```

### 如果你用 Makefile
安装 `bear` 工具来「录制」编译命令：
```bash
brew install bear        # macOS
bear -- make             # 用 bear 包裹你的 make 命令
```
就会生成 `compile_commands.json`。

### 临时方案（单文件 / 小项目）
`coc-settings.json` 里已设置了 `fallbackFlags`（默认 C++17）。
小项目不配 `compile_commands.json` 也能补全，只是跨文件跳转可能不全。

---

## 7. 常见问题排查

**Q: 状态栏 / 文件树是乱码方块？**
A: 没装 Nerd Font 或终端没启用它。见第 2 节。

**Q: 补全 / 跳转不工作？**
A: 在 vim 里执行 `:CocInfo` 看 LSP 状态；执行 `:CocList extensions` 看扩展
是否都是 `*`（已启用）。C++ 还要确认 `clangd --version` 能运行。

**Q: C++ 文件满屏报红，找不到头文件？**
A: 见第 6 节，生成 `compile_commands.json`。

**Q: 插件没装上 / 想重装？**
A: 在 vim 里执行 `:PlugInstall`（装）或 `:PlugUpdate`（更新）。

**Q: coc 扩展没装上？**
A: 在 vim 里执行 `:CocInstall coc-clangd coc-pyright`。

**Q: 想看某个快捷键是怎么定义的？**
A: 直接看 `~/.vimrc`，里面每个映射都有中文注释。

**Q: 提示需要 node？**
A: coc.nvim 依赖 Node.js。确认 `node --version` 可用（脚本会自动装）。

**Q: 机器上只有 root、没有 `sudo` 命令（常见于 Docker 容器）？**
A: 直接跑 `bash install.sh` 即可。脚本会自动检测权限：
- 你就是 **root** → 直接安装，不调用 sudo；
- 普通用户 + 有 sudo → 用 sudo；
- 既非 root 又无 sudo → 自动降级，若有 conda 则用 conda 装依赖。

支持的包管理器：apt / dnf / yum / pacman / apk(Alpine) / zypper。

**Q: 公司服务器既没 root 也没 sudo，怎么装依赖？**
A: 推荐用 **conda**（不需要 root）：
```bash
conda install -c conda-forge clangd nodejs ripgrep fzf
```
装好后再跑 `bash install.sh` 部署配置即可。脚本检测到 conda 也会自动这么做。

---

## 8. 卸载 / 恢复

一键脚本在安装时**自动备份**了你原来的配置，文件名形如
`~/.vimrc.backup-20260625-120000`。

恢复旧配置：
```bash
# 找到备份
ls -la ~/.vimrc.backup-*
# 恢复（把时间戳换成你的）
mv ~/.vimrc.backup-20260625-120000 ~/.vimrc
```

彻底卸载本配置：
```bash
rm -f ~/.vimrc
rm -rf ~/.vim/plugged ~/.vim/autoload/plug.vim ~/.vim/coc-settings.json
# coc 数据（可选）
rm -rf ~/.config/coc
```

---

## 9. 配置清单

### 安装的插件
| 插件 | 作用 |
|------|------|
| coc.nvim | LSP 智能补全引擎（核心） |
| nerdtree + git-plugin | 文件树 + git 状态 |
| fzf + fzf.vim | 模糊查找文件/内容 |
| vim-airline | 漂亮的状态栏 |
| vim-fugitive / gitgutter | Git 命令 / 行级 diff |
| vim-commentary | 快速注释 |
| vim-surround | 操作包围符号 |
| auto-pairs | 自动补全括号引号 |
| rainbow | 彩虹括号 |
| vim-polyglot | 多语言语法高亮 |
| vim-cuda-syntax | CUDA 语法高亮 |
| gruvbox / onedark | 配色主题 |
| vim-devicons | 文件图标 |
| indentLine | 缩进参考线 |

### 安装的 coc 扩展（LSP）
| 扩展 | 语言 |
|------|------|
| coc-clangd | C / C++ / CUDA |
| coc-pyright | Python |
| coc-json | JSON |
| coc-snippets | 代码片段 |
| coc-highlight | 颜色高亮 |
| coc-pairs | 括号配对 |

### 关键文件位置
```
~/.vimrc                      主配置（含全部中文注释）
~/.vim/coc-settings.json      LSP 设置（clangd/pyright 参数）
~/.vim/plugged/               插件安装目录
~/.vim/undodir/               持久化撤销历史
~/.config/coc/                coc 扩展数据
```

---

### 想换主题？
编辑 `~/.vimrc`，找到 `colorscheme gruvbox` 一行，改成 `colorscheme onedark`
（已预装），保存后重启 vim。记得 airline 主题也可同步改 `g:airline_theme`。

祝开发愉快！有任何快捷键忘了，回来翻第 4 节即可。
