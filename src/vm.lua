local bytecode = 
{
    OPCODES = 
    {
        PUSH = 0,
        POP = 1,
        LDV = 2,
        STV = 3,
        PRINT = 4,
        PRINTLN = 5,
        ADD = 6,
        SUB = 7,
        MUL = 8,
        DIV = 9,
        HALT = 10,
        CALL = 11,
        FUNC = 12,
        RET = 13,
        SET = 14,
        READLN = 15,
    }
}
--[[
    No codegen, os opcodes são transformados em numeros e depois em um formato binário.
    o CHAR_MAP vai servir pra converter o binário de volta pra um número decimal correspondente nos OPCODES.
]]--
local CHAR_MAP = 
{ 
    ["\x01"] = 0,  
    ["\x02"] = 1,
    ["\x03"] = 2,
    ["\x04"] = 3,
    ["\x05"] = 4,
    ["\x06"] = 5,
    ["\x07"] = 6,
    ["\x08"] = 7,
    ["\x09"] = 8,
    ["\x0A"] = 9,
    ["\x0B"] = 10,
    ["\x0C"] = 11,
    ["\x0D"] = 12,
    ["\x0E"] = 13,
    ["\x0F"] = 14,
    ["\xA0"] = 15
}

local function decode(code)
    local decoded = {}
    if type(code) == "table" then -- Decodificar (decompress) a table de bytecode
        local last_opcode = nil
        for _, item in ipairs(code) do
            if type(item) == "string" then
                local opcode = CHAR_MAP[item]
                if opcode then
                    table.insert(decoded, opcode)
                    last_opcode = opcode
                else
                    local is_quoted = item:match('^".*"$') or item:match("^'.*'$")
                    local is_number = item:match("^%-?%d+$") or item:match("^%-?%d+%.%d+$")
    
                    if is_quoted then
                        table.insert(decoded, item:sub(2, -2))
                    elseif is_number then
                        table.insert(decoded, tonumber(item))
                    else
                        table.insert(decoded, item)
                    end
                end
            else
                table.insert(decoded, item)
            end
        end
    elseif type(code) == "string" then -- Mini lexer pra ler e decodificar o .nbc diretamente
        local i = 1
        local n = #code
        while i <= n do
            local byte = code:sub(i, i)
            local opcode = CHAR_MAP[byte]
    
            if opcode then
                local instruction = {opcode}
                i = i + 1
            
                while i <= n do
                    local next_byte = code:sub(i, i)
                    local next_opcode = CHAR_MAP[next_byte]
            
                    if next_opcode then
                        break
                    end
            
                    local next_item = next_byte
            
                    while i + 1 <= n do
                        local lookahead = code:sub(i + 1, i + 1)
                        local lookahead_opcode = CHAR_MAP[lookahead]
            
                        if lookahead_opcode then
                            break
                        end
            
                        next_item = next_item .. lookahead
                        i = i + 1
                    end
            
                    local is_quoted = next_item:match('^".*"$') or next_item:match("^'.*'$")
                    local is_number = next_item:match("^%-?%d+$") or next_item:match("^%-?%d+%.%d+$")
                    if is_quoted then
                        next_item = next_item:sub(2, -2) 
                    elseif is_number then
                        next_item = tonumber(next_item)
                    end
            
                    table.insert(instruction, next_item)
                    i = i + 1
                end
            
                for _, v in ipairs(instruction) do
                    table.insert(decoded, v)
                end            
            else
                table.insert(decoded, byte)
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

function VM:debug_print()
    if not self.debug then return end

    local opcodes_str = {
        [0] = "PUSH",
        [1] = "POP",
        [2] = "LDV",
        [3] = "STV",
        [4] = "PRINT",
        [5] = "PRINTLN",
        [6] = "ADD",
        [7] = "SUB",
        [8] = "MUL",
        [9] = "DIV",
        [10] = "HALT",
        [11] = "CALL",
        [12] = "FUNC",
        [13] = "RET",
        [14] = "READLN",
    }    

    local function format_table(t, open, close)
        local str = open
        for i, v in ipairs(t) do
            if type(v) == "number" then
                v = "\x1b[31;1m" .. v .. "\x1b[0m"
            else 
                v = "\x1b[32;1m\"" .. v .. "\"\x1b[0m"
            end
            str = str .. tostring(v)
            if i < #t then
                str = str .. ",\n\t "
            end
        end
        return str .. close
    end

    local function format_vars(vars)
        local parts = {}
        for k, v in pairs(vars) do
            if type(v) == "number" then
                v = "\x1b[31;1m" .. v .. "\x1b[0m"
            else 
                v = "\x1b[32;1m\"" .. v .. "\"\x1b[0m"
            end
            table.insert(parts, "\x1b[33;1m" .. tostring(k) .. "\x1b[0m" .. " = " .. tostring(v) ..  "\x1b[0m")
        end
        table.sort(parts) 
        return "{" .. table.concat(parts, ", ") .. "}"
    end

    print("\n--------------------------------------------")
    local val1 = (opcodes_str[self.code[self.pc]] or (self.code[self.pc] or "None")) 
    local val2 = (self.code[self.pc] or "None")
    if (val1 == val2) then
        print(string.format(" pc: %-2d │ current opcode: %s", self.pc, val1))
    else 
        print(string.format(" pc: %-2d │ current opcode: %s", self.pc, val1 .. " or " .. val2))
    end

    val1 = (opcodes_str[self.code[self.pc + 1]] or (self.code[self.pc + 1] or "None")) 
    val2 = (self.code[self.pc + 1] or "None")
    if (val1 == val2) then
        print(" next: ", val1)
    else 
        print(" next: ", val1 .. " or " .. val2)
    end
    print(" Stack: " .. format_table(self.stack, "[", "]"))
    print(" Vars:  " .. format_vars(self.vars))
    print(" Data:  " .. format_table(self.data, "[", "]"))
    print("--------------------------------------------")
