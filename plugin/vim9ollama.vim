vim9script
# Author: Olex Hryshchenko <greeschenko@gmail.com>
# License: MIT
# Origin: https://github.com/greeschenko/vim9-ollama.git
#


### TODO prompt for change code with codelama
###    "prompt": '\\\' ..  &filetype
###    .. res
###    .. '\\\'
###    .. '[INST] You are an expert programmer and personal assistant. Your task is to rewrite the above code with these instructions:'
###    .. prompt
###    .. '[/INST] Sure! Here is the rewritten code you requested:'
###    .. '\\\' ..  &filetype,

g:ollama_compl_candidat = ""

if !exists("g:ollama_api")
  g:ollama_api = "http://localhost:11434/api/generate"
endif

if !exists("g:ollama_models")
  g:ollama_models = {
    "complete": {
      "name": "starcoder2:3b",
      "stream": false,
      "options": {
        "num_predict": 256,
        "temperature": 0.2,
        "stop": ["\n\n", "<EOT>", "[INST]", "[/INST]", '```'],
      },
      "prompt_template": [
        "```{filetype}",
        "{filecontext}",
        "{input}<|cursor|>{instruction}",
      ]
    },
    "change": {
      "name": "qwen2.5-coder:3b-instruct-q4_K_M",
      "stream": true,
      "options": {
        "temperature": 0.1,
        "num_predict": 512,
      },
      "prompt_template": [
        "You are an expert {filetype} developer.",
        "Rewrite the code strictly according to the instruction.",
        "Preserve formatting and style.",
        "Return only the modified code.",
        "",
        "Filetype: {filetype}",
        "",
        "File context:",
        "{filecontext}",
        "",
        "Instruction:",
        "{instruction}",
        "",
        "Input code:",
        "{input}",
        "",
        "Modified code:"
      ]
    },

    "chat": {
      "name": "qwen2.5-coder:3b-instruct-q4_K_M",
      "stream": true,
      "options": {
        "temperature": 0.3,
      },
      "prompt_template": [
        "You are a helpful programming assistant.",
        "Answer concisely and clearly.",
        "",
        "User question / instruction:",
        "{instruction}",
        "",
        "{input}",
        "",
        "Provide your answer below:"
      ]
    }
  }
endif

def GetModelConfig(model_key: string): dict<any>
  if !has_key(g:ollama_models, model_key)
    echoe "Unknown Ollama model key: " .. model_key
    return {}
  endif

  return g:ollama_models[model_key]
enddef

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

def GetSelectedText(): string
  const start = getpos("'<")[1 : 2]
  const end = getpos("'>")[1 : 2]
  const lines = getline(start[0], end[0])
  var selected = ""

  for i in range(len(lines))
    var line = lines[i]

    if i == 0
      line = line[start[1] - 1 :]
    endif

    if i == len(lines) - 1
      line = line[: end[1] - 1]
    endif

    selected ..= line
    if i < len(lines) - 1
      selected ..= "\n"
    endif
  endfor

  return selected
enddef

def DeleteSelection()
  const start = getpos("'<")[1]
  const end = getpos("'>")[1]
  deletebufline(bufnr(), start, end)
  cursor(max([1, line('.') - 1]), col('.'))
  append(line('.'), "")
enddef

def GetContext(linesAround: number = 50): string
  const cur = line(".")
  const ctx_start = max([1, cur - linesAround])
  const ctx_end = min([line("$"), cur + linesAround])
  return join(getline(ctx_start, ctx_end), "\n")
enddef

def CallOllamaApi(prompt: string, model_key: string, Callback: func)

  const model_cfg = GetModelConfig(model_key)

  if empty(model_cfg)
    return
  endif

  var data = {
    "model": model_cfg.name,
    "prompt": prompt,
    "stream": model_cfg.stream
  }

  if has_key(model_cfg, "options")
    data.options = model_cfg.options
  endif

  const cmd = [
    "curl",
    "-X", "POST",
    "-d", json_encode(data),
    "--silent",
    g:ollama_api
  ]

  const opts = {
    "out_cb": Callback,
    "err_cb": OnError
  }

  job_start(cmd, opts)
enddef

def ShowResultBuffer()
  silent execute "vertical belowright :60split /tmp/ollamaanswer.md"
  silent execute "set wrap linebreak"
  execute "normal ggVGd"
  setlocal filetype=markdown
enddef

