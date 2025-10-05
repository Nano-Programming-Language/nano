#pragma once
#include <optional>
#include <gtest/gtest.h>
#include "../../src/lexer.hpp"

TEST(LexerStrings, BasicString) {
      std::string in = "\"Hello, world!\"";
      auto lexer = Lexer(in);
      EXPECT_EQ(lexer.tokenize(), std::nullopt) << "Unable to tokenize basic strings properly.";
}

// For now will only test \n, \t, \r
TEST(LexerStrings, AnsiEscapeCode) {
      std::string in = "\\n\\t\\r";
      auto lexer = Lexer(in);
      std::optional<LexerError> result = lexer.tokenize();
      EXPECT_EQ(result, std::nullopt)
            << "Unable to even start tokenizing some/all common ANSI escape codes. Error code: "
            << std::to_string(static_cast<int>(result.value())) << ".";
      EXPECT_FALSE(lexer.tokens.empty()) << "\tNo tokens found.";
      const std::string_view& strval = lexer.tokens.at(0).val;
      EXPECT_EQ(strval.compare("\n\t\r"), 0) <<
            "Unable to properly interpret some/all common ANSI escape codes. String: "
            << strval << ".";
}

// mixed string would be like
// "hello'
// or 'hello"
TEST(LexerStrings, ErroringMixedString) {
      std::string in1 = "\"hello\'";
      std::string in2 = "\'hello\"";
      auto lexer1 = Lexer(in1);
      auto lexer2 = Lexer(in2);
      std::optional<LexerError> result1 = lexer1.tokenize();
      std::optional<LexerError> result2 = lexer2.tokenize();

      EXPECT_FALSE(result1.value() == LexerError::unterminated_string)
            << "Unable to properly error on a mixed string result1 value: "
            << (result1.has_value() ? "no error (nullopt)" : std::to_string(static_cast<int>(result1.value())))
            << ". Maybe try checking if different symbols were used to open and close the string.";
      EXPECT_FALSE(result2.value() == LexerError::unterminated_string)
              << "Unable to properly error on a mixed string. result2 value: "
              // what a mess
              << (result2.has_value() ? "no error (nullopt)" : std::to_string(static_cast<int>(result2.value())))
              << ". Maybe try checking if different symbols were used to open and close the string.";

      if (result1.has_value())
            EXPECT_TRUE(lexer1.tokens.empty()) << "lexer1 has tokens even though it errored.";
      if (result2.has_value())
            EXPECT_TRUE(lexer2.tokens.empty()) << "lexer2 has tokens even though it errored.";
      if (!lexer1.tokens.empty()) {
            const std::string_view& strval1 = lexer1.tokens.at(0).val;
            std::cout << "strval1 value: " << strval1 << ".";
      }
      if (!lexer1.tokens.empty()) {
            const std::string_view& strval2 = lexer2.tokens.at(0).val;
            std::cout << "strval2 value: " << strval2 << ".";
      }
}