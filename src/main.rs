use nano::{
    lexer::Lexer,
    parser::Parser,
    ast::AstNode,
};
use std::fs;
use std::io::Read;
use std::env;

fn main() 
{
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let mut file = fs::File::open(filename).expect("Unable to open file");
    let mut contents = String::new();
    file.read_to_string(&mut contents).expect("Unable to read file");
    let mut lexer = Lexer::new(contents);
    let tokens = lexer.tokenize();
    for token in &tokens 
    {
        println!("{}", format!("{} : {}", token.value, token.tot.as_ref()))
    }
    let mut parser = Parser::new(tokens.clone());
    let ast = parser.parse();
    for node in &ast 
    {
        node.print(0);
    }
    drop(ast);
}   
