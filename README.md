# MathToLatex Transpiler
![GitHub](https://img.shields.io/badge/Version-1.0-purple) ![GitHub](https://img.shields.io/badge/License-MIT-blue) ![GitHub](https://img.shields.io/badge/Status-Working-Green) ![GitHub](https://img.shields.io/badge/Tests-Passing-Green)

MathToLatex Transpiler is a small transpiler that compiles a custom math language to latex language.
Its purpose is to fasten note taking for math or physics lessons.

## Usage
Usage: `julia Main.jl [OPTIONS]`

Options:
```
--interactive, -i          Start interactive mode
--help, -h                Show this help message
--compile EXPR            Compile a single expression
--file INPUT OUTPUT       Process file from INPUT to OUTPUT
--template TEMPLATE       Use template file (with --file)
--create-template [FILE]  Create a sample template file
--create_sample [FILE]	 Create a sample txt file with various math equations
--inline                  Use inline math mode (default)
--display                 Use display math mode
--document-wrapper        Add complete LaTeX document wrapper

Examples:
julia Main.jl --interactive
julia Main.jl --compile \"x^2 + 3*y\"
julia Main.jl --file input.txt output.tex
julia Main.jl --file input.txt output.tex --template my_template.tex
julia Main.jl --create-template my_template.tex
julia Main.jl --file input.txt output.tex --display --document-wrapper
```

## Version changelog

### 1.0
- Trigonometry functions
- Greek Letters
- Basic math symbols (+, -, x, /)