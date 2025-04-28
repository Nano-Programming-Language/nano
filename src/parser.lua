local ast = require "src.ast"

local parser = {}
parser.__index = parser

function parser.new(tokens)
    return setmetatable(
    {
        tokens = tokens,
        index = 1,
        line = 1,
        column = 1,
    }, parser)
end

-- Helpers

function parser:is_at_end()
    return self.index > #self.tokens
end

function parser:peek(offset)
    offset = offset or 0
    return self.tokens[self.index + offset]
end

function parser:next_token()
    local token = self:peek()
    if token then
        self.index = self.index + 1
        if token.type == "newline" then
            self.line = self.line + 1
            self.column = 1
        else
            self.column = self.column + #(tostring(token.value) or "")
        end
    end
    return token
end

function parser:match(type, value)
    local token = self:peek()
    if token and token.type == type and (not value or token.value == value) then
        self.index = self.index + 1
        return token
    end
end

function parser:expect(type, value)
    local token = self:match(type, value)
    if not token then
        local found = self:peek() or {}
        error(("Expected %s%s at line %s, column %s, but found %s%s")
            :format(
                type,
                value and (" '" .. value .. "'") or "",
                found.line or "?",
                found.column or "?",
                found.type or "EOF",
                found.value and (" '" .. tostring(found.value) .. "'") or ""
            )
        )
    end
    return token
end

function parser:consume_newlines()
    while self:match("newline") do end
end

-- Parsing

function parser:parse()
    local statements = {}

    while not self:is_at_end() do
        self:consume_newlines()
        if not self:is_at_end() then
            statements[#statements + 1] = self:parse_statement()
        end
    end

    return statements
end

function parser:parse_statement()
    self:consume_newlines() 

    local token = self:peek()
    if not token then
        error("Unexpected end of input while parsing statement")
    end

    if token.type == "keyword" then
        if token.value == "var" then
            self:next_token()
            return self:parse_var_declaration()
        elseif token.value == "fn" then
            self:next_token()
            return self:parse_function()
        elseif token.value == "return" then
            self:next_token()
            return self:parse_return()
        else
            error("Unknown keyword: " .. token.value)
        end
    else
        return self:parse_expression()
    end
end

function parser:parse_var_declaration()
    local name = self:expect("identifier").value
    self:expect("operator", "=")
    local expr = self:parse_expression()
    return ast.Var.new(name, expr)
end

function parser:parse_function()
    local name = self:expect("identifier").value
    self:expect("delimiter", "(")

    local args = {}
    if not self:match("delimiter", ")") then
        repeat
            args[#args + 1] = self:expect("identifier").value
        until not self:match("delimiter", ",")
        self:expect("delimiter", ")")
    end

    self:consume_newlines() 

    self:expect("delimiter", "{")

    local body = {}
    while not self:match("delimiter", "}") do
        self:consume_newlines()
        if self:is_at_end() then
            error("Unexpected end of file inside function body")
        end
        body[#body + 1] = self:parse_statement()
    end

    return ast.Function.new(name, args, body)
end

function parser:parse_return()
    self:consume_newlines() 
    local expr = self:parse_expression()
    return ast.Return.new(expr)
end

function parser:parse_expression()
    return self:parse_binary()
end

function parser:parse_binary()
    local left = self:parse_primary()

    while true do
        local token = self:peek()
        if token and token.type == "operator" and (token.value == "+" or token.value == "-" or token.value == "*" or token.value == "/") then
            self:next_token()
            local right = self:parse_primary()
            left = ast.Binary.new(token.value, left, right)
        else
            break
        end
    end

    return left
end

function parser:parse_primary()
    self:consume_newlines()

    local token = self:peek()
    if not token then
        error("Unexpected end of input while parsing primary expression")
    end

    if token.type == "number" then
        self:next_token()
        return ast.Number.new(token.value)

    elseif token.type == "string" then
        self:next_token()
        return ast.String.new(token.value)

    elseif token.type == "identifier" then
        if self:peek(1) and self:peek(1).type == "delimiter" and self:peek(1).value == "(" then
            return self:parse_function_call()
        else
            self:next_token()
            return ast.Identifier.new(token.value)
        end
    end
end

function parser:parse_function_call()
    local name = self:expect("identifier").value
    self:expect("delimiter", "(")

    local args = {}
    if not self:match("delimiter", ")") then
        repeat
            args[#args + 1] = self:parse_expression()
        until not self:match("delimiter", ",")
        self:expect("delimiter", ")")
    end

    return ast.Call.new(name, args)
end

return parser