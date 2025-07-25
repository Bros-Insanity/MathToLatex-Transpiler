module Parser

using ..Lexer

using ..Lexer: Token, TokenType, NUMBER, IDENTIFIER, OPERATOR, FUNCTION, LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET, EOF, UNKNOWN

export ASTNode, BinaryOp, UnaryOp, Number, Variable, FunctionCall, MathParser, parse_expression

abstract type ASTNode end

struct Number <: ASTNode
    value::String
end

struct Variable <: ASTNode
    name::String
end

struct BinaryOp <: ASTNode
    left::ASTNode
    operator::String
    right::ASTNode
end

struct UnaryOp <: ASTNode
    operator::String
    operand::ASTNode
end

struct FunctionCall <: ASTNode
    name::String
    args::Vector{ASTNode}
end

Base.show(io::IO, node::Number) = print(io, "Number($(node.value))")
Base.show(io::IO, node::Variable) = print(io, "Variable($(node.name))")
Base.show(io::IO, node::BinaryOp) = print(io, "BinaryOp($(node.left) $(node.operator) $(node.right))")
Base.show(io::IO, node::UnaryOp) = print(io, "UnaryOp($(node.operator) $(node.operand))")
Base.show(io::IO, node::FunctionCall) = print(io, "FunctionCall($(node.name), $(node.args))")


mutable struct MathParser
    tokens::Vector{Token}
    position::Int
    current_token::Token

    function MathParser(tokens::Vector{Token})
        parser = new(tokens, 1, Token(EOF, "", 0))
        if !isempty(tokens)
            parser.current_token = tokens[1]
        end
        return parser
    end
end

function advance!(parser::MathParser)
    parser.position += 1
    if parser.position <= length(parser.tokens)
        parser.current_token = parser.tokens[parser.position]
    else
        parser.current_token = Token(EOF, "", parser.position)
    end
end

function peek_token(parser::MathParser)::Token
    if parser.position + 1 <= length(parser.tokens)
        return parser.tokens[parser.position + 1]
    end
    return Token(EOF, "", parser.position + 1)
end

function match_token(parser::MathParser, token_type::TokenType, value::String="")::Bool
    if parser.current_token.type == token_type
        return isempty(value) || parser.current_token.value == value
    end
    return false
end

function consume!(parser::MathParser, token_type::TokenType, value::String="")
    if match_token(parser, token_type, value)
        current = parser.current_token
        advance!(parser)
        return current
    else
        expected = isempty(value) ? string(token_type) : "$token_type('$value')"
        error("Expected $expected, got $(parser.current_token)")
    end
end

function parse_primary(parser::MathParser)::ASTNode
    token = parser.current_token

    if token.type == NUMBER
        advance!(parser)
        return Number(token.value)
    end

    if token.type == IDENTIFIER || token.type == FUNCTION
        name = token.value
        advance!(parser)

        if parser.current_token.type == LPAREN
            advance!(parser) # consume '('

            args = ASTNode[]

            if parser.current_token.type != RPAREN
                push!(args, parse_expression(parser))

                while parser.current_token.type == OPERATOR && parser.current_token.value == ","
                    advance!(parser) # consume ','
                    push!(args, parse_expression(parser))
                end
            end

            consume!(parser, RPAREN)
            return FunctionCall(name, args)
        else
            return Variable(name)
        end
    end

    if token.type == LPAREN
        advance!(parser) # consume '('
        node = parse_expression(parser)
        consume!(parser, RPAREN)
        return node
    end

    error("Unexpected token: $token")
end

function parse_unary(parser::MathParser)::ASTNode
    if parser.current_token.type == OPERATOR && parser.current_token.value in ["+", "-"]
        operator = parser.current_token.value
        advance!(parser)
        operand = parse_unary(parser)
        return UnaryOp(operator, operand)
    end

    return parse_primary(parser)
end

function parse_power(parser::MathParser)::ASTNode
    left = parse_unary(parser)

    while parser.current_token.type == OPERATOR && parser.current_token.value in ["^", "_"]
        operator = parser.current_token.value
        advance!(parser)
        right = parse_unary(parser)
        left = BinaryOp(left, operator, right)
    end

    return left
end

function parse_term(parser::MathParser)::ASTNode
    left = parse_power(parser)

    while parser.current_token.type == OPERATOR && parser.current_token.value in ["*", "/"]
        operator = parser.current_token.value
        advance!(parser)
        right = parse_power(parser)
        left = BinaryOp(left, operator, right)
    end

    return left
end

function parse_expression(parser::MathParser)::ASTNode
    left = parse_term(parser)

    while parser.current_token.type == OPERATOR && parser.current_token.value in ["+", "-"]
        operator = parser.current_token.value
        advance!(parser)
        right = parse_term(parser)
        left = BinaryOp(left, operator, right)
    end

    return left
end

function parse(tokens::Vector{Token})::ASTNode
    parser = MathParser(tokens)
    ast = parse_expression(parser)

    if parser.current_token.type != EOF
        @warn "Unexpected tokens remaining: $(parser.current_token)"
    end

    return ast
end

function print_ast(node::ASTNode, indent::Int=0)
    spaces = "  " ^ indent

    if isa(node, Number)
        println("$(spaces)Number: $(node.value)")
    elseif isa(node, Variable)
        println("$(spaces)Variable: $(node.name)")
    elseif isa(node, BinaryOp)
        println("$(spaces)BinaryOp: $(node.operator)")
        print_ast(node.left, indent + 1)
        print_ast(node.right, indent + 1)
    elseif isa(node, UnaryOp)
        println("$(spaces)UnaryOp: $(node.operator)")
        print_ast(node.operand, indent + 1)
    elseif isa(node, FunctionCall)
        println("$(spaces)FunctionCall: $(node.name)")
        for arg in node.args
            print_ast(arg, indent + 1)
        end
    end
end

end # module Parser
