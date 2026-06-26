" =============================================================================
"  现代化 Vim 配置  ——  C++ / CUDA / Python 开发
"  作者注: 本文件会被一键脚本复制到 ~/.vimrc
"  插件管理: vim-plug      LSP: coc.nvim
" =============================================================================

" ----------------------------------------------------------------------------
" 0. 基础设置 (Leader 键 / 编码)
" ----------------------------------------------------------------------------
" Leader 键是很多快捷键的前缀，这里设为空格键（最顺手）
let mapleader = " "
let maplocalleader = " "

set encoding=utf-8
scriptencoding utf-8
set nocompatible              " 关闭 vi 兼容，启用 vim 全部能力

" ----------------------------------------------------------------------------
" 0b. 让 coc.nvim 找到 node (尤其是用 nvm 安装时)
"     nvm 装的 node 只有 source 了 nvm.sh 才会进 PATH。如果 vim 从没读过
"     .bashrc 的环境启动 (GUI / cron / 某些 IDE 终端)，coc 就会报
"     "node is not executable"。这里主动把 nvm 的 node 路径告诉 coc。
" ----------------------------------------------------------------------------
if !executable('node')
  " 取 nvm default 别名指向的版本；没有 default 就取目录里最新的一个
  let s:nvm_node = ''
  let s:nvm_dir  = expand('$HOME/.nvm/versions/node')
  if isdirectory(s:nvm_dir)
    let s:alias = expand('$HOME/.nvm/alias/default')
    if filereadable(s:alias)
      let s:ver = trim(readfile(s:alias)[0])
      " 别名可能写成 "20" 或 "v20.20.2"，做一次模糊匹配
      let s:hit = glob(s:nvm_dir . '/v' . substitute(s:ver, '^v', '', '') . '*/bin/node', 0, 1)
      if !empty(s:hit) | let s:nvm_node = s:hit[0] | endif
    endif
    if empty(s:nvm_node)
      let s:all = sort(glob(s:nvm_dir . '/*/bin/node', 0, 1))
      if !empty(s:all) | let s:nvm_node = s:all[-1] | endif
    endif
  endif
  if !empty(s:nvm_node) && executable(s:nvm_node)
    let g:coc_node_path = s:nvm_node
    " 同时把 node 所在目录加进 $PATH，方便 coc 调用 npm/npx 等
    let $PATH = fnamemodify(s:nvm_node, ':h') . ':' . $PATH
  endif
endif

" ----------------------------------------------------------------------------
" 1. 插件列表 (vim-plug)
"    运行 :PlugInstall 安装，:PlugUpdate 更新
" ----------------------------------------------------------------------------
call plug#begin('~/.vim/plugged')

" ---- LSP / 智能补全（核心）----
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" ---- 文件树 ----
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'         " 文件树里显示 git 状态

" ---- 模糊查找（文件 / 内容 / buffer）----
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" ---- 状态栏 ----
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" ---- Git 集成 ----
Plug 'tpope/vim-fugitive'                  " :Git 命令
Plug 'airblade/vim-gitgutter'              " 左侧显示行级 git 增删改

" ---- 编辑增强 ----
Plug 'tpope/vim-commentary'                " gcc 注释一行，gc 注释选区
Plug 'tpope/vim-surround'                  " 快速增删改包围符号 () [] "" 等
Plug 'jiangmiao/auto-pairs'                " 自动补全括号引号
Plug 'luochen1990/rainbow'                 " 彩虹括号
Plug 'ojroques/vim-oscyank', {'branch': 'main'}  " 跨 SSH/容器 复制到本地剪贴板 (OSC52)

" ---- 语法高亮 ----
Plug 'sheerun/vim-polyglot'                " 一大批语言的语法包（含 Python/C++）
Plug 'bfrg/vim-cuda-syntax'                " CUDA (.cu/.cuh) 语法高亮

" ---- 主题配色 ----
Plug 'morhetz/gruvbox'
Plug 'joshdick/onedark.vim'

" ---- 图标（需要 Nerd Font 字体）----
Plug 'ryanoasis/vim-devicons'

" ---- 缩进参考线 ----
Plug 'Yggdroot/indentLine'

call plug#end()

" ----------------------------------------------------------------------------
" 2. 界面 / 外观
" ----------------------------------------------------------------------------
syntax enable
filetype plugin indent on

set number                   " 显示行号（绝对行号）
set norelativenumber         " 关闭相对行号：每行都显示真实的绝对行号
set cursorline               " 高亮当前行
set termguicolors            " 启用真彩色
set background=dark
set signcolumn=yes           " 始终显示左侧标记列（避免诊断图标导致抖动）
set scrolloff=8              " 光标上下保留 8 行
set showcmd                  " 右下角显示正在输入的命令
set laststatus=2             " 总是显示状态栏
set noshowmode               " 模式信息交给 airline 显示
set signcolumn=yes
" 长行/末屏放不下时，默认会整屏填满 '@'；改成尽量多显示，只在最后一行放 @@@。
" 这解决“上下滚动时后面内容不显示、每行只有 @”的问题。
set display=lastline

