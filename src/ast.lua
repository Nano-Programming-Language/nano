local ast = {}

local function define(kind, extra_methods)
    local class = {}
    class.__index = class

    function class.new(...)
        local fields = extra_methods.init and extra_methods.init(...) or {...}
        fields.kind = kind
        return setmetatable(fields, class)
    end

    function class:print(indent)
        indent = indent or 0
        local name = self.name or self.value or ""
        print(string.rep("  ", indent) .. kind .. (name ~= "" and " " .. tostring(name) or ""))
    end

    if extra_methods then
        for k, v in pairs(extra_methods) do
            if k ~= "init" then
                class[k] = v
            end
        end
    end

    ast[kind] = class
end

define("Var", {
    init = function(name, value) return { name = name, value = value } end,
    print = function(self, indent)
        indent = indent or 0
        print(string.rep("  ", indent) .. "Var " .. self.name)
        self.value:print(indent + 1)
    end
})


define("Number", {
    init = function(value) return { value = value } end
})

define("String", {
    init = function(value) return { value = value } end
})

define("Identifier", {
    init = function(name) return { name = name } end
})

define("Binary", {
    init = function(op, left, right) return { op = op, left = left, right = right } end,
    print = function(self, indent)
        indent = indent or 0
        print(string.rep("  ", indent) .. "Binary '" .. self.op .. "'")
        self.left:print(indent + 1)
        self.right:print(indent + 1)
    end
})

define("Call", {
    init = function(callee, args) return { callee = callee, args = args } end,
    print = function(self, indent)
        indent = indent or 0
        print(string.rep("  ", indent) .. "Call " .. self.callee)
        for _, arg in ipairs(self.args) do
            arg:print(indent + 1)
        end
    end
})

define("Function", {
    init = function(name, params, body) return { name = name, params = params, body = body } end,
    print = function(self, indent)
        indent = indent or 0
        print(string.rep("  ", indent) .. "Function " .. self.name)
        print(string.rep("  ", indent + 1) .. "Parameters: " .. table.concat(self.params, ", "))
        print(string.rep("  ", indent + 1) .. "Body:")
        for _, stmt in ipairs(self.body) do
            stmt:print(indent + 2)
        end
    end
})

define("Return", {
    init = function(value) return { value = value } end,
    print = function(self, indent)
        indent = indent or 0
        print(string.rep("  ", indent) .. "Return")
        if self.value and self.value.print then
            self.value:print(indent + 1)
        else
            print(string.rep("  ", indent + 1) .. tostring(self.value))
        end
    end
})

return ast
