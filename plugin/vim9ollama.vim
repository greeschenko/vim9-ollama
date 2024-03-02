vim9script
# Author: Olex Hryshchenko <greeschenko@gmail.com>
# License: MIT
# Origin: https://github.com/greeschenko/vim9-ollama.git
#

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
    #"model": "deepseek-coder:latest",
    "prompt": '\\\' ..  &filetype
    .. res
    .. '\\\'
    .. '[INST] You are an expert programmer and personal assistant. Your task is to rewrite the above code with these instructions:'
    .. prompt
    .. '[/INST] Sure! Here is the rewritten code you requested:'
    .. '\\\' ..  &filetype,
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

def OllamaFill()
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
    "prompt": res,
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
    #"model": "deepseek-coder:latest",
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


def OnError(ch: channel, msg: string)
    echoe "ERROR: " .. msg
enddef


defcompile

command! -nargs=1 OllamaAsk call OllamaAsk(<f-args>)
command! -nargs=1 -range OllamaChange call OllamaChange(<f-args>)
command! -nargs=1 -range OllamaChangeCode call OllamaChangeCode(<f-args>)
command! -range OllamaFill call OllamaFill()
command! OllamaReStart call StartServer()
command! -nargs=1 -range OllamaRead call OllamaRead(<f-args>)

:autocmd VimEnter * call StartServer()
:autocmd VimLeavePre * call StopServer()

# vim: et sw=2 sts=-1 cc=+1
