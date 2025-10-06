#pragma once

#include <memory>
#include <string_view>
#include <unordered_map>
#include "./lexer.hpp"

enum class Type { INT, FLOAT, STRING, BOOL, NULL_T, UNKNOWN };

constexpr std::string_view type_to_str(Type t) {
      switch (t) {
            case Type::INT:
                  return "int";
            case Type::FLOAT:
                  return "float";
            case Type::STRING:
                  return "string";
            case Type::BOOL:
                  return "bool";
            case Type::NULL_T:
                  return "null";
            case Type::UNKNOWN:
                  return "unknown_type";
      }
}

class ASTNode {
  public:
      virtual ~ASTNode() = default;
      [[nodiscard]] constexpr virtual std::string_view display() const = 0;
      Type type = Type::UNKNOWN;
};

class NullNode : public ASTNode {
  public:
      Token token;

      explicit NullNode(Token token) : token(std::move(token)) { type = Type::NULL_T; }

      [[nodiscard]] constexpr std::string_view display() const override { return "null"; }
};

class NumberNode : public ASTNode {
  public:
      Token token;
      bool isNeg;
      std::string_view val;

      explicit NumberNode(Token& token, bool isNeg) : token(token), isNeg(isNeg), val(token.val) {
            type = token.val.find('.') == std::string_view::npos ? Type::INT : Type::FLOAT;
      }

      [[nodiscard]] constexpr std::string_view display() const override { return val; }
};

class BoolNode : public ASTNode {
  public:
      Token token;
      bool val;

      explicit BoolNode(Token& token, bool val) : token(std::move(token)), val(val) { type = Type::BOOL; }

      [[nodiscard]] constexpr std::string_view display() const override { return val ? "true" : "false"; }
};

class StringNode : public ASTNode {
  public:
      Token token;
      std::string_view val;

      explicit StringNode(Token& token) : token(token), val(token.val) { type = Type::STRING; }

      [[nodiscard]] constexpr std::string_view display() const override { return val; }
};

class BinaryOperation : public ASTNode {
  public:
      std::unique_ptr<ASTNode> left;
      std::unique_ptr<ASTNode> right;
      Token op;

  private:
      mutable std::string buffer;

  public:
      explicit BinaryOperation(std::unique_ptr<ASTNode> left, std::unique_ptr<ASTNode> right, Token op) :
          left(std::move(left)), right(std::move(right)), op(std::move(op)) {}

      [[nodiscard]] std::string_view display() const override {
            buffer = "(" + std::string(left->display()) + " " + std::string(op.val) + " " +
                     std::string(right->display()) + ")";
            return buffer;
      }
};

class UnaryOperation : public ASTNode {
  public:
      std::unique_ptr<ASTNode> node;
      Token op;

  private:
      mutable std::string buffer;

  public:
      explicit UnaryOperation(std::unique_ptr<ASTNode> n, Token o) : node(std::move(n)), op(std::move(o)) {
            if (node->type != Type::INT && node->type != Type::FLOAT) {
                  // TODO: error handling: Expected a number
            }
      }

      [[nodiscard]] std::string_view display() const override {
            buffer = std::string(op.val) + std::string(node->display());
            return buffer;
      }
};

class VariableNode : public ASTNode {
  public:
      const std::string_view name;
      std::unique_ptr<ASTNode> val;
      const Type type;

  private:
      mutable std::string buffer;

  public:
      explicit VariableNode(const std::string_view n, std::unique_ptr<ASTNode> v = nullptr,
                            const Type t = Type::UNKNOWN) : name(n), val(std::move(v)), type(t) {}

      [[nodiscard]] std::string_view display() const override {
            if (val) {
                  buffer = std::string(type_to_str(type)) + std::string(name) + " = " + std::string(val->display());
            } else {
                  buffer = std::string(type_to_str(type)) + std::string(name);
            }
            return buffer;
      }
};

class VariableCallNode : public ASTNode {
  public:
      std::string_view name;

  private:
      mutable std::string buffer;

  public:
      explicit VariableCallNode(const std::string_view n) : name(n) {}

      [[nodiscard]] constexpr std::string_view display() const override {
            buffer = std::string(name);
            return buffer;
      }
};

class PrototypeNode : public ASTNode {
  public:
      const std::string_view name;
      std::vector<VariableNode> args;
      const Type type;

  private:
      mutable std::string buffer;

  public:
      explicit PrototypeNode(const std::string_view name, std::vector<VariableNode>&& a, const Type t) :
          name(name), args(std::move(a)), type(t) {}

      [[nodiscard]] std::string_view display() const override {
            buffer = std::string(type_to_str(type)) + " function " + std::string(name) + "(";
            for (size_t i = 0; i < args.size(); i++) {
                  buffer += args[i].display();
                  if (i + 1 < args.size()) {
                        buffer += ", ";
                  }
            }
            buffer += ")";
            return buffer;
      }
};

class FunctionNode : public ASTNode {
  public:
      std::unique_ptr<PrototypeNode> Proto;
      std::vector<std::unique_ptr<ASTNode>> Body;
      Type type;

  private:
      mutable std::string buffer;

