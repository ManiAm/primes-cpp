
#include "calc.h"
#include <cmath>
#include <vector>

int add(int a, int b) { return a + b; }

bool is_prime(int n) {
    if (n < 2)
        return false;
    if (n % 2 == 0)
        return n == 2;
    int limit = static_cast<int>(std::sqrt(n));
    for (int i = 3; i <= limit; i += 2) {
        if (n % i == 0)
            return false;
    }
    return true;
}

std::vector<int> primes_up_to(int n) {
    std::vector<int> out;
    for (int i = 2; i <= n; ++i)
        if (is_prime(i))
            out.push_back(i);
    return out;
}
