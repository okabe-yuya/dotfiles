" if you don't set this option, this color might not correct
set termguicolors

colorscheme iceberg
" ビジュアルモードの選択時の色の設定
" 背景透過をしていると、選択している箇所の判別がつかないため設定
highlight Visual ctermbg=darkgrey guibg=#5f5f5f

" lightline
let g:lightline = {}
let g:lightline.colorscheme = 'iceberg'

" or this line
let g:lightline = {'colorscheme' : 'iceberg'}

