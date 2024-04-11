vim9script
# Author: Olex Hryshchenko <greeschenko@gmail.com>
# License: MIT
# Origin: https://github.com/greeschenko/vim9-ollama.git
#

g:ollama_compl_candidat = ""

def StartServer()
    const cmd = [ "ollama", "serve" ]
    const opts = {
        "err_cb": OnSrvError
    }
    const job = job_start(cmd, opts)
    echom "Starting server..."
enddef


def StopServer()
    const cmd = [ "pkill", "-SIGTERM", "ollama" ]
    const opts = {
        "err_cb": OnSrvError
    }
    const job = job_start(cmd, opts)
    echom "Stoping server..."
enddef


def OnSrvError(ch: channel, msg: string)
    echom msg
enddef

def OnResponse(ch: channel, msg: string)
    const json = json_decode(msg)

    echom json.response

    execute "normal! A" .. json.response
enddef

def OllamaAsk(promt: string)
  const api = "http://localhost:11434/api/generate"
  const data = {
    "model": "codellama:latest",
    "prompt": promt,
    "stream": true,
  }
  const cmd = [ "curl", "-X", "POST", "-d", json_encode(data), "--silent", api ]
  const opts = {
    "out_cb": OnResponse,
    "err_cb": OnError
  }
  const job = job_start(cmd, opts)
  silent execute "vertical belowright :60split /tmp/ollamaanswer.md"
  silent execute "set wrap linebreak"
  execute "normal ggVGd"
  echom "Searching..."
enddef

def OllamaChange(prompt: string)
  const start = getpos("'<")[1 : 2]
  const end = getpos("'>")[1 : 2]
  const lines = getline(start[0], end[0])
  var res: string
  for line in lines
    res = res .. line[start[1] - 1  : end[1] - 1]
  endfor

  execute "normal! " .. start[0] .. "gg" .. start[1] .. "|" .. "v" .. end[0] .. "gg" .. end[1] .. "|" .. "d"

  const api = "http://localhost:11434/api/generate"
  const data = {
    "model": "codellama:latest",
    "prompt": prompt .. res,
    "stream": true,
  }

  const cmd = [ "curl", "-X", "POST", "-d", json_encode(data), "--silent", api ]
  const opts = {
    "out_cb": OnResponse,
    "err_cb": OnError
  }
  const job = job_start(cmd, opts)
  echom "Searching..."
enddef

def OllamaChangeCode(prompt: string)
  const start = getpos("'<")[1 : 2]
  const end = getpos("'>")[1 : 2]
  const lines = getline(start[0], end[0])
  var res: string
  for line in lines
    res = res .. line[start[1] - 1  : end[1] - 1]
  endfor

  execute "normal! " .. start[0] .. "gg" .. start[1] .. "|" .. "v" .. end[0] .. "gg" .. end[1] .. "|" .. "d"

  const api = "http://localhost:11434/api/generate"
  const data = {
    "model": "codellama:latest",
    "prompt": '\\\' ..  &filetype
    .. res
    .. '\\\'
    .. '[INST] You are an expert programmer and personal assistant. Your task is to rewrite the above code with these instructions:'
    .. prompt
    .. '[/INST] Sure! Here is the rewritten code you requested:'
    .. '\\\' ..  &filetype,
    "stream": true,
    "options": {
      "seed": 123,
      "temperature": 0.4,
      "num_thread": 8,
      #"mirostat_eta": 0.5,
    },
  }

  const cmd = [ "curl", "-X", "POST", "-d", json_encode(data), "--silent", api ]
  const opts = {
    "out_cb": OnResponse,
    "err_cb": OnError
  }
  const job = job_start(cmd, opts)
  echom "Searching..."
enddef

def OllamaFill()
  const start = getpos("'<")[1 : 2]
  const end = getpos("'>")[1 : 2]
  const lines = getline(start[0], end[0])
  var res: string
  for line in lines
    res = '\\\' ..  &filetype .. " " .. res .. line[start[1] - 1  : end[1] - 1] .. '\\\'
  endfor

  execute "normal! " .. start[0] .. "gg" .. start[1] .. "|" .. "v" .. end[0] .. "gg" .. end[1] .. "|" .. "d"

  const api = "http://localhost:11434/api/generate"
  const data = {
    "model": "codellama:latest",
    "prompt": res,
    "stream": true,
    "options": {
      "seed": 123,
      "temperature": 0.4,
      "num_thread": 8,
      #"mirostat_eta": 0.5,
    },
  }

  const cmd = [ "curl", "-X", "POST", "-d", json_encode(data), "--silent", api ]
  const opts = {
    "out_cb": OnResponse,
    "err_cb": OnError
  }
  const job = job_start(cmd, opts)
  echom "Searching..."
enddef

