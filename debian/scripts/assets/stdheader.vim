" **************************************************************************** "
"                                                                              "
"    stdheader.vim - Header 42 personnalise ANKAMA                             "
"    By: YohanGH <YohanGH@proton.me>                                           "
"    Bannière ANKAMA centrée ajoutée sur les 2 premières lignes du header.     "
"                                                                              "
" **************************************************************************** "

let s:asciiart = [
			\"        .--.    No       ",
			\"       |o_o |    Pain    ",
			\"       |:_/ |     No     ",
			\"      //    ''     Code  ",
			\"     (|     | )          ",
			\"     '__   _/_           ",
			\"    (___)=(___)          "
			\]

" Bannière ANKAMA : 2 lignes centrées (MAJUSCULE / ASCII) juste après le bord.
let s:banner = [
			\"A N K A M A",
			\"A N K A M A"
			\]

let s:start		= '/*'
let s:end		= '*/'
let s:fill		= '*'
let s:length	= 80
let s:margin	= 5

let s:types		= {
			\'\.c$\|\.h$\|\.cc$\|\.hh$\|\.cpp$\|\.hpp$\|\.php':
			\['/*', '*/', '*'],
			\'\.htm$\|\.html$\|\.xml$':
			\['<!--', '-->', '*'],
			\'\.js$':
			\['//', '//', '*'],
			\'\.tex$':
			\['%', '%', '*'],
			\'\.ml$\|\.mli$\|\.mll$\|\.mly$':
			\['(*', '*)', '*'],
			\'\.vim$\|\vimrc$':
			\['"', '"', '*'],
			\'\.el$\|\emacs$':
			\[';', ';', '*'],
			\'\.f90$\|\.f95$\|\.f03$\|\.f$\|\.for$':
			\['!', '!', '/']
			\}

function! s:filetype()
	let l:f = s:filename()

	let s:start	= '#'
	let s:end	= '#'
	let s:fill	= '*'

	for type in keys(s:types)
		if l:f =~ type
			let s:start	= s:types[type][0]
			let s:end	= s:types[type][1]
			let s:fill	= s:types[type][2]
		endif
	endfor

endfunction

" L'art ASCII occupe désormais les lignes 5 à 11 (décalé de 2 lignes).
function! s:ascii(n)
	return s:asciiart[a:n - 5]
endfunction

function! s:textline(left, right)
	let l:left = strpart(a:left, 0, s:length - s:margin * 2 - strlen(a:right))

	return s:start . repeat(' ', s:margin - strlen(s:start)) . l:left . repeat(' ', s:length - s:margin * 2 - strlen(l:left) - strlen(a:right)) . a:right . repeat(' ', s:margin - strlen(s:end)) . s:end
endfunction

" Ligne de texte centrée sur toute la largeur (utilisée pour la bannière).
function! s:centerline(text)
	let l:content = s:length - strlen(s:start) - strlen(s:end)
	let l:pad     = l:content - strlen(a:text)
	if l:pad < 0
		let l:pad = 0
	endif
	let l:left  = l:pad / 2
	let l:right = l:pad - l:left
	return s:start . repeat(' ', l:left) . a:text . repeat(' ', l:right) . s:end
endfunction

function! s:line(n)
	if a:n == 1 || a:n == 13 " top and bottom line
		return s:start . ' ' . repeat(s:fill, s:length - strlen(s:start) - strlen(s:end) - 2) . ' ' . s:end
	elseif a:n == 2 " bannière ANKAMA (ligne 1)
		return s:centerline(s:banner[0])
	elseif a:n == 3 " bannière ANKAMA (ligne 2)
		return s:centerline(s:banner[1])
	elseif a:n == 4 || a:n == 12 " blank line
		return s:textline('', '')
	elseif a:n == 5 || a:n == 7 || a:n == 9 " empty with ascii
		return s:textline('', s:ascii(a:n))
	elseif a:n == 6 " filename
		return s:textline(s:filename(), s:ascii(a:n))
	elseif a:n == 8 " author
		return s:textline("By: " . s:user() . " <" . s:mail() . ">", s:ascii(a:n))
	elseif a:n == 10 " created
		return s:textline("Created: " . s:date() . " by " . s:user(), s:ascii(a:n))
	elseif a:n == 11 " updated
		return s:textline("Updated: " . s:date() . " by " . s:user(), s:ascii(a:n))
	endif
endfunction

function! s:user()
	if exists('g:userName')
		return g:userName
	endif
	let l:user = $USER
	if strlen(l:user) == 0
		let l:user = "Gally"
	endif
	return l:user
endfunction

function! s:mail()
	if exists('g:mailName')
		return g:mailName
	endif
	let l:mail = $MAIL
	if strlen(l:mail) == 0
		let l:mail = "Gally@42.fr"
	endif
	return l:mail
endfunction

function! s:filename()
	let l:filename = expand("%:t")
	if strlen(l:filename) == 0
		let l:filename = "< new >"
	endif
	return l:filename
endfunction

function! s:date()
	return strftime("%Y/%m/%d %H:%M:%S")
endfunction

function! s:insert()
	let l:line = 13

	" empty line after header
	call append(0, "")

	" loop over lines
	while l:line > 0
		call append(0, s:line(l:line))
		let l:line = l:line - 1
	endwhile
endfunction

function! s:update()
	call s:filetype()
	if getline(11) =~ s:start . repeat(' ', s:margin - strlen(s:start)) . "Updated: "
		if &mod
			call setline(11, s:line(11))
		endif
		call setline(6, s:line(6))
		return 0
	endif
	return 1
endfunction

function! s:stdheader()
	if s:update()
		call s:insert()
	endif
endfunction

" Bind command and shortcut
command! Stdheader call s:stdheader ()
map <F1> :Stdheader<CR>
autocmd BufWritePre * call s:update ()
