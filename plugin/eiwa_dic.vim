if exists("g:loaded_eiwa_dic")
    finish
endif
let g:loaded_eiwa_dic = 1

augroup eiwa_dic
    autocmd!
    au CursorMoved * lua require("eiwa_dic").close()
augroup END

command! EiwaPopup lua require("eiwa_dic").popup()
