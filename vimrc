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

set number                   " 显示行号
set relativenumber           " 相对行号（配合 5j / 3k 跳转很方便）
set cursorline               " 高亮当前行
set termguicolors            " 启用真彩色
set background=dark
set signcolumn=yes           " 始终显示左侧标记列（避免诊断图标导致抖动）
set scrolloff=8              " 光标上下保留 8 行
set showcmd                  " 右下角显示正在输入的命令
set laststatus=2             " 总是显示状态栏
set noshowmode               " 模式信息交给 airline 显示
set signcolumn=yes

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
set clipboard=unnamed        " 与系统剪贴板共享
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
