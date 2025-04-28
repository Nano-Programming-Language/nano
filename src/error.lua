local error_types = 
{ --ta bom ta bom vou deixar do jeito "bonitinho"
    --auto explicativo
    parser_error = "Parse error",
    lexer_error = "Lexer error",
    codegen_error = "Codegen error",
    vm_error = "VM error",
    
    arithmetic_error = "Arithmetic error", -- divisão por 0, operandos incompatíveis etc
    constant_error = "Constant error", -- modificar constantes
    index_out_of_bounds = "Index out of bounds", -- acessar índices inválidos em arrays
    type_error = "Type error" -- tentar set um valor string pra uma variável int etc
}
local errors = {}

for k, v in pairs(error_types) do -- gera as funções do erro automaticamente baseado na table error_types
    errors[k] = function(msg, line, column, filename)
        error(
        ("%s: %s. Line %s, column %s, file %s."):format(
                v,
                msg,
                line or "?",
                column or "?",
                filename or "?"
            )
        )
    end
end

return errors