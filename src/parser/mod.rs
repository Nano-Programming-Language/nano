use crate::lexer::{TOT, Token};
use crate::ast::*; 

pub struct Parser
{
    tokens: Vec<Token>,
    index: usize,
    line: usize,
    column: usize,
}

impl Parser
{
    pub fn new(tokens: Vec<Token>) -> Self
    {
        Self
        {
            tokens,
            index: 0,
            line: 1,
            column: 1,
        }
    }

    fn is_at_end(&self) -> bool
    {
        self.index >= self.tokens.len()
    }

    fn peek(&self, offset: usize) -> Option<&Token>
    {
        self.tokens.get(self.index + offset)
    }

    fn next_token(&mut self) -> Option<Token>
    {
        let token = self.peek(0)?.clone();

        self.index += 1;

        if token.tot == TOT::NEWLINE
        {
            self.line += 1;
            self.column = 1;
        }
        else
        {
            self.column += token.value.len();
        }

        Some(token)
    }

    fn match_token(&mut self, tot: TOT, value: Option<&str>) -> Option<Token>
    {
        let token = self.peek(0)?.clone();

        if token.tot == tot && (value.is_none() || token.value == value.unwrap())
        {
            self.index += 1;
            Some(token.clone())
        }
        else
        {
            None
        }
    }

    fn expect(&mut self, tot: TOT, value: Option<&str>) -> Token
    {
        if let Some(token) = self.match_token(tot.clone(), value)
        {
            token
        }
        else
        {
            let found = self.peek(0).cloned().unwrap();

            panic!(
                "Expected {}{} at line {}, column {}, but found {}{}",
                tot.as_ref(),
                value.map_or(String::new(), |v| format!(" '{}'", v)),
                self.line,
                self.column,
                found.tot.as_ref(),
                found.value
            )
        }
    }

    fn consume_newlines(&mut self)
    {
        while self.match_token(TOT::NEWLINE, None).is_some() {}
    }

    pub fn parse(&mut self) -> Vec<Ast>
    {
        let mut statements = Vec::new();

        while !self.is_at_end()
        {
            self.consume_newlines();

            if !self.is_at_end()
            {
                statements.push(self.parse_statement());
            }
        }

        statements
    }

    fn parse_statement(&mut self) -> Ast
    {
        self.consume_newlines();

        let token = self.peek(0).cloned().unwrap();

        if token.tot == TOT::KEYWORD
        {
            match token.value.as_str()
            {
                "var" =>
                {
                    self.next_token();
                    self.parse_var_declaration()
                }
                "fn" =>
                {
                    self.next_token();
                    self.parse_function()
                }
                "return" =>
                {
                    self.next_token();
                    self.parse_return()
                }
                _ =>
                    panic!("Unknown keyword: {:?}", token.value),
            }
        }
        else
        {
            self.parse_expression()
        }
    }

    fn parse_var_declaration(&mut self) -> Ast
    {
        let name = self.expect(TOT::IDENTIFIER, None).value;
        self.expect(TOT::OPERATOR, Some("="));
        let expr = self.parse_expression();

        Ast::Var(Var
        {
            name,
            value: Box::new(expr),
        })
    }

    fn parse_function(&mut self) -> Ast
    {
        let name = self.expect(TOT::IDENTIFIER, None).value;
        self.expect(TOT::DELIMITER, Some("("));

        let mut params = Vec::new();

        if self.match_token(TOT::DELIMITER, Some(")")).is_none()
        {
            loop
            {
                params.push(self.expect(TOT::IDENTIFIER, None).value);

                if self.match_token(TOT::DELIMITER, Some(",")).is_none()
                {
                    break;
                }
            }

            self.expect(TOT::DELIMITER, Some(")"));
        }

        self.consume_newlines();
        self.expect(TOT::DELIMITER, Some("{"));

        let mut body = Vec::new();
        while !self.is_at_end() && self.match_token(TOT::DELIMITER, Some("}")).is_none()
        {
            self.consume_newlines();

            if self.is_at_end()
            {
                panic!("Unexpected end of file inside function body");
            }

            if let Some(token) = self.peek(0) 
            {
                if token.tot == TOT::DELIMITER && token.value == "}" 
                {
                    break;
                }
            }
            body.push(self.parse_statement());
        }

        if self.is_at_end()
        {
            panic!("Expected '}}' to close function body, but reached end of file");
        }

        self.expect(TOT::DELIMITER, Some("}"));

        Ast::Function(Function
        {
            name,
            params,
            body,
        })
    }

