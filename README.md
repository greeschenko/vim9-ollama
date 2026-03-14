# vim9-ollama

**Local AI coding assistant for Vim 9 powered by Ollama.**

`vim9-ollama` is a modern **Vim9script plugin** that integrates **local LLMs** into Vim.  
It provides AI-powered chat, code rewriting, code review, and **inline code completion**.

All AI inference runs **locally** using **Ollama**, so your code never leaves your machine.

---

## Features

- 🧠 Local AI coding assistant
- ⚡ Written in modern **Vim9script**
- 🔌 **Autoload architecture** for fast startup
- 💬 Chat with LLM about your code
- ✏️ Rewrite / refactor selected code
- 🔍 Code review and suggestions
- 🤖 Inline AI completion (experimental)
- ⚙️ Fully configurable models and prompts

---

## Requirements

- **Vim ≥ 9.0**
- **Ollama**

Install Ollama:

```bash
curl -fsSL https://ollama.com/install.sh | sh
````

Start the Ollama server:

```bash
ollama serve
```

Download recommended models:

```bash
ollama pull starcoder2:3b
ollama pull qwen2.5-coder:3b
```

---

## Installation

Using **vim-plug**:

```vim
Plug 'greeschenko/vim9-ollama'
```

Restart Vim.

The plugin will automatically start the Ollama server on Vim startup.

---

## Configuration

The plugin can be configured via global Vim variables.

Example configuration:

````vim
let g:ollama_api = "http://localhost:11434/api/generate"

let g:ollama_models = {
\ "complete": {
\   "name": "starcoder2:3b",
\   "stream": v:false,
\   "options": {
\     "num_predict": 256,
\     "temperature": 0.2
\   },
\   "prompt_template": [
\     "```{filetype}",
\     "{filecontext}",
\     "{input}<|cursor|>{instruction}"
\   ]
\ },
\
\ "change": {
\   "name": "qwen2.5-coder:3b",
\   "stream": v:true,
\   "options": {
\     "temperature": 0.1,
\     "num_predict": 512
\   }
\ },
\
\ "chat": {
\   "name": "qwen2.5-coder:3b",
\   "stream": v:true,
\   "options": {
\     "temperature": 0.3
\   }
\ }
\ }
````

You can customize:

* model names
* temperature
* token limits
* prompt templates

---

## Commands

### Ask the LLM

Ask a question about the current file or code context.

```
:OllamaAsk Explain this function
```

The response will appear in a split window.

---

### Rewrite selected code

Select code in **visual mode** and run:

```
:OllamaChange Refactor this function
```

Examples:

```
:OllamaChange Improve readability
```

```
:OllamaChange Add logging
```

```
:OllamaChange Convert this to Go generics
```

The selected code will be replaced with the modified version.

---

### Review selected code

Select code and run:

```
:OllamaRead What could be improved here?
```

This displays AI comments in a separate buffer.

---

## Inline Code Completion (Experimental)

Inline completion works similarly to **GitHub Copilot**.

### Trigger completion

Press:

```
Ctrl + L
```

This sends the current context to the model and shows a **ghost suggestion** below the cursor.

Press again to request another suggestion.

---

### Accept completion

Press:

```
Ctrl + F
```

The suggested code will be inserted into the buffer.

---

## How Completion Works

The plugin sends a **Fill-in-the-Middle (FIM)** prompt to the model.

Example input:

```go
fmt.Printf(<|cursor|>"hello")
```

The model generates the missing code at the cursor position.

---

## Architecture

The plugin uses **modern Vim9 autoload architecture**.

```
vim9-ollama
├─ plugin
│  └─ vim9ollama.vim
│
└─ autoload
   └─ vim9ollama.vim
```

* `plugin/` defines commands and key mappings
* `autoload/` contains implementation
* functions load **only when used**

This keeps Vim startup fast.

---

## Troubleshooting

### Ollama does not respond

Restart the server:

```
:call ollama.StartServer()
```

Or manually:

```bash
pkill ollama
ollama serve
```

---

## Roadmap

Planned improvements:

* streaming inline completion
* better FIM prompts
* async UI updates
* multi-buffer context
* configurable keymaps
* model selection per filetype

---

## License

MIT

---

## Author

Olex Hryshchenko
[https://github.com/greeschenko](https://github.com/greeschenko)

```
```
