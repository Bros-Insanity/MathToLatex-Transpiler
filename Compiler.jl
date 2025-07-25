module Compiler

using ..Parser

using ..Parser: ASTNode, Number, Variable, BinaryOp, UnaryOp, FunctionCall

export MathCompiler, compile_math, compile_to_latex

struct MathCompiler
    latex_functions::Dict{String, String}

    function MathCompiler()
        latex_functions = Dict{String, String}()

        open("symbols.txt", "r") do file
            for line in eachline(file)
                parts = split(line, "=")
                if length(parts) == 2
                    key = strip(parts[1])
                    value = strip(parts[2])
                    latex_functions[key] = value
                end
            end
        end

        return new(latex_functions)
    end
end

function compile_node(compiler::MathCompiler, node::ASTNode)::String
    if isa(node, Number)
        return node.value

    elseif isa(node, Variable)

        if haskey(compiler.latex_functions, node.name)
            return compiler.latex_functions[node.name]
        end
        return node.name

    elseif isa(node, BinaryOp)
        left = compile_node(compiler, node.left)
        right = compile_node(compiler, node.right)

        if node.operator == "+"
            return "$left + $right"
        elseif node.operator == "-"
            return "$left - $right"
        elseif node.operator == "*"
            return "$left \\cdot $right"
        elseif node.operator == "/"
            return "\\frac{$left}{$right}"
        elseif node.operator == "^"
            return "$left^{$right}"
        elseif node.operator == "_"
            return "$left_{$right}"
        else
            error("Unknown binary operator: $(node.operator)")
        end

    elseif isa(node, UnaryOp)
        operand = compile_node(compiler, node.operand)

        if node.operator == "+"
            return "+$operand"
        elseif node.operator == "-"
            return "-$operand"
        else
            error("Unknown unary operator: $(node.operator)")
        end

    elseif isa(node, FunctionCall)
        func_name = node.name

        latex_func = get(compiler.latex_functions, func_name, func_name)

        if isempty(node.args)
            return latex_func
        end

        compiled_args = [compile_node(compiler, arg) for arg in node.args]

        if func_name == "sqrt"
            if length(compiled_args) == 1
                return "$latex_func{$(compiled_args[1])}"
            elseif length(compiled_args) == 2
                return "$latex_func[$(compiled_args[2])]{$(compiled_args[1])}"
            end
        elseif func_name in ["sum", "prod", "int"]
            if length(compiled_args) == 1
                return "$latex_func $(compiled_args[1])"
            else
                return "$latex_func\\left($(join(compiled_args, ", "))\\right)"
            end
        elseif func_name == "lim"
            if length(compiled_args) >= 2
                return "$latex_func_{$(compiled_args[1])} $(compiled_args[2])"
            else
                return "$latex_func $(compiled_args[1])"
            end
        else
            args_str = join(compiled_args, ", ")
            return "$latex_func\\left($args_str\\right)"
        end

    else
        error("Unknown AST node type: $(typeof(node))")
    end
end

function compile_math(compiler::MathCompiler, ast::ASTNode; inline::Bool=true)::String
    latex_code = compile_node(compiler, ast)

    if inline
        return "\$$latex_code\$"
    else
        return "\$\$$latex_code\$\$"
    end
end

function compile_to_latex(compiler::MathCompiler, ast::ASTNode)::String
    return compile_node(compiler, ast)
end

function compile_expression(expression::String; inline::Bool=true)::String
    tokens = tokenize(expression)
    parser = MathParser(tokens)
    ast = parse_expression(parser)
    compiler = MathCompiler()
    return compile_math(compiler, ast, inline=inline)
end

function debug_compile(expression::String)
    println("Expression: $expression")
    println("=" ^ 50)

    println("1. Tokenization:")
    tokens = tokenize(expression)
    for (i, token) in enumerate(tokens)
        println("   $i: $token")
    end
    println()

    println("2. Parsing (AST):")
    parser = MathParser(tokens)
    ast = parse_expression(parser)
    print_ast(ast)
    println()

    println("3. Compilation:")
    compiler = MathCompiler()
    latex = compile_math(compiler, ast)
    println("   LaTeX: $latex")
    println()

    return latex
end

end # module Compiler
