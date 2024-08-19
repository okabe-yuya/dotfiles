" ddc settings
" Ddc は「dark deno-powered completion」の略です。これは、neovim/Vim 用の拡張可能で非同期の補完フレームワークを提供します。
" https://github.com/Shougo/ddc.vim

" ui で何を使用するか指定
call ddc#custom#patch_global('ui', 'native')

" <TAB>: completion.
inoremap <expr> <TAB>
    \ pumvisible() ? '<C-n>' :
    \ (col('.') <= 1 <Bar><Bar> getline('.')[col('.') - 2] =~# '\s') ?
    \ '<TAB>' : ddc#map#manual_complete()

" <S-TAB>: completion back.
inoremap <expr> <S-TAB>  pumvisible() ? '<C-p>' : '<C-h>'

" 使いたいsourceを指定する
call ddc#custom#patch_global('sources', ['around'])

" sourceOptionsのmatchersにfilter指定することで、候補の一覧を制御できる
call ddc#custom#patch_global('sourceOptions', {
    \ '_': {
    \     'matchers': ['matcher_head'],
    \ }})

" ddc.vimの機能を有効にする
call ddc#enable()

