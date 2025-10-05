#include <algorithm>
#include <array>
#include <cctype>
#include <string>
#include <string_view>
#include <vector>

export module lexer;

export constexpr std::array<std::string_view, 24> keywords = {
        "fn",       "return", "var",   "const",   "enum", "struct", "class", "dyn",
        "while",    "true",   "false", "for",     "if",   "elseif", "else",  "break",
        "continue", "switch", "case",  "default", "null", "import", "asm",   "comptime",
};

export enum class TypeOfToken {
      IDENTIFIER,
      KEYWORD,
      NUMBER,
      STRING,
      CHAR,
      NEWLINE,
      OP_PLUS,
      OP_PLUSEQUALS,
      OP_INC,
      OP_MINUS,
      OP_MINUSEQUALS,
      OP_DEC,
      OP_TIMES,
      OP_TIMESEQUALS,
      OP_DIV,
      OP_DIVEQUALS,
      OP_EQUALS,
      OP_EQUALSEQUALS,
      OP_AMPERSAND,
      OP_DOUBLEAMPERSAND,
      OP_EXCL_MARK,
      OP_EXCL_EQUALS,
      OP_PIPE,
      OP_DOUBLEPIPE,
      COMMA,
      PERIOD,
      COLON,
      DOUBLECOLON,
      SEMICOLON,
      GTHAN,
      GTHAN_EQUALS,
      LTHAN,
      LTHAN_EQUALS,
      RPAREN,
      LPAREN,
      RBRACKET,
      LBRACKET,
      RBRACE,
      LBRACE,
      COMMENT,
      T_EOF
};

export struct Token {
      TypeOfToken type;
      std::string_view val;
      unsigned int line;
      unsigned int column;

      explicit constexpr Token(TypeOfToken t = TypeOfToken::IDENTIFIER, std::string_view v = "", unsigned int l = 0,
                               unsigned int c = 0) : type(t), val(v), line(l), column(c) {}
};

export class Lexer {
      std::string_view source;
      size_t index = 0;
      size_t line = 1;
      size_t column = 1;

  public:
      explicit Lexer(std::string_view src) : source(src) {}

      char next_char() {
            if (index >= source.size())
                  return '\0';
            char c = source[index];
            index++;
            if (c == '\n') {
                  line++;
                  column = 1;
            } else {
                  column++;
            }
            return c;
      }

      [[nodiscard]] char peek_next() const {
            if (index >= source.size())
                  return '\0';
            return source[index];
      }

