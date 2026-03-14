vim9script

import autoload "vim9ollama.vim" as ollama

# Plugin loader for Ollama
# Functions are autoloaded from autoload/ollama.vim9

# Chat commands
command! -nargs=1 OllamaAsk call ollama.OllamaAsk(<f-args>)
command! -nargs=1 -range OllamaChange call ollama.OllamaChange(<f-args>)
command! OllamaComplete call ollama.OllamaComplete()
command! OllamaCompleteExc call ollama.OllamaCompleteExc()
command! -nargs=1 -range OllamaRead call ollama.OllamaRead(<f-args>)

# Start/stop server automatically
:autocmd VimEnter * call ollama.StartServer()
:autocmd VimLeavePre * call ollama.StopServer()

# Key mappings
inoremap <C-l> <ESC><ESC>:OllamaComplete<CR>
inoremap <C-f> <ESC>:OllamaCompleteExc<CR>
