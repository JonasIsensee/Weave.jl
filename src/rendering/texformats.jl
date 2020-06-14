# Tex
# ---

abstract type TexFormat <: WeaveFormat end

function set_rendering_options!(docformat::TexFormat; keep_unicode = false, template=nothing, kwargs...)
    docformat.keep_unicode |= keep_unicode
    docformat.template = get_tex_template(template)
end

get_tex_template(::Nothing) = get_template(normpath(TEMPLATE_DIR, "md2pdf.tpl"))
get_tex_template(x) = get_template(x)

# very similar to export to html
function format_chunk(chunk::DocChunk, docformat::TexFormat)
    out = IOBuffer()
    io = IOBuffer()
    for inline in chunk.content
        if isa(inline, InlineText)
            write(io, inline.content)
        elseif !isempty(inline.rich_output)
            clear_buffer_and_format!(io, out, WeaveMarkdown.latex)
            write(out, addlines(inline.rich_output, inline))
        elseif !isempty(inline.figures)
            write(io, inline.figures[end], inline)
        elseif !isempty(inline.output)
            write(io, addlines(inline.output, inline))
        end
    end
    clear_buffer_and_format!(io, out, WeaveMarkdown.latex)
    out = take2string!(out)
    return unicode2latex(docformat, out)
end
format_termchunk(chunk, docformat::TexFormat) = string(docformat.termstart, chunk.output, docformat.termend, "\n")

format_output(result, docformat::TexFormat) = unicode2latex(docformat, result, true)

format_code(code, docformat::TexFormat) = unicode2latex(docformat, code, true)

# from julia symbols (e.g. "\bfhoge") to valid latex
const UNICODE2LATEX = let
    function texify(s)
        return if occursin(r"^\\bf[A-Z]$", s)
            replace(s, "\\bf" => "\\bm{\\mathrm{") * "}}"
        elseif startswith(s, "\\bfrak")
            replace(s, "\\bfrak" => "\\bm{\\mathfrak{") * "}}"
        elseif startswith(s, "\\bf")
            replace(s, "\\bf" => "\\bm{\\") * "}"
        elseif startswith(s, "\\frak")
            replace(s, "\\frak" => "\\mathfrak{") * "}"
        else
            s
        end
    end
    Dict(unicode => texify(sym) for (sym, unicode) in REPL.REPLCompletions.latex_symbols)
end

function unicode2latex(docformat::TexFormat, s, escape = false)
    # Check whether to convert at all and return input if not
    docformat.keep_unicode && return s
    for (unicode, latex) in UNICODE2LATEX
        body = "\\ensuremath{$(latex)}"
        target = escape ? string(docformat.escape_starter, body, docformat.escape_closer) : body
        s = replace(s, unicode => target)
    end
    return s
end

function formatfigures(chunk, docformat::TexFormat)
    fignames = chunk.figures
    caption = chunk.options[:fig_cap]
    width = chunk.options[:out_width]
    height = chunk.options[:out_height]
    f_pos = chunk.options[:fig_pos]
    f_env = chunk.options[:fig_env]
    result = ""
    figstring = ""

    if isnothing(f_env) && !isnothing(caption)
        f_env = "figure"
    end

    (isnothing(f_pos)) && (f_pos = "!h")
    # Set size
    attribs = ""
    isnothing(width) || (attribs = "width=$(md_length_to_latex(width,"\\linewidth"))")
    (!isempty(attribs) && !isnothing(height)) && (attribs *= ",")
    isnothing(height) || (attribs *= "height=$(md_length_to_latex(height,"\\paperheight"))")

    if !isnothing(f_env)
        result *= "\\begin{$f_env}"
        (!isempty(f_pos)) && (result *= "[$f_pos]")
        result *= "\n"
    end

    for fig in fignames
        if splitext(fig)[2] == ".tex" # Tikz figures
            figstring *= "\\resizebox{$width}{!}{\\input{$fig}}\n"
        else
            if isempty(attribs)
                figstring *= "\\includegraphics{$fig}\n"
            else
                figstring *= "\\includegraphics[$attribs]{$fig}\n"
            end
        end
    end

    # Figure environment
    if !isnothing(caption)
        result *= string("\\center\n", "$figstring", "\\caption{$caption}\n")
    else
        result *= figstring
    end

    if !isnothing(chunk.options[:label]) && !isnothing(f_env)
        label = chunk.options[:label]
        result *= "\\label{fig:$label}\n"
    end

    if !isnothing(f_env)
        result *= "\\end{$f_env}\n"
    end

    return result
