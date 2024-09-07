" ## NERDtree
" ## https://github.com/preservim/nerdtree

" Start NERDTree when Vim is started without file arguments.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
nnoremap <C-n> :NERDTreeToggle<CR>
nnoremap <C-h> :NERDTree<CR>
nnoremap <C-f> :NERDTreeFind<CR>

" 隠しファイルを表示する
let NERDTreeShowHidden = 1

"他のバッファをすべて閉じた時にNERDTreeが開いていたらNERDTreeも一緒に閉じる。
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

