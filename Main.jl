using Pkg

try
    Pkg.activate(".")
    include("MainTranspiler.jl")
    using .Transpiler
catch e
    println("Error loading Transpiler module: $e")
    println("Make sure all required files (Lexer.jl, Parser.jl, Compiler.jl, FileProcessor.jl) are present.")
    exit(1)
end

function print_usage()
    println("Usage: julia Main.jl [OPTIONS]")
    println()
    println("Options:")
    println("  --interactive, -i          Start interactive mode")
    println("  --help, -h                Show this help message")
    println("  --compile EXPR            Compile a single expression")
    println("  --file INPUT OUTPUT       Process file from INPUT to OUTPUT")
    println("  --template TEMPLATE       Use template file (with --file)")
    println("  --create-template [FILE]  Create a sample template file")
    println("  --create_sample [FILE]	 Create a sample txt file with various math equations")
    println("  --inline                  Use inline math mode (default)")
    println("  --display                 Use display math mode")
    println("  --document-wrapper        Add complete LaTeX document wrapper")
    println()
    println("Examples:")
    println("  julia Main.jl --interactive")
    println("  julia Main.jl --compile \"x^2 + 3*y\"")
    println("  julia Main.jl --file input.txt output.tex")
    println("  julia Main.jl --file input.txt output.tex --template my_template.tex")
    println("  julia Main.jl --create-template my_template.tex")
    println("  julia Main.jl --file input.txt output.tex --display --document-wrapper")
end

function show_interactive_help()
    println("\nInteractive Mode Help:")
    println("═" ^ 50)
    println("• Enter any mathematical expression to convert to LaTeX")
    println("• Supported operations: +, -, *, /, ^, sqrt, sin, cos, etc.")
    println("• Use parentheses for grouping: (a + b) * c")
    println("• Functions: sqrt(x), sin(x), cos(x), log(x), exp(x)")
    println("• Greek letters: alpha, beta, gamma, theta, pi, etc.")
    println("\nCommands:")
    println("  help/h     - Show this help")
    println("  sample     - Show example expressions")
    println("  clear/cls  - Clear screen")
    println("  quit/q     - Exit")
    println("═" ^ 50)
    println()
end

function show_samples()
    println("\nSample Expressions:")
    println("═" ^ 50)

    samples = [
        ("Basic algebra", "x^2 + 3*y - 5"),
        ("Fractions", "(a + b) / (c - d)"),
        ("Square root", "sqrt(x^2 + y^2)"),
        ("Trigonometry", "sin(x) + cos(y)"),
        ("Logarithm", "log(x) + ln(y)"),
        ("Exponential", "e^(x^2)"),
        ("Complex", "sqrt((a + b)^2 + (c - d)^2)"),
        ("Greek letters", "alpha + beta * gamma")
    ]

    for (category, expr) in samples
        try
            result = compile(expr)
            println("$category:")
            println("  Input:  $expr")
            println("  LaTeX:  $result")
            println()
        catch e
            println("$category:")
            println("  Input:  $expr")
            println("  Error:  $e")
            println()
        end
    end

    println("═" ^ 50)
    println()
end

function interactive_mode()
    println("╔═══════════════════════════════════════╗")
    println("║        MathToLatex Interactive        ║")
    println("║     Math Expression → LaTeX Tool      ║")
    println("╚═══════════════════════════════════════╝")
    println()
    println("Enter mathematical expressions to convert to LaTeX.")
    println("Commands:")
    println("  help    - Show help")
    println("  quit,q    - Exit interactive mode")
    println("  clear   - Clear screen")
    println("  sample  - Show sample expressions")
    println()

    while true
        print("math> ")

        input = ""
        try
            input = readline()
        catch InterruptException
            println("\nUse 'quit' to exit gracefully.")
            continue
        end

        if isempty(strip(input))
            continue
        end

        cmd = strip(lowercase(input))

        if cmd in ["quit", "exit", "q"]
            break
        elseif cmd in ["help", "h"]
            show_interactive_help()
        elseif cmd in ["clear", "cls"]
            try
                run(`clear`)
            catch
                for i in 1:50
                    println()
                end
            end
        elseif cmd in ["sample", "samples"]
            show_samples()
        else
            latex_result = compile(input)
            println("LaTeX: $latex_result")
            println()
        end
    end
