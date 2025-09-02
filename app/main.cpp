// Copyright 2025 Mani Amoozadeh

#include <iostream>
#include "src/calc.h"

int main() {
    std::cout << "2 + 3 = " << add(2, 3) << "\n";
    std::cout << "Is 17 prime? " << (is_prime(17) ? "yes" : "no") << "\n";
    return 0;
}
