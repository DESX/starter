#include <iostream>
#include "fmt/format.h"
#include <catch2/catch_test_macros.hpp>

using namespace std;

TEST_CASE("aix buffer test","")
{
    SECTION("Basic IO")
    {
        fmt::print("hello\n");
        REQUIRE(1==1);
    }
}