end

function compile_expression(expr::String)
    try
        result = compile(expr)
        println("LaTeX:  $result")
    catch e
        println("Error compiling expression '$expr': $e")
        exit(1)
    end
end

function process_files(input_file::String, output_file::String;
                      template_file::String="",
                      inline_math::Bool=true,
                      document_wrapper::Bool=false)
    println(template_file)
    try
        process_file(input_file, output_file,
                    inline_math=inline_math,
                    document_wrapper=document_wrapper,
                    template_file=template_file)

        if !isempty(template_file)
            println("Successfully processed '$input_file' into '$output_file' using template '$template_file'")
        else
            println("Successfully processed '$input_file' into '$output_file'")
        end
    catch e
        println("Error processing files: $e")
        exit(1)
    end
end

function create_template_file(template_file::String="template.tex")
    try
        create_sample_template(template_file)
        println("Template created: $template_file")
        println("Edit this file to customize your LaTeX document structure")
        println("Keep the '{{ generated }}' placeholder where you want the math expressions")
    catch e
        println("Error creating template: $e")
        exit(1)
    end
end

function create_sample_txt(sample_file::String="sample.txt")
	try
		create_sample_file(sample_file)
		println("Sample file created: $sample_file")
    catch e
        println("Error creating sample file: $e")
        exit(1)
    end
end

function main()
    args = ARGS

    if length(args) == 0
        print_usage()
        return
    end

    i = 1
    template_file = ""
    inline_math = true
    document_wrapper = false
    input_file = ""
    output_file = "output.tex"

    while i <= length(args)
        arg = args[i]

        if arg in ["--interactive", "-i"]
            interactive_mode()
            return

        elseif arg in ["--help", "-h"]
            print_usage()
            return

        elseif arg == "--compile"
            if i + 1 > length(args)
                println("Error: --compile requires an expression argument")
                exit(1)
            end
            compile_expression(args[i + 1])
            return

        elseif arg == "--create-template"
            if i + 1 <= length(args) && !startswith(args[i + 1], "--")
                create_template_file(args[i + 1])
                i += 1
            else
                create_template_file()
            end
            return

		elseif arg == "--create_sample"
			if i + 1 <= length(args) && !startswith(args[i + 1], "--")
                create_sample_file(args[i + 1])
                i += 1
            else
                create_sample_file()
            end
            return

        elseif arg == "--template"
            if i + 1 > length(args)
                println("Error: --template requires a template file argument")
                exit(1)
            end
            template_file = args[i + 1]
            println(template_file)
            if !isfile(template_file)
                println("Error: Template file '$template_file' does not exist")
                println("You can generate a basic template with the following: julia main.jl --create-template $template_file")
                exit(1)
            end
            i += 1

        elseif arg == "--inline"
            inline_math = true

        elseif arg == "--display"
            inline_math = false

        elseif arg == "--document-wrapper"
            document_wrapper = true

        elseif arg == "--file"
            if i + 2 > length(args)
                println("Error: --file requires input and output file arguments")
                exit(1)
            end

            input_file = args[i + 1]
            output_file = args[i + 2]

			i += 2

            if !isfile(input_file)
                println("Error: Input file '$input_file' does not exist")
                exit(1)
            end

        else
            println("Unknown option: $arg")
            print_usage()
            exit(1)
        end

        i += 1
    end
    process_files(input_file, output_file,
                         template_file=template_file,
                         inline_math=inline_math,
                         document_wrapper=document_wrapper)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