end

function md_length_to_latex(def, reference)
    if occursin("%", def)
        _def = tryparse(Float64, replace(def, "%" => ""))
        isnothing(_def) && return def
        perc = round(_def / 100, digits = 2)
        return "$perc$reference"
    end
    return def
end

function render_doc(docformat::TexFormat, body, doc)
    return Mustache.render(
        docformat.template;
        body = body,
        highlight = "",
        tex_deps = docformat.tex_deps,
        [Pair(Symbol(k), v) for (k, v) in doc.header]...,
    )
end

# minted Tex
# ----------

Base.@kwdef mutable struct TexMinted <: TexFormat
    description = "Latex using minted for highlighting"
    extension = "tex"
    codestart = "\\begin{minted}[escapeinside=||, mathescape, fontsize=\\small, xleftmargin=0.5em]{julia}"
    codeend = "\\end{minted}"
    termstart = "\\begin{minted}[escapeinside=||, mathescape, fontsize=\\footnotesize, xleftmargin=0.5em]{jlcon}"
    termend = "\\end{minted}"
    outputstart = "\\begin{minted}[escapeinside=||, mathescape, fontsize=\\small, xleftmargin=0.5em, frame = leftline]{text}"
    outputend = "\\end{minted}"
    mimetypes = ["application/pdf", "image/png", "text/latex", "text/plain"]
    fig_ext = ".pdf"
    out_width = "\\linewidth"
    out_height = nothing
    fig_pos = "htpb"
    fig_env = "figure"
    # specials
    keep_unicode = false
    template = nothing
    tex_deps = "\\usepackage{minted}"
    # how to escape latex in verbatim/code environment
    escape_starter = "|\$"
    escape_closer = reverse(escape_starter)
end
register_format!("texminted", TexMinted())
register_format!("mintedpdf", LatexPDF(TexMinted(), "xelatex --shell-escape"))
# Tex (directly to PDF)
# ---------------------

Base.@kwdef mutable struct JMarkdown2PDF <: TexFormat
    description = "Julia markdown to latex"
    extension = "tex"
    codestart = ""
    codeend = ""
    termstart = codestart
    termend = codeend
    outputstart = "\\begin{lstlisting}"
    outputend = "\\end{lstlisting}\n"
    mimetypes = ["application/pdf", "image/png", "image/jpg",
        "text/latex", "text/markdown", "text/plain"]
    fig_ext = ".pdf"
    out_width = "\\linewidth"
    out_height = nothing
    fig_pos = nothing
    fig_env = nothing
    # specials
    highlight_theme = nothing
    template = nothing
    keep_unicode = false
    tex_deps = ""
    # how to escape latex in verbatim/code environment
    escape_starter = "(*@"
    escape_closer = "@*)"
end
register_format!("md2tex", JMarkdown2PDF())
register_format!("md2pdf", LatexPDF(JMarkdown2PDF(), "xelatex"))

function set_rendering_options!(docformat::JMarkdown2PDF; template = nothing, highlight_theme = nothing, keep_unicode = false, kwargs...)
    docformat.template = get_tex_template(template)
    docformat.highlight_theme = get_highlight_theme(highlight_theme)
    docformat.keep_unicode |= keep_unicode
end

function render_doc(docformat::JMarkdown2PDF, body, doc)
    return Mustache.render(
        docformat.template;
        body = body,
        highlight = get_highlight_stylesheet(MIME("text/latex"), docformat.highlight_theme),
        tex_deps = docformat.tex_deps,
        [Pair(Symbol(k), v) for (k, v) in doc.header]...,
    )
end

function format_output(result, docformat::JMarkdown2PDF)
    # Highligts has some extra escaping defined, eg of $, ", ...
    result_escaped = sprint(
        (io, x) ->
            Highlights.Format.escape(io, MIME("text/latex"), x, charescape = true),
        result,
    )
    return unicode2latex(docformat, result_escaped, true)
end

function format_code(code, docformat::JMarkdown2PDF)
    ret = highlight_code(MIME("text/latex"), code, docformat.highlight_theme)
    unicode2latex(docformat, ret, false)
end

format_termchunk(chunk, docformat::JMarkdown2PDF) =
    should_render(chunk) ? highlight_term(MIME("text/latex"), chunk.output, docformat.highlight_theme) : ""
