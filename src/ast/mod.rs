pub trait AstNode
{
    fn print(&self, indent: usize);
}

fn indent_str(indent: usize) -> String
{
    "  ".repeat(indent)
}

#[derive(Debug)]
pub struct Var
{
    pub name: String,
    pub value: Box<Ast>,
}

impl AstNode for Var
{
    fn print(&self, indent: usize)
    {
        println!("{}Var {}", indent_str(indent), self.name);
        self.value.print(indent + 1);
    }
}

#[derive(Debug)]
pub struct Number
{
    pub value: f64,
}

impl AstNode for Number
{
    fn print(&self, indent: usize)
    {
        println!("{}Number {}", indent_str(indent), self.value);
    }
}

#[derive(Debug)]
pub struct Str
{
    pub value: String,
}

impl AstNode for Str
{
    fn print(&self, indent: usize)
    {
        println!("{}String \"{}\"", indent_str(indent), self.value);
    }
}

#[derive(Debug)]
pub struct Identifier
{
    pub name: String,
}

impl AstNode for Identifier
{
    fn print(&self, indent: usize)
    {
        println!("{}Identifier {}", indent_str(indent), self.name);
    }
}

#[derive(Debug)]
pub struct Binary
{
    pub op: String,
    pub left: Box<Ast>,
    pub right: Box<Ast>,
}

impl AstNode for Binary
{
    fn print(&self, indent: usize)
    {
        println!("{}Binary '{}'", indent_str(indent), self.op);
        self.left.print(indent + 1);
        self.right.print(indent + 1);
    }
}

#[derive(Debug)]
pub struct Call
{
    pub callee: String,
    pub args: Vec<Ast>,
}

impl AstNode for Call
{
    fn print(&self, indent: usize)
    {
        println!("{}Call {}", indent_str(indent), self.callee);
        for arg in &self.args
        {
            arg.print(indent + 1);
        }
    }
}

#[derive(Debug)]
pub struct Function
{
    pub name: String,
    pub params: Vec<String>,
    pub body: Vec<Ast>,
}

impl AstNode for Function
{
    fn print(&self, indent: usize)
    {
        println!("{}Function {}", indent_str(indent), self.name);
        println!("{}Parameters: {}", indent_str(indent + 1), self.params.join(", "));
        println!("{}Body:", indent_str(indent + 1));
        for stmt in &self.body
        {
            stmt.print(indent + 2);
        }
    }
}

#[derive(Debug)]
pub struct Return
{
    pub value: Option<Box<Ast>>,
}

impl AstNode for Return
{
    fn print(&self, indent: usize)
    {
        println!("{}Return", indent_str(indent));
        if let Some(val) = &self.value
        {
            val.print(indent + 1);
        }
    }
}

#[derive(Debug)]
pub enum Ast
{
    Var(Var),
    Number(Number),
    Str(Str),
    Identifier(Identifier),
    Binary(Binary),
    Call(Call),
    Function(Function),
    Return(Return),
}

impl AstNode for Ast
{
    fn print(&self, indent: usize)
    {
        match self
        {
            Ast::Var(v) => v.print(indent),
            Ast::Number(n) => n.print(indent),
            Ast::Str(s) => s.print(indent),
            Ast::Identifier(i) => i.print(indent),
            Ast::Binary(b) => b.print(indent),
            Ast::Call(c) => c.print(indent),
            Ast::Function(f) => f.print(indent),
            Ast::Return(r) => r.print(indent),
        }
    }
}