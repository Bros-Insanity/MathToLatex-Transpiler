module FileProcessor

using ..Lexer
using ..Parser
using ..Compiler

export process_file, create_sample_file, cli_main, interactive_mode, demo_mode, create_sample_template, apply_template

function create_latex_document(content::String)::String
    return """
\\documentclass{article}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\usepackage{amsfonts}
\\usepackage{mathtools}

\\begin{document}

$content

\\end{document}
"""
end

function process_file(input_file::String, output_file::String="";
                     inline_math::Bool=true, document_wrapper::Bool=false,
                     template_file::String="", mixed_content::Bool=true)
    if !isfile(input_file)
        error("Input file '$input_file' does not exist!")
    end

    if isempty(output_file)
        base_name = splitext(input_file)[1]
        output_file = "$base_name.tex"
    end

    compiler = MathCompiler()

    println("Processing file: $input_file")
    println("Output file: $output_file")

    content = read(input_file, String)
    lines = split(content, '\n')

    processed_lines = String[]

    for (line_num, line) in enumerate(lines)
        try
            line_str = String(line)
            if mixed_content
                processed_line = process_mixed_line(compiler, line_str)
            else
                processed_line = process_line(compiler, line_str, inline_math)
            end
            push!(processed_lines, processed_line)
        catch e
            @warn "Error processing line $line_num: '$line'" exception=e
            push!(processed_lines, String(line))
        end
    end

    processed_content = join(processed_lines, '\n')

    if !isempty(template_file)
        output_content = apply_template(template_file, processed_content)
    elseif document_wrapper
        output_content = create_latex_document(processed_content)
    else
        output_content = processed_content
    end

    write(output_file, output_content)

    println("File processed successfully!")
    println("Math expressions converted to LaTeX")
    println("Output saved to: $output_file")

    return output_file
end

function process_mixed_line(compiler::MathCompiler, line::String)::String
    if isempty(strip(line))
        return "\\\\"
    end

    if !contains(line, '$')
        return line * "\\\\"
    end

    result = ""
    i = 1

    while i <= length(line)
        if line[i] == '$'
            i += 1
            math_start = i

            while i <= length(line) && line[i] != '$'
                i += 1
            end

            if i > length(line)
                result *= '$' * line[math_start:end]
                break
            end

            math_expr = line[math_start:i-1]

            if !isempty(strip(math_expr))
                try
                    latex_code = compile_expression_to_latex(compiler, math_expr)
                    result *= "\$" * latex_code * "\$"
                catch e
                    @warn "Failed to compile math expression: '$math_expr'" exception=e
                    result *= "\$" * math_expr * "\$"
                end
            else
                result *= "\$\$"
            end

            i += 1
        else
            result *= line[i]
            i += 1
        end
    end

    return result * "\\\\"
end

function compile_expression_to_latex(compiler::MathCompiler, expression::String)::String
    tokens = tokenize(expression)
    parser = MathParser(tokens)
    ast = parse_expression(parser)
    return compile_to_latex(compiler, ast)
end

function process_line(compiler::MathCompiler, line::String, inline_math::Bool)::String
    if contains(line, r"\$\$|\$|```math")
        return line

    elseif startswith(strip(line), "MATH:")
        math_expr = strip(replace(line, r"^MATH:\s*" => ""))
        if !isempty(math_expr)
            latex_expr = compile_expression_safe(compiler, math_expr, inline_math)
            return replace(line, r"^MATH:\s*.*" => latex_expr)
        end

    elseif startswith(strip(line), "\$\$") || startswith(strip(line), "\$")
        return line

    elseif contains(line, r"[+\-*/^_()a-zA-Z0-9]") &&
           contains(line, r"[+\-*/^_]") &&
           !contains(line, r"[.,:;!?].*[+\-*/^_]") &&
           !contains(line, r"http|www|\.com|\.org") &&
           length(strip(line)) > 0

        stripped = String(strip(line))
        if is_likely_math_expression(stripped)
            latex_expr = compile_expression_safe(compiler, stripped, inline_math)
            return latex_expr
        end
    end

    return line
end

function is_likely_math_expression(line::String)::Bool
    if !contains(line, r"[+\-*/^_=]")
        return false
    end

    indicators = r"\b(the|and|or|but|if|then|when|where|how|what|is|are|was|were|have|has|had|will|would|could|should|may|might|can|must|shall|to|of|in|on|at|by|for|with|from|as|an|a|le|la|les|un|une|des|et|ou|mais|si|alors|quand|où|comment|que|quoi|est|sont|était|étaient|ai|as|a|avons|avez|ont|aurai|aurais|aurait|aurions|auriez|auraient|peux|peut|pouvons|pouvez|peuvent|dois|doit|devons|devez|doivent|peut|pourrais|pourrait|devrais|devrait|dois|doit|doit|à|de|dans|sur|par|pour|avec|sans|sous|entre|comme|en|au|aux|du|des)\b"i

    if contains(line, indicators)
        return false
    end

    if length(line) > 100
        return false
    end

    if contains(line, r"[.,:;!?]\s+[a-zA-Z]")
        return false
    end
    return true
end

function compile_expression_safe(compiler::MathCompiler, expression::String, inline::Bool)::String
    try
        tokens = tokenize(expression)
        parser = MathParser(tokens)
        ast = parse_expression(parser)
        return compile_math(compiler, ast, inline=inline)
    catch e
        @warn "Failed to compile expression: '$expression'" exception=e
        return expression
    end
end

function apply_template(template_file::String, generated_content::String)::String
    if !isfile(template_file)
        error("Template file '$template_file' does not exist!")
    end

    if isempty(template_file)
    	error("Template file '$template_file' is empty!")
    end

    template_content = read(template_file, String)

    output_content = replace(template_content, "{{ generated }}" => generated_content)

    return output_content
end

function create_sample_template(template_file::String="template.tex")::String
    template_content = """
\\documentclass{article}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\usepackage{amsfonts}
\\usepackage{mathtools}

\\title{Mathematical Expressions}
\\author{LaTeX Transpiler}
\\date{\\today}

\\begin{document}

\\maketitle

\\section{Generated Mathematical Expressions}

{{ generated }}

\\end{document}
"""

    write(template_file, template_content)
    println("Sample template created: $template_file")
    println("Edit this file to customize your LaTeX document structure")
    println("Keep the '{{ generated }}' placeholder where you want the math expressions")

    return template_file
end

function create_sample_file(filename::String="sample.txt")
    sample_content = """Some text here \$a+b\$

\$x^2 + y^2 = r^2\$
\$sin(theta) + cos(theta)\$
\$sqrt(sin(alpha+1)/inf))\$

More text here with \$sqrt(x^2 + y^2)\$ inline math.

Final paragraph with no math expressions."""

    open(filename, "w") do file
        write(file, sample_content)
    end

    println("Sample mixed content file created: $filename")
    return filename
end

end # module FileProcessor