" ---- 终端兼容: 关闭所有终端查询，避免命令行冒出 [B1E3] 之类乱码 ----
" vim 启动/恢复时会向终端发查询(版本/颜色/光标位置等)。精简终端
" (如 TERM=xterm 的容器) 不会正确吞掉这些回应，回应字符就被当成键盘
" 输入回显到命令行，看起来是一串乱码。
"
" 为什么“有时才出现”: 回应是异步回来的——来得快(进入读键盘前)就被吞掉，
" 来得慢(容器调度/管道延迟)就泄漏成乱码。同一配置因这几毫秒快慢而时有时无。
" 清空这些 termcode 是从源头掐断: 不发查询 => 没有回应可泄漏，与快慢无关。
set t_RV=                    " 终端版本查询 (启动乱码最常见元凶)
set t_RB=                    " 背景色查询
set t_RF=                    " 前景色查询
set t_u7=                    " 光标位置查询 (ambiwidth 探测)
set t_RC=                    " 真彩色能力查询
set t_RS=                    " 同上一类
set t_8u=                    " 终端 Unicode/键盘协议查询
" 焦点事件: 切走/切回窗口、Ctrl-Z 挂起后 fg 恢复，会让 vim 重发查询并漏码。
" 这正是“清掉启动查询后仍偶发”的元凶。容器里用不到焦点上报，一并关闭。
set t_fe=                    " 焦点事件: 获得焦点
set t_fd=                    " 焦点事件: 失去焦点
" 关掉版本查询后，鼠标“能力自动探测”失效；手动指定 sgr 以保证
" 宽窗口下鼠标点击/滚动定位正确(配合上面的 set mouse=a)。
if !has('gui_running')
  set ttymouse=sgr
endif

" 主题（gruvbox）。想换成 onedark 改成: colorscheme onedark
let g:gruvbox_contrast_dark = 'medium'
silent! colorscheme gruvbox

" 状态栏
let g:airline_powerline_fonts = 1
let g:airline_theme = 'gruvbox'
let g:airline#extensions#tabline#enabled = 1   " 顶部显示 buffer 标签栏

" 彩虹括号
let g:rainbow_active = 1

" 缩进线（在某些文件类型里关闭以免干扰）
let g:indentLine_char = '┊'
let g:indentLine_fileTypeExclude = ['nerdtree', 'help', 'coc-explorer']

" ----------------------------------------------------------------------------
" 3. 编辑行为
" ----------------------------------------------------------------------------
set tabstop=4                " 一个 Tab 显示为 4 空格
set shiftwidth=4             " 自动缩进 4 空格
set expandtab                " Tab 转为空格
set autoindent
set smartindent
set wrap                     " 自动折行显示
set linebreak                " 折行时在单词边界断开

set ignorecase               " 搜索忽略大小写
set smartcase                " 但含大写时区分大小写
set incsearch                " 增量搜索
set hlsearch                 " 高亮搜索结果

set hidden                   " 允许有未保存改动时切换 buffer
set updatetime=300           " 加快 coc 响应
set timeoutlen=500           " 快捷键组合等待时间
set mouse=a                  " 启用鼠标（新手友好）
" 剪贴板: 只有这个 vim 真编译了 +clipboard(同机有 X11/桌面时) 才用 unnamed，
" 否则 set clipboard 是空转。容器/远程纯命令行环境下走下面的 OSC52 方案。
if has('clipboard')
  set clipboard=unnamed
endif
set splitright               " 垂直分屏在右边打开
set splitbelow               " 水平分屏在下方打开
set nobackup                 " coc 需要：关闭备份避免警告
set nowritebackup
set shortmess+=c
set cmdheight=1
set wildmenu                 " 命令行补全菜单
set confirm                  " 退出未保存时弹确认而非报错

" 持久化撤销（关闭文件后仍可撤销）
set undofile
set undodir=~/.vim/undodir

" 针对不同语言的缩进
augroup filetype_indent
  autocmd!
  autocmd FileType python setlocal tabstop=4 shiftwidth=4 expandtab
  autocmd FileType c,cpp,cuda setlocal tabstop=2 shiftwidth=2 expandtab
  autocmd FileType yaml,json setlocal tabstop=2 shiftwidth=2 expandtab
augroup END

" 把 .cu / .cuh 识别为 cuda 文件类型
augroup cuda_ft
  autocmd!
  autocmd BufRead,BufNewFile *.cu,*.cuh set filetype=cuda
augroup END

" =============================================================================
" 4. 快捷键映射
"    说明: <leader> 是空格键; <C-x> 是 Ctrl+x
" =============================================================================

" ---- 基础 ----
" 空格+w 保存，空格+q 退出
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
" 空格+回车 清除搜索高亮
nnoremap <leader><CR> :nohlsearch<CR>

