
# Weave.jl - Scientific Reports Using Julia

This is the documentation of [Weave.jl](http://github.com/mpastell/weave.jl).
Weave is a scientific report generator/literate programming tool for Julia.
It resembles
[Pweave](http://mpastell.com/pweave),
[knitr](https://yihui.org/knitr/),
[R Markdown](https://rmarkdown.rstudio.com/),
and [Sweave](https://stat.ethz.ch/R-manual/R-patched/library/utils/doc/Sweave.pdf).


**Current features**

* Markdown, script of Noweb syntax for input documents
* Publish markdown directly to html and pdf using Julia or Pandoc markdown
* Execute code as terminal or "script" chunks
* Capture Plots.jl or  Gadfly.jl figures
* Supports LaTex, Pandoc, GitHub markdown, MultiMarkdown, Asciidoc and reStructuredText output
* Simple caching of results
* Convert to and from IJulia notebooks

![Weave in Juno demo](https://user-images.githubusercontent.com/40514306/76081328-32f41900-5fec-11ea-958a-375f77f642a2.png)

## Contents

```@contents
Pages = ["getting_started.md", "usage.md",
"publish.md", "chunk_options.md", "notebooks.md",
"function_index.md"]
```
