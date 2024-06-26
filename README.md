# vim9-ollama

Local driven AI assistent plugin written in the cutting-edge Vim9 script and powered by ollama and codellama

https://github.com/greeschenko/vim9-ollama/assets/2754533/9091d416-1ef2-4651-b954-f563000b3f8d

## Requirement

This plugin supports Vim version 9.0+.

You need install [ollama](https://ollama.com/) and test it with following commands

```bash
ollama serve
ollama pull codellama:latest
ollama pull codellama:7b-code

ollama run codellama:latest
```

## Configuration

Add to your .vimrc

```vim
Plug 'greeschenko/vim9-ollama'
```

## Usage

1. type in vim console

```bash
    :OllamaAsk Tell me a joke
```

return a random joke or another ansver for your question in the cursor position line

2. select text or code and type in vim console

```bash
    :OllamaChange Modify the following text to improve grammar and spelling, just output the final text without additional quotes around it
```

this command replace text with correct text with improved gramma and spelling

3. select code and type in vim console

```bash
    :OllamaChangeCode Add extra logging in this function
```

this command replace you code with updated

4. prepere not completite code with <FILL> in midle

```go
func fibanachi(a, b){
    <FILL>
}
```
select whis code and type

```bash
    :OllamaFill
```

this command replace you code with complete function

5. select text or code and type in vim console

```bash
    :OllamaRead what I can change in this
```

this command write after selection text a LLM comments about this

## Inline Completion

You can use this experimental function some kind like copilot

start write a code and pres `<C-l>` you can see a completion candidat press `<C-l>` again and you get new candidat
when you get correct variant press `<C-f>` to paste code in the buffer

## Troubleshooting

If you run multiple Vim instances and Ollama does not respond, try running the command `:OllamaReStart`.
This will restart the Ollama server and fix any connection issues."

