module Lexer

export Token, TokenType, tokenize

@enum TokenType begin
    NUMBER
    IDENTIFIER
    OPERATOR
    FUNCTION
    LPAREN
    RPAREN
    LBRACE
    RBRACE
    LBRACKET
    RBRACKET
    EOF
    UNKNOWN
end

struct Token
    type::TokenType
    value::String
    position::Int
end

Base.show(io::IO, token::Token) = print(io, "Token($(token.type), \"$(token.value)\", $(token.position))")

mutable struct MathLexer
    input::String
    position::Int
    current_char::Union{Char, Nothing}

    function MathLexer(input::String)
        lexer = new(input, 1, nothing)
        lexer.current_char = lexer.position <= length(input) ? input[lexer.position] : nothing
        return lexer
    end
end

function advance!(lexer::MathLexer)
    lexer.position += 1
    if lexer.position <= length(lexer.input)
        lexer.current_char = lexer.input[lexer.position]
    else
        lexer.current_char = nothing
    end
end

function peek(lexer::MathLexer)::Union{Char, Nothing}
    peek_pos = lexer.position + 1
    if peek_pos <= length(lexer.input)
        return lexer.input[peek_pos]
    end
    return nothing
end

function skip_whitespace!(lexer::MathLexer)
    while lexer.current_char !== nothing && isspace(lexer.current_char)
        advance!(lexer)
    end
end

function read_number(lexer::MathLexer)::String
    result = ""
    start_pos = lexer.position

    while lexer.current_char !== nothing && (isdigit(lexer.current_char) || lexer.current_char == '.')
        result *= lexer.current_char
        advance!(lexer)
    end

    return result
end

function read_identifier(lexer::MathLexer)::String
    result = ""

    while lexer.current_char !== nothing && (isletter(lexer.current_char) || isdigit(lexer.current_char) || lexer.current_char == '_')
        result *= lexer.current_char
        advance!(lexer)
    end

    return result
end

function is_function(identifier::String)::Bool
    functions = Set([
        "sqrt", "sin", "cos", "tan", "log", "ln", "exp",
        "sum", "int", "lim", "max", "min",
        "alpha", "beta", "gamma", "delta", "theta", "pi", "infinity",
        "lambda", "mu", "nu", "sigma", "omega"
    ])
    return identifier in functions
end

function next_token(lexer::MathLexer)::Token
    while lexer.current_char !== nothing
        if isspace(lexer.current_char)
            skip_whitespace!(lexer)
            continue
        end

        pos = lexer.position

        if isdigit(lexer.current_char)
            number = read_number(lexer)
            return Token(NUMBER, number, pos)
        end

        if isletter(lexer.current_char)
            identifier = read_identifier(lexer)
            token_type = is_function(identifier) ? FUNCTION : IDENTIFIER
            return Token(token_type, identifier, pos)
        end

        char = lexer.current_char
        advance!(lexer)

        if char == '+'
            return Token(OPERATOR, "+", pos)
        elseif char == '-'
            return Token(OPERATOR, "-", pos)
        elseif char == '*'
            return Token(OPERATOR, "*", pos)
        elseif char == '/'
            return Token(OPERATOR, "/", pos)
        elseif char == '^'
            return Token(OPERATOR, "^", pos)
        elseif char == '_'
            return Token(OPERATOR, "_", pos)
        elseif char == '('
            return Token(LPAREN, "(", pos)
        elseif char == ')'
            return Token(RPAREN, ")", pos)
        elseif char == '{'
            return Token(LBRACE, "{", pos)
        elseif char == '}'
            return Token(RBRACE, "}", pos)
        elseif char == '['
            return Token(LBRACKET, "[", pos)
        elseif char == ']'
            return Token(RBRACKET, "]", pos)
        else
            return Token(UNKNOWN, string(char), pos)
        end
    end

    return Token(EOF, "", lexer.position)
end

function tokenize(expression::String)::Vector{Token}
    lexer = MathLexer(expression)
    tokens = Token[]

    while true
        token = next_token(lexer)
        push!(tokens, token)

        if token.type == EOF
            break
        end
    end

    return tokens
end

function print_tokens(tokens::Vector{Token})
    println("Tokens:")
    for (i, token) in enumerate(tokens)
        println("  $i: $token")
    end
end

end # module Lexer
