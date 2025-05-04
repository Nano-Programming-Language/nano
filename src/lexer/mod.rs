use strum_macros::{EnumString, AsRefStr};
const OPERATORS: [&str; 10] = 
[
    "+" , "-" , "*" , "/" , "=",
    "+=", "-=", "*=", "/=", "=="
];

const DELIMITERS: [&str; 7] = 
[
    "(", ")", "{", "}", ".", ",",
    ";"
];

const KEYWORDS: [&str; 13] = 
[
    "if", "else", "elseif", "var", "const",
    "fn", "return", "for", "in", "while", "once",
    "true", "false"
];

#[derive(PartialEq, AsRefStr, EnumString, Clone)]
pub enum TOT 
{
    #[strum(serialize = "identifier")]
    IDENTIFIER,
    #[strum(serialize = "keyword")]
    KEYWORD,
    #[strum(serialize = "number")]
    NUMBER,
    #[strum(serialize = "string")]
    STRING,
    #[strum(serialize = "operator")]
    OPERATOR,
    #[strum(serialize = "delimiter")]
    DELIMITER,
    #[strum(serialize = "comment")]
    COMMENT,
    #[strum(serialize = "newline")]
    NEWLINE
}

#[derive(Clone)]
pub struct Token 
{
    pub value: String,
    pub tot: TOT
}

impl Token 
{
    pub fn new(value: String, tot: TOT) -> Self 
    {
        Token { value, tot }
    }
}

pub struct Lexer 
{
    src: String,
    index: usize,
    line: u32,
    column: u32
}

impl Lexer 
{
    pub fn new(src: String) -> Self
    {
        Lexer 
        {
            src: src,
            index: 0,
            line: 1,
            column: 1,
        }
    }

    fn is_eof(&self) -> bool 
    {
        self.index >= self.src.chars().count()
    }

    fn peek(&self, offset: usize) -> char 
    {
        self.src.chars().nth(self.index + offset).unwrap_or('\0')
    }

    fn next_char(&mut self) -> char 
    {
        let c = self.src.chars().nth(self.index).unwrap_or('\0');
        if c == '\n' 
        {
            self.line += 1;
            self.column = 1;
        }
        else 
        {
            self.column += 1;
        }
        self.index += 1;
        c
    }

    fn expect(&mut self, expected: char) 
    {
        let actual = self.peek(0);
        if actual != expected 
        {
            panic!("{}", format!(
                "Expected '{}' but found '{}' at line '{}', column '{}'.", 
                expected, actual, self.line, self.column
            ))
        }
        self.next_char();
    }

    pub fn tokenize(&mut self) -> Vec<Token>
    {
        let mut tokens = Vec::new();
        while !self.is_eof() 
        {
            let c = self.peek(0);
            if c.is_whitespace() 
            {
                if c == '\n' 
                {
                    self.next_char();
                    tokens.push(Token::new("[newline]".to_string(), TOT::NEWLINE));
                }
                else 
                {
                    self.next_char();    
                }
            }
            else if c.is_numeric() 
            {
                tokens.push(self.read_number())
            }
            else if c.is_alphanumeric() 
            {
                tokens.push(self.read_identifier_or_keyword())
            }
            else if DELIMITERS.contains(&c.to_string().as_str())
            {
                self.next_char();
                tokens.push(Token::new(c.to_string(), TOT::DELIMITER))
            }
            else if c == '"'
            {
                tokens.push(self.read_string())
            }
            else if c == '/'
            {
                tokens.push(self.read_comment())
            }
            else if OPERATORS.contains(&c.to_string().as_str())
            {
                tokens.push(self.read_operator());
            }
            else
            {
                panic!("{}", format!(
                    "Unknown character '{}' at line {}, column {}.",
                    c, self.line, self.column
                ))
            }
        }
        tokens
    }

    fn read_number(&mut self) -> Token 
    {
        let start = self.index;
        while self.peek(0).is_numeric() 
        {
            self.next_char();
        }
        let value = &self.src[start..self.index];
        Token::new(value.to_string(), TOT::NUMBER)
    }

    fn read_identifier_or_keyword(&mut self) -> Token 
    {
        let start = self.index;
        while self.peek(0).is_alphanumeric() 
        {
            self.next_char();
        }
        let value = &self.src[start..self.index];
        if KEYWORDS.contains(&value) 
        {
            Token::new(value.to_string(), TOT::KEYWORD)
        }
        else
        {
            Token::new(value.to_string(), TOT::IDENTIFIER)
        }
    }

    fn read_string(&mut self) -> Token 
    {
        self.next_char();
        let mut str = String::new();
        while !self.is_eof() && self.peek(0) != '"' 
        {
            str += self.next_char().to_string().as_str();
        }
        if self.is_eof() 
        {
            panic!("{}", format!(
                "Unterminated string at line {}, column {}",
                self.line, self.column
            ));
        }
        self.expect('"');
        Token::new(str, TOT::STRING)
    }

    fn read_operator(&mut self) -> Token 
    {
        let first = self.peek(0);
        let second = self.peek(1);
        let combined = first.to_string() + second.to_string().as_str();

        if OPERATORS.contains(&combined.as_str())
        {
            self.next_char();
            self.next_char();
            Token::new(combined, TOT::OPERATOR)
        }
        else if OPERATORS.contains(&first.to_string().as_str())
        {
            self.next_char();
            Token::new(first.to_string(), TOT::OPERATOR)
        }
        else 
        {
            panic!("{}", format!(
                "Unknown character '{}' at line {}, column {}.",
                first, self.line, self.column
            ))
        }
    }

    fn read_comment(&mut self) -> Token
    {
        let next = self.peek(1);

        if next == '/' 
        {
            self.next_char();
            self.next_char();
            let mut comment = String::new();
            while !self.is_eof() && self.peek(0) != '\n' 
            {
                comment += self.next_char().to_string().as_str();
            }
            Token::new(comment, TOT::COMMENT)
        }
        else if next == '*' 
        {
            self.next_char();
            self.next_char();
            let mut comment = String::new();
            while !self.is_eof() && !(self.peek(0) == '*' && self.peek(1) == '/') 
            {
                comment += self.next_char().to_string().as_str();
            }
            Token::new(comment, TOT::COMMENT)
        }
        else 
        {
            self.next_char();
            Token::new("/".to_string(), TOT::OPERATOR)    
        }
    }
}