def OllamaRead(prompt: string)
  const start = getpos("'<")[1 : 2]
  const end = getpos("'>")[1 : 2]
  const lines = getline(start[0], end[0])
  var res: string
  for line in lines
    res = res .. line[start[1] - 1  : end[1] - 1]
  endfor

  execute "normal! " .. end[0] .. "gg" .. end[1] .. "|" .. "o"

  const api = "http://localhost:11434/api/generate"
  const data = {
    "model": "codellama:latest",
    "prompt": prompt .. res,
    "stream": true,
  }
  const cmd = [ "curl", "-X", "POST", "-d", json_encode(data), "--silent", api ]
  const opts = {
    "out_cb": OnResponse,
    "err_cb": OnError
  }
  const job = job_start(cmd, opts)
  silent execute "vertical belowright :60split /tmp/ollamaanswer.md"
  silent execute "set wrap linebreak"
  execute "normal ggVGd"
  echom "Searching..."
enddef

#experimental function for inline code completion
def OllamaComplete()    
  var before_cursor = strpart(getline('.'), 0, col('.') - 1)    
  var after_cursor = strpart(getline('.'), col('.') - 1)
  var before_cursor_lines = ""
  var after_cursor_lines = ""

  prop_type_delete("ollama_compl_prop_type")

  g:ollama_before_cursor = before_cursor

  var line_num = getcurpos()[1]
  var prelines = 100
  if line_num < prelines
    prelines = line_num
  endif
  var linespre = getline(line_num - prelines, line_num - 1)
  var linesafter = getline(line_num + 1, line_num + 2)

  for [k, v] in items(linespre)
    before_cursor_lines ..= v
    if len(linespre) - 1 != k
      before_cursor_lines ..= "\n"
    endif
  endfor

  for [k, v] in items(linesafter)
    after_cursor_lines ..= v
    if len(linesafter) - 1 != k
      after_cursor_lines ..= "\n"
    endif
  endfor

  var res = printf(
    "%s\n%s",
    before_cursor_lines,
    before_cursor,
  )

  const api = "http://localhost:11434/api/generate"

  const prompt = res

  const data = {
    "model": "codellama:7b-code",
    "prompt": prompt,
    "stream": false,
    "options": {
      #"seed": 123,
      #"temperature": 0.4,
      #"temperature": 0,
      "num_predict": 256,
      "stop": ["\n\n", "<EOT>", "[INST]", "[/INST]"],
      #"num_thread": 8,
      #"mirostat_eta": 0.5,
    },
  }

  const cmd = [ "curl", "-X", "POST", "-d", json_encode(data), "--silent", api ]
  const opts = {
    "out_cb": OnResponseComplete,
    "err_cb": OnError
  }
  const job = job_start(cmd, opts)
  execute "normal a "
  :startinsert
  echom "Searching..."
enddef

def OnResponseComplete(ch: channel, msg: string)
    const json = json_decode(msg)
    const curlnum = getcurpos()[1]
    const curcol = getcurpos()[2]
    const res = substitute(json.response, g:ollama_before_cursor, '', 'g')
    const lines = split(res, "\n")

    prop_type_add("ollama_compl_prop_type", {highlight: 'Comment'})

    g:ollama_compl_candidat = res

    for line in lines
      prop_add(curlnum, 0, {
          text: line,
          type: "ollama_compl_prop_type",
          text_align: 'below',
          text_padding_left: curcol,
      })
    endfor

    autocmd CursorMovedI * call prop_type_delete("ollama_compl_prop_type")
    autocmd CursorMoved * call prop_type_delete("ollama_compl_prop_type")
enddef

def OllamaCompleteExc()    
  if g:ollama_compl_candidat != ""
    execute "normal! a" .. g:ollama_compl_candidat .. " "
    prop_type_delete("ollama_compl_prop_type")
    :w
    :e!
    :startinsert
  endif
enddef

def OnError(ch: channel, msg: string)
  echoe "ERROR: " .. msg
enddef

defcompile

command! -nargs=1 OllamaAsk call OllamaAsk(<f-args>)
command! -nargs=1 -range OllamaChange call OllamaChange(<f-args>)
command! -nargs=1 -range OllamaChangeCode call OllamaChangeCode(<f-args>)
command! -range OllamaFill call OllamaFill()
command! OllamaReStart call StartServer()
command! OllamaComplete call OllamaComplete()
command! OllamaCompleteExc call OllamaCompleteExc()
command! -nargs=1 -range OllamaRead call OllamaRead(<f-args>)

:autocmd VimEnter * call StartServer()
:autocmd VimLeavePre * call StopServer()

inoremap <C-l> <ESC><ESC>:OllamaComplete<CR>
inoremap <C-f> <ESC>:OllamaCompleteExc<CR>

# vim: et sw=2 sts=-1 cc=+1