      std::vector<Token> tokenize() {
            std::vector<Token> tokens;
            while (index < source.size()) {
                  char c = next_char();
                  if (std::isspace(c)) {
                        continue;
                  } else if (c == '\n') {
                        tokens.emplace_back(TypeOfToken::NEWLINE, "[newline]", line, column);
                  } else if (std::isalpha(c) || c == '_') {
                        std::string identifier;
                        identifier.push_back(c);

                        while (std::isalnum(peek_next()) || peek_next() == '_') {
                              identifier.push_back(next_char());
                        }

                        if (std::ranges::find(keywords, identifier) != keywords.end()) {
                              tokens.emplace_back(TypeOfToken::KEYWORD, identifier, line, column);
                        } else {
                              tokens.emplace_back(TypeOfToken::IDENTIFIER, identifier, line, column);
                        }
                  } else if (std::isdigit(c)) {
                        std::string num;
                        num.push_back(c);

                        bool has_dot = false;

                        while (true) {
                              char next = peek_next();

                              if (std::isdigit(next)) {
                                    num.push_back(next);
                                    next_char();
                              } else if (next == '.' && !has_dot) {
                                    has_dot = true;
                                    num.push_back(next);
                                    next_char();
                              } else {
                                    break;
                              }
                        }

                        tokens.emplace_back(TypeOfToken::NUMBER, num, line, column);
                  } else if (c == '"') {
                        std::string str;

                        while (peek_next() != '"' && peek_next() != '\0') {
                              str.push_back(next_char());
                        }

                        if (peek_next() == '"') {
                              next_char();
                              tokens.emplace_back(TypeOfToken::STRING, str, line, column);
                        } else {
                              // TODO: error handling: Unterminated string
                        }
                  } else if (c == '/') {
                        char next = peek_next();

                        if (next == '/') {
                              next_char();
                              std::string comment;

                              while (peek_next() != '\n' && peek_next() != '\0') {
                                    comment.push_back(next_char());
                              }

                              tokens.emplace_back(TypeOfToken::COMMENT, comment, line, column);
                        } else if (next == '*') {
                              next_char();
                              std::string comment;
                              bool closed = false;

                              while (true) {
                                    char ch = next_char();
                                    if (ch == '\0') {
                                          break;
                                    }
                                    if (ch == '*' && peek_next() == '/') {
                                          next_char();
                                          closed = true;
                                          break;
                                    }
                                    comment.push_back(ch);
                              }

                              tokens.emplace_back(TypeOfToken::COMMENT, comment, line, column);

                              if (!closed) {
                                    // TODO: error handling: Unclosed comment
                              }
                        } else {
                              tokens.emplace_back(TypeOfToken::OP_DIV, "/", line, column);
                        }
                  } else if (c == '\'') {
                        std::string str;

                        char ch = '\0';
                        next_char();

                        if (peek_next() == '\\') {
                              next_char();
                              char esc = next_char();
                              switch (esc) {
                                    case 'n':
                                          ch = '\n';
                                          break;
                                    case 't':
                                          ch = '\t';
                                          break;
                                    case '\\':
                                          ch = '\\';
                                          break;
                                    case '\'':
                                          ch = '\'';
                                          break;
                                    case '"':
                                          ch = '"';
                                          break;
                                    default:
                                          // TODO: error handling: Unknown escape sequence
                                          break;
                              }
                        } else {
                              ch = next_char();
                        }

                        if (peek_next() == '\'') {
                              next_char();
                              tokens.emplace_back(TypeOfToken::CHAR, std::string(1, ch), line, column);
                        } else {
                              // TODO: error handling: Unterminated char
                        }
                  } else {
                        TypeOfToken type;
                        std::string op(1, c);
                        char next = peek_next();

                        switch (c) {
                              case '+':
                                    if (next == '+') {
                                          next_char();
                                          type = TypeOfToken::OP_INC;
                                          op = "++";
                                    } else if (next == '=') {
                                          next_char();
                                          type = TypeOfToken::OP_PLUSEQUALS;
                                          op = "+=";
                                    } else {
                                          type = TypeOfToken::OP_PLUS;
                                    }
                                    break;
                              case '-':
                                    if (next == '-') {
                                          next_char();
                                          type = TypeOfToken::OP_DEC;
                                          op = "--";
                                    } else if (next == '=') {
                                          next_char();
                                          type = TypeOfToken::OP_MINUSEQUALS;
                                          op = "-=";
                                    } else {
                                          type = TypeOfToken::OP_MINUS;
                                    }
                                    break;
                              case '*':
                                    if (next == '=') {
                                          next_char();
                                          type = TypeOfToken::OP_TIMESEQUALS;
                                          op = "*=";
                                    } else {
                                          type = TypeOfToken::OP_TIMES;
                                    }
                                    break;
                              case '=':
                                    if (next == '=') {
                                          next_char();
                                          type = TypeOfToken::OP_EQUALSEQUALS;
                                          op = "==";
                                    } else {
                                          type = TypeOfToken::OP_EQUALS;
                                    }
                                    break;
                              case '!':
                                    if (next == '=') {
                                          next_char();
                                          type = TypeOfToken::OP_EXCL_EQUALS;
                                          op = "!=";
                                    } else {
                                          type = TypeOfToken::OP_EXCL_MARK;
                                    }
                                    break;
                              case '&':
                                    if (next == '&') {
                                          next_char();
                                          type = TypeOfToken::OP_DOUBLEAMPERSAND;
                                          op = "&&";
                                    } else {
                                          type = TypeOfToken::OP_AMPERSAND;
                                    }
                                    break;
                              case '|':
                                    if (next == '|') {
                                          next_char();
                                          type = TypeOfToken::OP_DOUBLEPIPE;
                                          op = "||";
                                    } else {
                                          type = TypeOfToken::OP_PIPE;
                                    }
                                    break;
                              case '>':
                                    if (next == '=') {
                                          next_char();
                                          type = TypeOfToken::GTHAN_EQUALS;
                                          op = ">=";
                                    } else {
                                          type = TypeOfToken::GTHAN;
                                    }
                                    break;
                              case '<':
                                    if (next == '=') {
                                          next_char();
                                          type = TypeOfToken::LTHAN_EQUALS;
                                          op = "<=";
                                    } else {
                                          type = TypeOfToken::LTHAN;
                                    }
                                    break;
                              case ':':
                                    if (next == ':') {
                                          next_char();
                                          type = TypeOfToken::DOUBLECOLON;
                                          op = "::";
                                    } else {
                                          type = TypeOfToken::COLON;
                                    }
                                    break;
                              case ';':
                                    type = TypeOfToken::SEMICOLON;
                                    break;
                              case ',':
                                    type = TypeOfToken::COMMA;
                                    break;
                              case '.':
                                    type = TypeOfToken::PERIOD;
                                    break;
                              case '(':
                                    type = TypeOfToken::LPAREN;
                                    break;
                              case ')':
                                    type = TypeOfToken::RPAREN;
                                    break;
                              case '[':
                                    type = TypeOfToken::LBRACKET;
                                    break;
                              case ']':
                                    type = TypeOfToken::RBRACKET;
                                    break;
                              case '{':
                                    type = TypeOfToken::LBRACE;
                                    break;
                              case '}':
                                    type = TypeOfToken::RBRACE;
                                    break;
                              default:
                                    // TODO: error handling: Unknown character
                                    continue;
                        }

                        tokens.emplace_back(type, op, line, column);
                  }
            }
            return tokens;
      }
};