  public:
      explicit FunctionNode(std::unique_ptr<PrototypeNode> Proto, std::vector<std::unique_ptr<ASTNode>> Body) :
          Proto(std::move(Proto)), Body(std::move(Body)) {
            type = Proto->type;
      };

      [[nodiscard]] std::string_view display() const override {
            buffer = std::string(Proto->display()) + " :\n";
            for (size_t i = 0; i < Body.size(); i++) {
                  buffer += "\t" + std::string(Body[i]->display());
                  if (i + 1 < Body.size()) {
                        buffer += "\n";
                  }
            }
            return buffer;
      }
};

class CallNode : public ASTNode {
  public:
      std::string_view callee;
      std::vector<std::unique_ptr<ASTNode>> args;

  private:
      mutable std::string buffer;

  public:
      explicit CallNode(const std::string_view callee, std::vector<std::unique_ptr<ASTNode>> args) :
          callee(callee), args(std::move(args)) {}

      [[nodiscard]] std::string_view display() const override {
            buffer = std::string(callee) + "(";
            for (size_t i = 0; i < args.size(); i++) {
                  buffer += std::string(args[i]->display());
                  if (i + 1 < args.size()) {
                        buffer += ", ";
                  }
            }
            return buffer;
      }
};

class Scope {
  public:
      std::unordered_map<std::string_view, Type> variables;

      void declare_var(std::string_view name, Type t) {
            if (variables.contains(name)) {
                  // TODO: error handling: Already declared variable
            }
            variables[name] = t;
      }

      Type get_var(std::string_view name) const {
            auto it = variables.find(name);
            if (it == variables.end()) {
                  // TODO: error handling: Undeclared variable
            }
            return it->second;
      }
};

class Parser {
  public:
      std::vector<Token> tokens;
      size_t index;
      size_t column;
      size_t line;
      Scope current_scope;

      explicit Parser(std::vector<Token> tokns) : tokens(std::move(tokns)), index(0), column(1), line(1) {}

  private:
      Token next_token() {
            if (index < tokens.size()) {
                  Token token = tokens[index];
                  index++;
                  if (token.type == TypeOfToken::NEWLINE) {
                        column = 1;
                        line++;
                  } else {
                        column += token.val.length();
                  }
                  return token;
            }
            return Token{TypeOfToken::T_EOF, "\0", column, line};
      }

      Token peek_next() {
            if (index >= tokens.size())
                  return Token{TypeOfToken::T_EOF, "", column, line};
            return tokens[index];
      }

      ASTNode* parse_expr() {
            ASTNode* node = parse_term();
            while (peek_next().type == TypeOfToken::OP_PLUS || peek_next().type == TypeOfToken::OP_MINUS) {
                  Token token = next_token();
                  node = new BinaryOperation(std::unique_ptr<ASTNode>(node), std::unique_ptr<ASTNode>(parse_term()),
                                             token);
            }
            return node;
      }

      ASTNode* parse_term() {
            ASTNode* node = parse_factor();
            while (peek_next().type == TypeOfToken::OP_TIMES || peek_next().type == TypeOfToken::OP_DIV) {
                  Token token = next_token();
                  node = new BinaryOperation(std::unique_ptr<ASTNode>(node), std::unique_ptr<ASTNode>(parse_factor()),
                                             token);
            }
            return node;
      }

      ASTNode* parse_factor() {
            Token token = next_token();
            switch (token.type) {
                  case TypeOfToken::NUMBER:
                        return new NumberNode(token, false);
                  case TypeOfToken::STRING:
                        return new StringNode(token);
                  case TypeOfToken::IDENTIFIER: {
                        Type t = current_scope.get_var(token.val);
                        auto var = new VariableCallNode(token.val);
                        var->type = t;
                        return var;
                  }
                  case TypeOfToken::OP_MINUS:
                        return new UnaryOperation(std::unique_ptr<ASTNode>(parse_factor()), token);
                  case TypeOfToken::LPAREN: {
                        ASTNode* node = parse_expr();
                        Token close = next_token();
                        if (close.type != TypeOfToken::RPAREN)
                              // TODO: error handling: Expected ')'/Unclosed parent
                              return node;
                  }
                  case TypeOfToken::KEYWORD: {
                        std::string_view keyword = token.val;
                        if (keyword == "var") {
                              Token name = next_token();
                              Token eq = next_token();
                              if (eq.type != TypeOfToken::OP_EQUALS) {
                                    // TODO: error handling: Expected '='
                              }
                              auto val_node = std::unique_ptr<ASTNode>(parse_expr());
                              current_scope.declare_var(name.val, val_node->type);
                              return new VariableNode(name.val, std::move(val_node));
                        } else if (keyword == "null") {
                              return new NullNode(token);
                        }
                        break;
                  }
                  default:
                        // TODO: error handling: Unexpected <token>
            }
      }

  public:
      std::vector<std::unique_ptr<ASTNode>> parse() {
            std::vector<std::unique_ptr<ASTNode>> nodes;

            while (peek_next().type != TypeOfToken::T_EOF) {
                  auto node = std::unique_ptr<ASTNode>(parse_expr());
                  nodes.push_back(std::move(node));

                  if (peek_next().type == TypeOfToken::NEWLINE)
                        next_token();
            }

            return nodes;
      }
};