end

--- Pega o próximo item no bytecode (um opcode ou qualquer outro valor), serve como um next_token
function VM:next_val()
   local v = self.code[self.pc]
   self.pc = self.pc + 1
   return v
end

function VM:run()
    local running = true 
    
    local handlers = 
    {
        [bytecode.OPCODES.SET] = function() -- Set um valor no .data
            local val = self:next_val()
            table.insert(self.data, val)
        end,

        [bytecode.OPCODES.PUSH] = function() -- Push um valor na stack (nem precisava doc but ok)
            local val = self:get_val(self:next_val())
            table.insert(self.stack, val)
        end,
        
        [bytecode.OPCODES.POP] = function()
            table.remove(self.stack)
        end,
        
        [bytecode.OPCODES.LDV] = function() -- Load o valor de uma variável na stack
            local varname = self:next_val()
            table.insert(self.stack, self.vars[varname] or 0)
        end,
        
        [bytecode.OPCODES.STV] = function() -- Store o último valor da stack em uma variável
            local varname = self:next_val()
            self.vars[varname] = table.remove(self.stack)
        end,
        
        [bytecode.OPCODES.PRINT] = function() -- Printar o último valor da stack (sem newline)
            local value = table.remove(self.stack)
            io.write(tostring(value))
        end,
        
        [bytecode.OPCODES.PRINTLN] = function() -- Printar o último valor da stack 
            local value = table.remove(self.stack)
            print(tostring(value))
        end,

        [bytecode.OPCODES.READLN] = function() -- Ler o input e guardar na stack
            local input = io.read("*l")
            table.insert(self.stack, input)
        end,
        
        
        [bytecode.OPCODES.ADD] = function()
            local b = table.remove(self.stack)
            local a = table.remove(self.stack)

            local na = tonumber(a)
            local nb = tonumber(b)
            if na and nb then
                table.insert(self.stack, na + nb)
            elseif type(a) == "string" and type(b) == "string" then
                table.insert(self.stack, a .. b)
            else
                error("só é possible somar nums ou strings né otonto")
            end
        end,
        
        [bytecode.OPCODES.SUB] = function()
            local b = table.remove(self.stack)
            local a = table.remove(self.stack)
            
            local na = tonumber(a)
            local nb = tonumber(b)
            if na and nb then
                table.insert(self.stack, na - nb)
            else
                error("só é possible subtrair nums né otonto")
            end
        end,
        
        [bytecode.OPCODES.MUL] = function()
            local b = table.remove(self.stack)
            local a = table.remove(self.stack)
            
            local na = tonumber(a)
            local nb = tonumber(b)
            if na and nb then
                table.insert(self.stack, na * nb)
            else
                error("só é possible multplicar nums né otonto")
            end
        end,
        
        [bytecode.OPCODES.DIV] = function()
            local b = table.remove(self.stack)
            local a = table.remove(self.stack)
            
            local na = tonumber(a)
            local nb = tonumber(b)
            if na and nb then
                if nb == 0 then
                    error("divisão por zero nananan")
                else
                    table.insert(self.stack, na / nb)
                end
            else
                error("só pode dividir números né otonto")
            end
        end,
        
        [bytecode.OPCODES.HALT] = function()
            running = false
        end,
        
        [bytecode.OPCODES.CALL] = function()
            local func_name = self:next_val()
            self:call_function(func_name)
        end,
        
        [bytecode.OPCODES.FUNC] = function()
            local func_name = self:next_val()
            self.functions[func_name] = self.pc
            
            local nesting = 0
            while self.pc <= #self.code do
                if self.code[self.pc] == bytecode.OPCODES.FUNC then
                    nesting = nesting + 1
                elseif self.code[self.pc] == bytecode.OPCODES.RET then
                    if nesting == 0 then break end
                    nesting = nesting - 1
                end
                self.pc = self.pc + 1
            end
            
            self.pc = self.pc + 1
        end,
        
        [bytecode.OPCODES.RET] = function()
            local return_value = nil
            if #self.stack > 0 then
                return_value = table.remove(self.stack)
            end
            
            if #self.call_stack > 0 then
                self.pc = table.remove(self.call_stack)
                if return_value ~= nil then
                    table.insert(self.stack, return_value)
                end
            else
                running = false
            end
        end
    }
    
    while running and self.pc <= #self.code do
        self:debug_print()
        
        local opcode = self:next_val()
        
        local handler = handlers[opcode]
        if handler then
            handler()
        else
            error("Opcode desconhecido: " .. tostring(opcode))
        end
    end
    
    return self.stack
end

function VM:set_debug(enabled)
    self.debug = enabled
end

return VM