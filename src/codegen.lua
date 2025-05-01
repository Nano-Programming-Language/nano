local ast = require "src.ast"
local bytecode = {}

bytecode.OPCODES = 
{
    PUSH = "PUSH",
    POP = "POP",
    LDV = "LDV",
    STV = "STV",
    PRINT = "PRINT",
    PRINTLN = "PRINTLN",
    READLN = "READLN",
    ADD = "ADD",
    SUB = "SUB",
    MUL = "MUL",
    DIV = "DIV",
    HALT = "HALT",
    CALL = "CALL",
    FUNC = "FUNC",
    RET = "RET",
}

local char_map = 
{
    ["PUSH"] = "\x01",  
    ["POP"] = "\x02",
    ["LDV"] = "\x03",
    ["STV"] = "\x04",
    ["PRINT"] = "\x05",
    ["PRINTLN"] = "\x06",
    ["ADD"] = "\x07",
    ["SUB"] = "\x08",
    ["MUL"] = "\x09",
    ["DIV"] = "\x0A",
    ["HALT"] = "\x0B",
    ["CALL"] = "\x0C",
    ["FUNC"] = "\x0D",
    ["RET"] = "\x0E",
    ["READLN"] = "\xA0"
}

local function compress(code_section, data_section)
    local code_table = {}

    for _, item in ipairs(data_section) do
        table.insert(code_table, "\x0F") -- SET antes de cada item do .data (pra ficar mais facil pra VM)
        table.insert(code_table, item)
    end

    for _, item in ipairs(code_section) do
        if type(item) == "string" then
            local opcode = char_map[item]  
            if opcode then
                table.insert(code_table, opcode)
            else
                table.insert(code_table, item)
            end
        else
            table.insert(code_table, item) 
        end
    end

    return code_table
end


function bytecode.generate(nodes)
    local data_section = {}
    local code_section = {}

    for _, node in ipairs(nodes) do
        node:generate_bytecode(code_section, data_section)
    end

    table.insert(code_section, bytecode.OPCODES.HALT)

    local readable_data = {}
    for _, item in ipairs(data_section) do
        table.insert(readable_data, "SET") -- SET antes de cada item do .data (readable)
        table.insert(readable_data, item)
    end
    local readable = {data = readable_data, code = code_section}
    local compressed = compress(code_section, data_section)

    --[[
    print(".data")
    for _, item in ipairs(readable.data) do
        print(item)
    end

    print(".code")
    for _, item in ipairs(readable.code) do
        print(item)
    end]]

    return {readable = readable, bc = compressed}
end

function ast.Number:generate_bytecode(code_section, data_section)

end

function ast.String:generate_bytecode(code_section, data_section)

end

function ast.Var:generate_bytecode(code_section, data_section)

end

function ast.Identifier:generate_bytecode(code_section, data_section)

end

function ast.Binary:generate_bytecode(code_section, data_section)

end

function ast.Call:generate_bytecode(code_section, data_section)

end

function ast.Function:generate_bytecode(code_section, data_section)

end

function ast.Return:generate_bytecode(code_section, data_section)

end

return bytecode