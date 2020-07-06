set showcmd
set showmode 
set ignorecase
set smartcase
set mouse=a
set nocompatible
set backspace=indent,eol,start
filetype off
syntax on
filetype plugin indent on
set wrap
set modelines=0
set laststatus=2
set number
" set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]\ [BUFFER=%n]\ %{strftime('%c')}
set encoding=utf-8
set hlsearch
nnoremap <silent> <Space> @=(foldlevel('.')?'za':"\<Space>")<CR>
vnoremap <Space> zf

" Theme
" let g:gruvbox_italic=1
" set termguicolors
let g:gruvbox_contrast_dark="soft"
let g:airline_theme='gruvbox'
autocmd vimenter * colorscheme gruvbox

" Tabs
set tabstop=4
set softtabstop=0 noexpandtab
set shiftwidth=4
set smarttab

" Load .vimrc.plug
if filereadable(expand("~/.vimrc.plug"))
	source ~/.vimrc.plug
endif

" Autocompletion
filetype plugin on
set omnifunc=syntaxcomplete#Complete

function! OpenCompletion()
    if !pumvisible() && ((v:char >= 'a' && v:char <= 'z') || (v:char >= 'A' && v:char <= 'Z'))
        call feedkeys("\<C-x>\<C-o>", "n")
    endif
endfunction
autocmd InsertCharPre * call OpenCompletion()
set completeopt+=menuone,noselect,noinsert

" NERDTree config
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
map <C-n> :NERDTreeToggle<CR>
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" TagBar
nmap <C-\> :TagbarToggle<CR>

" PDF
:command! -complete=file -nargs=1 Rpdf :r !pdftotext -nopgbrk <q-args> -
:command! -complete=file -nargs=1 Rpdf :r !pdftotext -nopgbrk <q-args> - |fmt -csw78