" ---- 复制到「本地」系统剪贴板 (OSC52，跨 SSH/容器有效) ----
" 用法: 可视模式选中后按  <leader>y  ；普通模式 <leader>y + 动作(如 <leader>yy 整行)
"   原理: vim 把内容用 OSC52 转义序列发给你的终端，由终端写进你本地电脑的剪贴板。
"   不需要 +clipboard，也不需要 X11；前提是终端支持 OSC52
"   (iTerm2 / 新版 Windows Terminal / kitty / wezterm / tmux 配好都支持)。
let g:oscyank_silent = 1            " 复制后不弹提示
nnoremap <leader>y <Plug>OSCYankOperator
nnoremap <leader>yy <leader>y_
vnoremap <leader>y <Plug>OSCYankVisual

" 没有真·本地 clipboard 时，让常规的 y 也自动镜像到 OSC52，
" 这样 yy / yiw 等顺手操作也能直接粘到本地电脑。有 +clipboard 则不打扰。
if !has('clipboard')
  augroup osc52_yank
    autocmd!
    autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' |
          \ execute 'OSCYankRegister "' | endif
  augroup END
endif

" ---- 窗口切换（Ctrl + hjkl 在分屏间跳）----
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ---- Buffer 切换 ----
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
" Tab / Shift-Tab 切换 buffer
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>

" ---- 文件树 NERDTree ----
" 空格+e 开关文件树，空格+f 定位当前文件
nnoremap <leader>e :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>
let g:NERDTreeShowHidden = 1
let g:NERDTreeWinSize = 32
let g:NERDTreeMinimalUI = 1
" 当只剩文件树时自动关闭 vim
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" ---- 模糊查找 fzf ----
" 空格+空格 找文件; 空格+/ 全局搜内容(需 ripgrep); 空格+b 找 buffer; 空格+; 找命令历史
nnoremap <leader><Space> :Files<CR>
nnoremap <leader>/ :Rg<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>fl :Lines<CR>
nnoremap <leader>fh :History<CR>

" ---- 移动一行 / 多行（Alt+j / Alt+k）----
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" 可视模式下缩进后保持选区
vnoremap < <gv
vnoremap > >gv

" =============================================================================
" 5. coc.nvim (LSP) 设置 —— 类 VSCode 的补全 / 跳转 / 诊断
" =============================================================================
" 需要安装的语言服务（一键脚本会自动装）：
"   coc-clangd   -> C / C++ / CUDA
"   coc-pyright  -> Python
"   coc-json / coc-snippets / coc-highlight
let g:coc_global_extensions = [
  \ 'coc-clangd',
  \ 'coc-pyright',
  \ 'coc-json',
  \ 'coc-snippets',
  \ 'coc-highlight',
  \ 'coc-pairs',
  \ ]

" ---- 补全菜单操作 ----
" Tab / Shift-Tab 在补全菜单中上下选择
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" 回车确认选中的补全项
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Ctrl+Space 手动触发补全
inoremap <silent><expr> <c-@> coc#refresh()

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" ---- 代码跳转（核心功能）----
" gd 跳到定义, gy 类型定义, gi 实现, gr 引用
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" K 显示悬浮文档（函数签名/注释）
nnoremap <silent> K :call ShowDocumentation()<CR>
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" ---- 诊断（错误/警告）跳转 ----
" [g 上一个问题, ]g 下一个问题
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" 空格+d 列出所有诊断
nnoremap <silent><nowait> <leader>d :<C-u>CocList diagnostics<cr>

" ---- 重命名 / 代码操作 / 格式化 ----
" 空格+rn 重命名符号
nmap <leader>rn <Plug>(coc-rename)
" 空格+ca 代码操作（quick fix）
nmap <leader>ca <Plug>(coc-codeaction-cursor)
" 空格+F 格式化整个文件
nmap <leader>F :call CocAction('format')<CR>
" 选区格式化
xmap <leader>F  <Plug>(coc-format-selected)

" 高亮光标下的同名符号
autocmd CursorHold * silent call CocActionAsync('highlight')

" coc 列表常用
nnoremap <silent><nowait> <leader>o :<C-u>CocList outline<cr>   " 文件大纲
nnoremap <silent><nowait> <leader>s :<C-u>CocList -I symbols<cr>" 全局符号搜索

" =============================================================================
" 6. C++ / CUDA 编译运行快捷键 (可选, 单文件快速测试用)
" =============================================================================
" 空格+rc 编译并运行当前 C++ 文件
autocmd FileType cpp nnoremap <buffer> <leader>rc :w<CR>:!g++ -std=c++17 -O2 % -o /tmp/%:t:r && /tmp/%:t:r<CR>
" 空格+rc 运行当前 Python 文件
autocmd FileType python nnoremap <buffer> <leader>rc :w<CR>:!python3 %<CR>
" 空格+rc 用 nvcc 编译并运行 CUDA 文件
autocmd FileType cuda nnoremap <buffer> <leader>rc :w<CR>:!nvcc % -o /tmp/%:t:r && /tmp/%:t:r<CR>

" =============================================================================
" 7. 小贴士
"   - 第一次启动会自动安装插件，请耐心等待并重启 vim
"   - 输入 :checkhealth 之外，可用 :CocInfo 看 LSP 状态
"   - C/C++ 项目建议在根目录放 compile_commands.json 让 clangd 找到头文件
" =============================================================================
