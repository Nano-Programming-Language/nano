use std::collections::HashMap;
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Opcode 
{
    Push,
    Pop,
    Ldv,
    Stv,
    Print,
    Println,
    Readln,
    Add,
    Sub,
    Mul,
    Div,
    Halt,
    Call,
    Func,
    Ret,
    Set,
}

fn opcode_char_map() -> HashMap<Opcode, u8> 
{
    use crate::codegen::Opcode::*;
    HashMap::from([
        (Push, 0x01),
        (Pop, 0x02),
        (Ldv, 0x03),
        (Stv, 0x04),
        (Print, 0x05),
        (Println, 0x06),
        (Add, 0x07),
        (Sub, 0x08),
        (Mul, 0x09),
        (Div, 0x0A),
        (Halt, 0x0B),
        (Call, 0x0C),
        (Func, 0x0D),
        (Ret, 0x0E),
        (Readln, 0xA0),
        (Set, 0x0F),
    ])
}

#[derive(Debug, Clone)]
pub enum Instruction 
{
    Op(Opcode),
    OpWithArg(Opcode, String), 
    Data(String), 
}
