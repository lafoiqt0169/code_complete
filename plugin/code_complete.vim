"==================================================
"           variables:
"
"               g:completekey
"                   the key used to complete function
"                   parameters and key words.
"
"               g:rs, g:re
"                   region start and stop
"               you can change them as you like.
"==================================================

if v:version < 700
    finish
endif

" Variable Definitions: {{{1
" options, define them as you like in vimrc:
if !exists("g:completekey")
    let g:completekey = "<C-j>"   "hotkey
endif


if !exists("g:rs")
    let g:rs = '`<'    "region start
endif

if !exists("g:re")
    let g:re = '>`'    "region stop
endif

" ----------------------------
let s:signature_list = []
let s:jumppos = -1
let s:doappend = 1

" Autocommands: {{{1
autocmd BufReadPost,BufNewFile * call CodeCompleteStart()

" Menus:
menu <silent>       &Tools.Code\ Complete\ Start          :call CodeCompleteStart()<CR>
menu <silent>       &Tools.Code\ Complete\ Stop           :call CodeCompleteStop()<CR>

" Function Definitions: {{{1

function! CodeCompleteStart()
    exec "silent! iunmap  <buffer> ".g:completekey
    exec "inoremap <buffer> ".g:completekey." <c-r>=CodeComplete()<cr><c-r>=SwitchRegion()<cr>"
endfunction

function! CodeCompleteStop()
    exec "silent! iunmap <buffer> ".g:completekey
endfunction

function! FunctionComplete(fun)
    let s:signature_list=[]
    let signature_word=[]
    let ftags=taglist("^".a:fun."$")
    if type(ftags)==type(0) || ((type(ftags)==type([])) && ftags==[])
        return ''
    endif
    let tmp=''
    for i in ftags
        if match(i.cmd,'^/\^.*\(\*'.a:fun.'\)\(.*\)\;\$/')>=0
            if match(i.cmd,'(\s*void\s*)')<0 && match(i.cmd,'(\s*)')<0
                    let tmp=substitute(i.cmd,'^/\^','','')
                    let tmp=substitute(tmp,'.*\(\*'.a:fun.'\)','','')
                    let tmp=substitute(tmp,'^[\){1}]','','')
                    let tmp=substitute(tmp,';\$\/;{1}','','')
                    let tmp=substitute(tmp,'\$\/','','')
                    let tmp=substitute(tmp,';','','')
                    let tmp=substitute(tmp,',\(\S\)',', \1','g')            "string tmp expects ', ' not ',SOMETHING'
                    let tmp=substitute(tmp,', ',g:re.', '.g:rs,'g')
                    let tmp=substitute(tmp,'(\(.*\))',g:rs.'\1'.g:re,'g')
            else
                    let tmp=''
            endif
            if (tmp != '') && (index(signature_word,tmp) == -1)
                let signature_word+=[tmp]
                let item={}
                " Fix the completion which starts with SPACE
                let item['word']=substitute(tmp, '^\(\s*\)', '', '')
                let item['menu']=i.filename
                let s:signature_list+=[item]
            endif
        endif
        if has_key(i,'kind') && has_key(i,'name') && has_key(i,'signature')
            if (i.kind=='p' || i.kind=='f') && i.name==a:fun  " p is declare, f is definition
                if match(i.signature,'(\s*void\s*)')<0 && match(i.signature,'(\s*)')<0
                    "string tmp expects ', ' not ',SOMETHING', generates ', SOMETHING'
                    let tmp=substitute(i.signature,',\(\S\)',', \1','g')
                    let tmp=substitute(tmp,', ',g:re.', '.g:rs,'g')
                    let tmp=substitute(tmp,'(\(.*\))',g:rs.'\1'.g:re,'g')
                else
                    let tmp=''
                endif
                if (tmp != '') && (index(signature_word,tmp) == -1)
                    let signature_word+=[tmp]
                    let item={}
                    " Fix the completion which starts with SPACE
                    let item['word']=substitute(tmp, '^\(\s*\)', '', '')
                    let item['menu']=i.filename
                    let s:signature_list+=[item]
                endif
            endif
        endif
    endfor
    if s:signature_list==[]
        return "\<RIGHT>"
    endif
    if len(s:signature_list)==1
        return s:signature_list[0]['word']
    else
        call  complete(col('.'),s:signature_list)
        return ''
    endif
endfunction


function! SwitchRegion()
    if len(s:signature_list)>1
        let s:signature_list=[]
        return ''
    endif
    if s:jumppos != -1
        call cursor(s:jumppos,0)
        let s:jumppos = -1
    endif
    if match(getline('.'),g:rs.'.*'.g:re)!=-1 || search(g:rs.'.\{-}'.g:re)!=0
        normal 0
        call search(g:rs,'c',line('.'))
        normal v
        call search(g:re,'e',line('.'))
        if &selection == "exclusive"
            exec "norm l"
        endif
        return "\<c-\>\<c-n>gvo\<c-g>"
    else
        if s:doappend == 1
            if g:completekey == "<C-j>"
                return ''
            endif
        endif
        return ''
    endif
endfunction

function! CodeComplete()
    let s:doappend = 1
    let function_name = matchstr(getline('.')[:(col('.')-2)],'\zs\w*\ze\s*(\s*$')
    if function_name != ''
        let funcres = FunctionComplete(function_name)
        if funcres != ''
            let s:doappend = 0
        endif
        return funcres
    else
        return ''
    endif
endfunction

" vim: set fdm=marker et :
