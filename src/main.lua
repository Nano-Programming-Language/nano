local lexer = require "src.lexer"
local parser = require "src.parser"
local codegen = require "src.codegen"
local vm = require "src.vm"

local flags = {}
local files = {}

for _, v in ipairs(arg) do
    if v:sub(1, 1) == "-" then
        table.insert(flags, v)
    else
        table.insert(files, v)
    end
end

local function has_flag(flag)
    for _, f in ipairs(flags) do
        if f == flag then
            return true
        end
    end
    return false
end

local function run_source(source)
    local _lexer = lexer.new(source)
    local tokens = _lexer:tokenize()

    local _parser = parser.new(tokens)
    local ast = _parser:parse()

    local bytecode = codegen.generate(ast)
    ast = nil

    if has_flag("--bc-keep") then
        local bytecode_file = "output.nbc"
        local file = io.open(bytecode_file, "wb")
        if file then
            for _, item in ipairs(bytecode.bc) do
                file:write(tostring(item))
            end
            file:close()
        end
    end

    local _vm = vm.new(bytecode.bc)
    _vm:set_debug(false)
    _vm:run()
end

local function run_file(filepath)
    local file = io.open(filepath, "r")
    if not file then
        print("Error: Could not read file '" .. filepath .. "'.")
        os.exit(1)
    end

    local content = file:read("*a")
    file:close()

    if filepath:sub(-4) == ".nbc" then
        local _vm = vm.new(content)
        _vm:set_debug(false)
        _vm:run()
    else
        run_source(content)
    end
end

local function run_repl()
    print("Nano REPL - (CTRL + D to exit.)")
    while true do
        io.write("> ")
        local line = io.read("*l")

        if not line then
            break
        end

        local success, result = pcall(function()
            local _lexer = lexer.new(line)
            local tokens = _lexer:tokenize()

            local _parser = parser.new(tokens)
            local ast = _parser:parse()

            local bytecode = codegen.generate(ast)
            local _vm = vm.new(bytecode.bc)
            _vm:run()
            
            return true
        end)
        io.write("\n")
        
        if not success then
            print("Error: " .. tostring(result))
        end
    end
    
    print("Goodbye!")
end

if #files > 0 then
    for _, file in ipairs(files) do
        run_file(file)
    end
elseif has_flag("-v") then
    print("Nano - v0.0.1")
else
    run_repl()
end

