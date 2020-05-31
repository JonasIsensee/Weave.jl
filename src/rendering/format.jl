# TODO:
# - 1. do assertions for definition mandatory fields in `@define_format` macro
# - 2. implement fallback format/rendering functions in format.jl
# - 3. export this as public API


const FORMATS = Dict{String,WeaveFormat}()

# TODO: do some assertion for necessary fields of `format`
register_format!(format_name::AbstractString, format::WeaveFormat) = push!(FORMATS, format_name => format)
register_format!(_,format) = error("Format needs to be a subtype of WeaveFormat.")


# TODO: reorganize this file into multiple files corresponding to each output format

using Mustache, Highlights, .WeaveMarkdown, Markdown, Dates, Pkg
using REPL.REPLCompletions: latex_symbols

function format(doc, template = nothing, highlight_theme = nothing; css = nothing)
    docformat = doc.format
    # TODO : put docformat things earlier into docformat struct. that allows us to pass around fewer args
    docformat.highlight_theme = get_highlight_theme(highlight_theme)
    # this overwrites template given in docformat
    docformat.template = template
    restore_header!(doc)

    lines = map(copy(doc.chunks)) do chunk
        format_chunk(chunk, docformat)
    end
    body = join(lines, '\n')

    return render_doc(docformat, body, doc, css)
end

render_doc(_, body, args...) = body


get_highlight_theme(::Nothing) = Highlights.Themes.DefaultTheme
get_highlight_theme(highlight_theme::Type{<:Highlights.AbstractTheme}) = highlight_theme

get_html_template(::Nothing) = get_template(normpath(TEMPLATE_DIR, "md2html.tpl"))
get_html_template(x) = get_template(x)
get_tex_template(::Nothing) = get_template(normpath(TEMPLATE_DIR, "md2pdf.tpl"))
get_tex_template(x) = get_template(x)
get_template(path::AbstractString) = Mustache.template_from_file(path)
get_template(tpl::Mustache.MustacheTokens) = tpl

get_stylesheet(::Nothing) = get_stylesheet(normpath(STYLESHEET_DIR, "skeleton.css"))
get_stylesheet(path::AbstractString) = read(path, String)

get_highlight_stylesheet(mime, highlight_theme) =
    get_highlight_stylesheet(mime, get_highlight_theme(highlight_theme))
get_highlight_stylesheet(mime, highlight_theme::Type{<:Highlights.AbstractTheme}) =
    sprint((io, x) -> Highlights.stylesheet(io, mime, x), highlight_theme)