def BuildOllamaPrompt(model_key: string, instruction: string, selected: string, filetype: string, ctx: string): string

  const model_cfg = GetModelConfig(model_key)

  if !has_key(model_cfg, "prompt_template")
    return instruction .. "\n\n" .. selected
  endif

  var template = join(model_cfg.prompt_template, "\n")

  template = substitute(template, "{instruction}", instruction, "g")
  template = substitute(template, "{input}", selected, "g")
  template = substitute(template, "{filetype}", filetype, "g")
  template = substitute(template, "{filecontext}", ctx, "g")

  return template
enddef

def OllamaAsk(instruction: string)
  var ctx = GetContext(get(g:, "ollama_context_lines", 50))
  var final_prompt = BuildOllamaPrompt(
    "chat", instruction, "", &filetype, ctx
  )

  ShowResultBuffer()

  CallOllamaApi(final_prompt, "chat", OnResponse)

  echom "Ollama says..."
enddef

def OllamaChange(instruction: string)

  var selected = GetSelectedText()
  var ctx = GetContext(get(g:, "ollama_context_lines", 50))

  DeleteSelection()

  var final_prompt = BuildOllamaPrompt(
    "change",
    instruction,
    selected,
    &filetype,
    ctx
  )

  CallOllamaApi(final_prompt, "change", OnResponse)

  echom "Ollama processing..."
  execute "normal! \<CR>"
enddef

def OllamaRead(instruction: string)
  var selected = GetSelectedText()
  var ctx = GetContext(get(g:, "ollama_context_lines", 50))
  var final_prompt = BuildOllamaPrompt(
    "chat", instruction, selected, &filetype, ""
  )

  ShowResultBuffer()

  CallOllamaApi(final_prompt, "chat", OnResponse)

  echom "Ollama says..."
enddef

#experimental function for inline code completion
def OllamaComplete()

  # remove previous ghost completion
  prop_type_delete("ollama_compl_prop_type")

  # get text before cursor
  var line_text = getline(".")
  var before_cursor = strpart(line_text, 0, col(".") - 1)
  var after_cursor  = strpart(line_text, col(".") - 1)

  # check if line is empty
  if empty(before_cursor)
    echom "Ollama: nothing before cursor"
    return
  endif

  # store prefix globally for response processing
  g:ollama_before_cursor = before_cursor

  # get current line number
  var line_num = line(".")

  # calculate context lines
  var ctx_lines = min([100, line_num])

  # read lines before cursor
  var linespre = getline(line_num - ctx_lines, line_num - 1)

  # join context
  var context = join(linespre, "\n")

  # check model config exists
  var model_cfg = GetModelConfig("complete")
  if empty(model_cfg)
    echoe "Ollama: complete model config not found"
    return
  endif

  # build prompt for inline completion
  var final_prompt = BuildOllamaPrompt(
    "complete",
    after_cursor,
    before_cursor,
    &filetype,
    context
  )

  # ensure prompt was built
  if empty(final_prompt)
    echoe "Ollama: prompt generation failed"
    return
  endif

  # debug message
  echom "Ollama: sending completion request"

  # call ollama API
  CallOllamaApi(final_prompt, "complete", OnResponseComplete)

  # enter insert mode without triggering mappings
  execute "normal a "
  feedkeys("i", "n")

  echom "Ollama completion..."

enddef

def OnResponseComplete(ch: channel, msg: string)
  echom "Ollama: got raw response -> " .. msg  # DEBUG: see raw API output

  const json = json_decode(msg)
  if !has_key(json, "response")
    echom "Ollama: response field missing"
    return
  endif

  const curlnum = getcurpos()[1]
  const curcol = getcurpos()[2]

  const res = substitute(json.response, g:ollama_before_cursor, '', 'g')
  echom "Ollama: processed completion -> " .. res  # DEBUG

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

  augroup ollama_complete
    autocmd!
    autocmd CursorMovedI * call prop_type_delete("ollama_compl_prop_type")
    autocmd CursorMoved * call prop_type_delete("ollama_compl_prop_type")
  augroup END
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
command! OllamaReStart call StartServer()
command! OllamaComplete call OllamaComplete()
command! OllamaCompleteExc call OllamaCompleteExc()
command! -nargs=1 -range OllamaRead call OllamaRead(<f-args>)

:autocmd VimEnter * call StartServer()
:autocmd VimLeavePre * call StopServer()

inoremap <C-l> <ESC><ESC>:OllamaComplete<CR>
inoremap <C-f> <ESC>:OllamaCompleteExc<CR>

# vim: et sw=2 sts=-1 cc=+1
