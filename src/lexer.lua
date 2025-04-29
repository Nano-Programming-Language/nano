local lexer = {}
lexer.__index = lexer

local operators = 
{
    ["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true,
    ["="] = true, ["+="] = true, ["-="] = true, ["*="] = true,
    ["/="] = true, ["=="] = true
}

local delimiters = 
{
    ["("] = true, [")"] = true,
    ["{"] = true, ["}"] = true,
    ["."] = true, [","] = true,
    [";"] = true
}

local keywords = 
{
    ["if"] = true, ["else"] = true, ["elseif"] = true,
    ["var"] = true, ["const"] = true, ["fn"] = true,
    ["return"] = true, ["for"] = true, ["in"] = true,
    ["while"] = true, ["once"] = true,
    ["true"] = true, ["false"] = true
}

function lexer.new(source)
    return setmetatable({
        src = source,
        index = 1,
        line = 1,
        column = 1
    }, lexer)
end

function lexer:is_eof()
    return self.index > #self.src
end

function lexer:peek(offset)
    offset = offset or 0
    return self.src:sub(self.index + offset, self.index + offset)
end

function lexer:next_char()
    local char = self.src:sub(self.index, self.index)
    if char == "\n" then
        self.line = self.line + 1
        self.column = 1
    else
        self.column = self.column + 1
    end
    self.index = self.index + 1
    return char
end

function lexer:expect(expected)
    local actual = self:peek()
    if actual ~= expected then
        error(("Expected '%s' but found '%s' at line %d, column %d")
            :format(expected, actual, self.line, self.column))
    end
    self:next_char()
end

function lexer:tokenize()
    local tokens = {}

    while not self:is_eof() do
        local char = self:peek()

        if char:match("%s") then
            if char == "\n" then
                self:next_char()
                table.insert(tokens, { type = "newline", value = "\n" })
            else
                self:next_char()
            end

        elseif char:match("%d") then
            table.insert(tokens, self:read_number())

        elseif char:match("[%a_]") then
            table.insert(tokens, self:read_identifier_or_keyword())

        elseif delimiters[char] then
            table.insert(tokens, self:read_delimiter())

        elseif char == '"' then
            table.insert(tokens, self:read_string())

        elseif char == "/" then
            local comment = self:read_comments()
            if comment then
                table.insert(tokens, comment)
            end
        else
            table.insert(tokens, self:read_operator_or_error())
        end
    end

    return tokens
end

function lexer:read_number()
    local start = self.index
    while self:peek():match("%d") do
        self:next_char()
    end
    local value = tonumber(self.src:sub(start, self.index - 1))
    return { type = "number", value = value }
end

function lexer:read_identifier_or_keyword()
    local start = self.index
    while self:peek():match("[%w_]") do
        self:next_char()
    end
    local value = self.src:sub(start, self.index - 1)
    if keywords[value] then
        return { type = "keyword", value = value }
    else
        return { type = "identifier", value = value }
    end
end

function lexer:read_delimiter()
    local char = self:next_char()
    return { type = "delimiter", value = char }
end

function lexer:read_string()
    self:next_char() 
    local str = ""
    while not self:is_eof() and self:peek() ~= '"' do
        str = str .. self:next_char()
    end
    if self:is_eof() then
        error(("Unterminated string at line %d, column %d"):format(self.line, self.column))
    end
    self:expect('"')
    return { type = "string", value = str }
end

function lexer:read_operator_or_error()
    local first = self:peek()
    local second = self:peek(1)
    local combined = first .. second

    if operators[combined] then
        self:next_char()
        self:next_char()
        return { type = "operator", value = combined }
    elseif operators[first] then
        self:next_char()
        return { type = "operator", value = first }
    else
        error(("Unknown character '%s' at line %d, column %d")
            :format(first, self.line, self.column))
    end
end

function lexer:read_comments()
    local next = self:peek(1)

    if next == "/" then
        self:next_char() 
        self:next_char() 
        local comment = ""
        while not self:is_eof() and self:peek() ~= '\n' do
            comment = comment .. self:next_char()
        end
        return { type = "comment", value = comment }

    elseif next == "*" then
        self:next_char() 
        self:next_char() 
        local comment = ""
        while not self:is_eof() and not (self:peek() == "*" and self:peek(1) == "/") do
            comment = comment .. self:next_char()
        end
        if self:is_eof() then
            error(("Unterminated comment at line %d, column %d"):format(self.line, self.column))
        end
        self:next_char() 
        self:next_char() 
        return { type = "comment", value = comment }

    else
        return { type = "operator", value = "/" }
    end
end


return lexer
