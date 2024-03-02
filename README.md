# vim9-ollama

Local driven AI assistent plugin written in the cutting-edge Vim9 script and powered by ollama

## Requirement

This plugin supports Vim version 9.0+.

You need install [ollama](https://ollama.com/) and test it with following commands

```bash
ollama serve

ollama run codellama
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

## Troubleshooting

If you run multiple Vim instances and Ollama does not respond, try running the command `:OllamaReStart`.
This will restart the Ollama server and fix any connection issues."

