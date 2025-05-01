local ffi = require "ffi"
local cutils = require "cutils"
local alloc = cutils.alloc
local free = cutils.free
ffi.cdef[[
    
]]

--[[
A single bytecode instruction is 32 bit wide and has an 
8 bit opcode field and several operand fields of 8 or 16 bit. 

Instructions come in one of two formats:

B	C	A	OP
D
A	OP

Source: (https://web.archive.org/web/20190204110223/)http://wiki.luajit.org/Bytecode-2.0
]]

local bytecode = 
{
    OPCODES = 
    {
        RSETL = "RSETL", -- Set register A to literal D
        RSETV = "RSETV", -- Set register A to register D 
        FUNC = "FUNC", -- Sets proto D to register A
        CALL = "CALL", -- Calls function pointed by register A with arguments B..C
        RETURN = "RETURN", -- Returns registers A..D

    }
}

local CHAR_MAP = 
{ 

}

local function decode(code)
    local decoded = {}
    local ctype = type(code)
    local len = 0
    if ctype == "table" then -- Decodificar (decompress) a table de bytecode
        for _, item in ipairs(code) do
            len = len + 1
            if type(item) == "string" then
                local opcode = CHAR_MAP[item]
                decoded[len] = opcode or item
            else
                decoded[len] = item
            end
        end
    elseif ctype == "string" then -- Mini lexer pra ler e decodificar o .nbc diretamente
        local i = 1
        local n = #code
        while i <= n do
            local byte = code:sub(i, i)
            local opcode = CHAR_MAP[byte]
    
            if opcode then
                local instruction = {opcode}
                local ilen = #instruction
                i = i + 1
    
                while i <= n do
                    local next_byte = code:sub(i, i)
                    local next_opcode = CHAR_MAP[next_byte]

                    if next_opcode then
                        break
                    end
                    local next_item = next_byte
    
                    while i + 1 <= n do
                        local next_byte = code:sub(i + 1, i + 1)
                        local next_opcode = CHAR_MAP[next_byte]
    
                        if next_opcode then
                            break
                        end
    
                        next_item = next_item .. next_byte
                        i = i + 1
                    end
                    ilen = ilen + 1
                    instruction[ilen] = next_item
                    i = i + 1
                end

                len = len + 1
                decoded[len] = instruction[1]
                len = len + 1
                decoded[len] = instruction[2]
            else
                len = len + 1
                decoded[len] = byte
                i = i + 1
            end
        end
    end
    return decoded
end

local VM = {}
VM.__index = VM

function VM.new(code)
    local vm = setmetatable({}, VM)
    vm.code = decode(code)
    vm.data = {}
    vm.stack = {}
    vm.vars = {}
    vm.pc = 1
    vm.call_stack = {}
    vm.functions = {}
    vm.debug = false
    return vm
end

function VM:get_val(index) -- checar se o valor index é um data[num] (e pegar o valor correspondente no .data)
    if type(index) == "string" then
        local num = tonumber(index:match("data%[(%d+)%]"))
        if num and num >= 1 and num <= #self.data then
            return self.data[num]
        end
    end
    return index
end

function VM:call_function(func_name)
    local func_pc = self.functions[func_name]
    if not func_pc then
        error("function '" .. tostring(func_name) .. "' not found.")
    end
    table.insert(self.call_stack, self.pc)
    self.pc = func_pc
end

function VM:debug_print() -- debugs
    if not self.debug then return end
    
    print("\npc: " .. self.pc .. 
          ", current opcode: " .. tostring(self.code[self.pc]) .. 
          ", nexto opcode: " .. tostring(self.code[self.pc + 1] or "none"))
    
    io.write("stack: [")
    for i, item in ipairs(self.stack) do
        io.write(tostring(item))
        if i < #self.stack then io.write(", ") end
    end
    print("]")
    
    io.write("vars: {")
    local vars = {}
    for k, v in pairs(self.vars) do
        table.insert(vars, k)
    end
    
    for i, k in ipairs(vars) do
        io.write(tostring(k) .. "=" .. tostring(self.vars[k]))
        if i < #vars then io.write(", ") end
    end
    print("}")

    io.write("data: [")
    for i, item in ipairs(self.data) do
        io.write(tostring(item))
        if i < #self.data then io.write(", ") end
    end 
    print("]")
end

--- Pega o próximo item no bytecode (um opcode ou qualquer outro valor), serve como um next_token
function VM:next_val()
   local v = self.code[self.pc]
   self.pc = self.pc + 1
   return v
end



return VM