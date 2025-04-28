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
    table.insert(code_section, bytecode.OPCODES.PUSH)
    table.insert(code_section, self.value)
end

function ast.String:generate_bytecode(code_section, data_section)
    table.insert(data_section, self.value)
    table.insert(code_section, bytecode.OPCODES.PUSH)
    table.insert(code_section, "data[" .. #data_section .. "]")
end

function ast.Var:generate_bytecode(code_section, data_section)
    self.value:generate_bytecode(code_section, data_section)
    table.insert(code_section, bytecode.OPCODES.STV)
    table.insert(code_section, self.name)
end

function ast.Identifier:generate_bytecode(code_section, data_section)
    table.insert(code_section, bytecode.OPCODES.LDV)
    table.insert(code_section, self.name)
end

function ast.Binary:generate_bytecode(code_section, data_section)
    self.left:generate_bytecode(code_section, data_section)
    self.right:generate_bytecode(code_section, data_section)

    if self.op == "+" then
        table.insert(code_section, bytecode.OPCODES.ADD)
    elseif self.op == "-" then
        table.insert(code_section, bytecode.OPCODES.SUB)
    elseif self.op == "*" then
        table.insert(code_section, bytecode.OPCODES.MUL)
    elseif self.op == "/" then
        table.insert(code_section, bytecode.OPCODES.DIV)
    end
end

function ast.Call:generate_bytecode(code_section, data_section)
    if self.callee == "println" then
        self.args[1]:generate_bytecode(code_section, data_section)
        table.insert(code_section, bytecode.OPCODES.PRINTLN)
    elseif self.callee == "print" then 
        self.args[1]:generate_bytecode(code_section, data_section)
        table.insert(code_section, bytecode.OPCODES.PRINT)
    elseif self.callee == "readln" then
        table.insert(code_section, bytecode.OPCODES.READLN)
    else
        for _, arg in ipairs(self.args) do
            arg:generate_bytecode(code_section, data_section)
        end
        table.insert(code_section, bytecode.OPCODES.CALL)
        table.insert(code_section, self.callee)
    end
end

function ast.Function:generate_bytecode(code_section, data_section)
    table.insert(code_section, bytecode.OPCODES.FUNC)
    table.insert(code_section, self.name)

    for _, param in ipairs(self.params) do
        table.insert(code_section, bytecode.OPCODES.STV)
        table.insert(code_section, param)
    end

    for _, stmt in ipairs(self.body) do
        stmt:generate_bytecode(code_section, data_section)
    end
end

function ast.Return:generate_bytecode(code_section, data_section)
    if self.value then
        self.value:generate_bytecode(code_section, data_section)
    end
    table.insert(code_section, bytecode.OPCODES.RET)
end

return bytecode