" ## NERDtree
" ## https://github.com/preservim/nerdtree

" Start NERDTree when Vim is started without file arguments.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-h> :NERDTree<CR>