    fn parse_return(&mut self) -> Ast
    {
        self.consume_newlines();
        let expr = self.parse_expression();

        Ast::Return(Return
        {
            value: Some(Box::new(expr)),
        })
    }

    fn parse_expression(&mut self) -> Ast 
    {
        self.parse_addition()
    }
    
    fn parse_addition(&mut self) -> Ast 
    {
        let mut left = self.parse_multiplication();
        while let Some(token) = self.peek(0)
        {
            if token.tot == TOT::OPERATOR && (token.value == "+" || token.value == "-") 
            {
                let op = token.value.clone();
                self.next_token();
                let right = self.parse_multiplication();
                left = Ast::Binary(Binary 
                {
                    op,
                    left: Box::new(left),
                    right: Box::new(right),
                });
            } 
            else 
            {
                break;
            }
        }
        left
    }
    
    fn parse_multiplication(&mut self) -> Ast 
    {
        let mut left = self.parse_primary();
        while let Some(token) = self.peek(0) 
        {
            if token.tot == TOT::OPERATOR && (token.value == "*" || token.value == "/") 
            {
                let op = token.value.clone();
                self.next_token();
                let right = self.parse_primary();
                left = Ast::Binary(Binary {
                    op,
                    left: Box::new(left),
                    right: Box::new(right),
                });
            } 
            else 
            {
                break;
            }
        }
        left
    }    

    fn parse_grouping(&mut self) -> Ast
    {
        self.expect(TOT::DELIMITER, Some("("));
        let expr = self.parse_expression();
        self.expect(TOT::DELIMITER, Some(")"));
        expr
    }

    fn consume_comments(&mut self)
    {
        while matches!(self.peek(0), Some(Token { tot: TOT::COMMENT, .. })) 
        {
            self.next_token();
        }
    }

    fn parse_primary(&mut self) -> Ast
    {
        self.consume_comments();

        let token = self.peek(0).cloned().unwrap();

        match token.tot
        {
            TOT::NEWLINE =>
            {
                self.consume_newlines();
                self.parse_statement()
            }
            TOT::NUMBER =>
            {
                self.next_token();
                Ast::Number(Number
                {
                    value: token.value.parse().unwrap(),
                })
            }
            TOT::STRING =>
            {
                self.next_token();
                Ast::Str(Str
                {
                    value: token.value,
                })
            }
            TOT::IDENTIFIER =>
            {
                if let Some(peeked) = self.peek(1)
                {
                    if peeked.tot == TOT::DELIMITER && peeked.value == "("
                    {
                        return self.parse_function_call();
                    }
                }

                self.next_token();
                Ast::Identifier(Identifier
                {
                    name: token.value,
                })
            }
            TOT::DELIMITER if token.value == "(" =>
            {
                self.parse_grouping()
            }
            _ =>
                panic!("Unexpected token while parsing primary expression: {}, next token: {} ", token.value, self.peek(1).unwrap().value),
        }
    }

    fn parse_function_call(&mut self) -> Ast
    {
        let name = self.expect(TOT::IDENTIFIER, None).value;
        self.expect(TOT::DELIMITER, Some("("));

        let mut args = Vec::new();

        if self.match_token(TOT::DELIMITER, Some(")")).is_none()
        {
            loop
            {
                args.push(self.parse_expression());

                if self.match_token(TOT::DELIMITER, Some(",")).is_none()
                {
                    break;
                }
            }

            self.expect(TOT::DELIMITER, Some(")"));
        }

        Ast::Call(Call
        {
            callee: name,
            args,
        })
    }
}
