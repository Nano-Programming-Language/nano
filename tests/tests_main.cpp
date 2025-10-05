#include <optional>
#include <gtest/gtest.h>
#include "../src/lexer.hpp"


// EXAMPLE TEST. may not be actually good, since it can fail not only because of bad string scanning.
TEST(LexerText, WorkingStrings) {
      std::string in = "var x = \"hi\"";
      auto lexer = Lexer(in);
      EXPECT_EQ(lexer.tokenize(), std::nullopt) << "Unable to tokenize strings properly";
}