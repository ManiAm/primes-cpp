#define CATCH_CONFIG_MAIN
#include <catch2/catch_all.hpp>

#include "calc.h"
#include <vector>

TEST_CASE("Add") {
    REQUIRE(add(2, 3) == 5);
    REQUIRE(add(-1, 1) == 0);
}

TEST_CASE("Prime") {
    REQUIRE(is_prime(1) == false);
    REQUIRE(is_prime(2) == true);
    REQUIRE(is_prime(17) == true);
    REQUIRE(is_prime(100) == false);
}

TEST_CASE("PrimesUpTo") {
    auto v = primes_up_to(10);
    std::vector<int> expected{2, 3, 5, 7};
    REQUIRE(v == expected);
}
