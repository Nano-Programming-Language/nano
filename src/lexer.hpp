#pragma once
#include <algorithm>
#include <array>
#include <cctype>
#include <optional>
#include <string_view>
#include <utility>
#include <vector>
// for some weird reason, including string before a few other headers causes the clion lsp (and maybe the compiler)
// to think std::string doesn't exist
#include <string>

constexpr std::array<std::string_view, 24> keywords = {
        "fn",       "return", "var",   "const",   "enum", "struct", "class", "dyn",
        "while",    "true",   "false", "for",     "if",   "elseif", "else",  "break",
        "continue", "switch", "case",  "default", "null", "import", "asm",   "comptime",
};

enum class LexerError {
      unterminated_string,
      unterminated_character,
      unknown_character,
      unclosed_comment,
      unknown_escape_sequence,
};

// TODO: make all variants lower-cased, enum classes don't require them to be upper-cased.
enum class TypeOfToken {
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

struct Token {
      const TypeOfToken type;
      const std::string_view val;
      const size_t line;
      const size_t column;

      explicit constexpr Token(const TypeOfToken t = TypeOfToken::IDENTIFIER, const std::string_view v = "",
                               const size_t l = 0, const size_t c = 0) : type(t), val(v), line(l), column(c) {}
};

class Lexer {
      // to avoid a dangling pointer, std::string is used and we move it
      const std::string m_source;
      size_t m_index = 0;
      size_t m_line = 1;
      size_t m_column = 1;

  public:
      std::vector<Token> tokens;

      explicit Lexer(std::string& src) : m_source(std::move(src)) {}

      char next_char() {
            if (m_index >= m_source.size())
                  return '\0';
            char c = m_source[m_index];
            m_index++;
            if (c == '\n') {
                  m_line++;
                  m_column = 1;
            } else {
                  m_column++;
            }
            return c;
      }

      [[nodiscard]] char peek_next() const {
            if (m_index >= m_source.size())
                  return '\0';
            return m_source[m_index];
      }

      std::optional<LexerError> tokenize() {
            while (m_index < m_source.size()) {
                  const char c = next_char();
                  if (std::isspace(c)) {
                        continue;
                  } else if (c == '\n') {
                        tokens.emplace_back(TypeOfToken::NEWLINE, "[newline]", m_line, m_column);
                  } else if (std::isalpha(c) || c == '_') {
                        std::string identifier;
                        identifier.push_back(c);

                        while (std::isalnum(peek_next()) || peek_next() == '_') {
                              identifier.push_back(next_char());
                        }

                        if (std::ranges::find(keywords, identifier) != keywords.end()) {
                              tokens.emplace_back(TypeOfToken::KEYWORD, identifier, m_line, m_column);
                        } else {
                              tokens.emplace_back(TypeOfToken::IDENTIFIER, identifier, m_line, m_column);
                        }
                  } else if (std::isdigit(c)) {
                        std::string num;
                        num.push_back(c);

                        bool has_dot = false;

                        while (true) {
                              const char next = peek_next();

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

                        tokens.emplace_back(TypeOfToken::NUMBER, num, m_line, m_column);
                  } else if (c == '"') {
                        std::string str;

                        while (peek_next() != '"' && peek_next() != '\0') {
                              str.push_back(next_char());
                        }

                        if (peek_next() == '"') {
                              next_char();
                              tokens.emplace_back(TypeOfToken::STRING, str, m_line, m_column);
                        } else {
                              return LexerError::unterminated_string;
                        }
                  } else if (c == '/') {
                        const char next = peek_next();

                        if (next == '/') {
                              next_char();
                              std::string comment;

                              while (peek_next() != '\n' && peek_next() != '\0') {
                                    comment.push_back(next_char());
                              }

                              tokens.emplace_back(TypeOfToken::COMMENT, comment, m_line, m_column);
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

                              tokens.emplace_back(TypeOfToken::COMMENT, comment, m_line, m_column);

                              if (!closed) {
                                    return LexerError::unclosed_comment;
                              }
                        } else {
                              tokens.emplace_back(TypeOfToken::OP_DIV, "/", m_line, m_column);
                        }
                  } else if (c == '\'') {
                        std::string str;

                        char ch = '\0';
                        next_char();

                        if (peek_next() == '\\') {
                              next_char();
                              switch (const char esc = next_char()) {
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
                                          return LexerError::unknown_escape_sequence;
                              }
                        } else {
                              ch = next_char();
                        }

                        if (peek_next() == '\'') {
                              next_char();
                              tokens.emplace_back(TypeOfToken::CHAR, std::string(1, ch), m_line, m_column);
                        } else {
                              return LexerError::unterminated_character;
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
                                    return LexerError::unknown_character;
                        }

                        tokens.emplace_back(type, op, m_line, m_column);
                  }
            }
            return std::nullopt;
      }
};
