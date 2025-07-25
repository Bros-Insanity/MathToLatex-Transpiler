module Transpiler

include("Lexer.jl")
include("Parser.jl")
include("Compiler.jl")
include("FileProcessor.jl")

using .Lexer
using .Parser
using .Compiler
using .FileProcessor

export tokenize, Token, TokenType
export MathParser, parse_expression
export MathCompiler, compile_math, compile_to_latex
export process_file, create_sample_file, create_sample_template

function compile(expression::String)::String
    tokens = tokenize(expression)
    parser = MathParser(tokens)
    ast = parse_expression(parser)
    compiler = MathCompiler()
    return compile_math(compiler, ast)
end

function compile_raw(expression::String)::String
    tokens = tokenize(expression)
    parser = MathParser(tokens)
    ast = parse_expression(parser)
    compiler = MathCompiler()
    return compile_to_latex(compiler, ast)
end

export compile, compile_raw

end # module Transpiler
