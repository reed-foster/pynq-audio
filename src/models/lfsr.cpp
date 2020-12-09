#include <stdio.h>
#include <stdint.h>
#include <unordered_set>

int fast_parity(uint64_t val) {
    int upper = __builtin_parity(val >> 32);
    int lower = __builtin_parity(val & ((1uL << 32) - 1));
    return upper ^ lower;
}

int lfsr_period(uint8_t bits, uint64_t polynomial) {
    std::unordered_set<uint64_t> seen;
    uint64_t mask = (1uL << bits) - 1;
    //uint64_t seed = mask ^ (polynomial >> 8) ^ (polynomial >> 1);
    uint64_t seed = 0xB82EDC58BFFB;
    uint64_t last_seed;
    uint64_t count = 0;
    while (seen.count(seed) == 0) {
        last_seed = seed;
        seen.insert(last_seed);
        uint64_t bit = fast_parity(seed & polynomial);
        seed >>= 1;
        seed &= mask;
        seed |= (bit << (bits - 1));
        seed &= mask;
        count++;
    }
    printf("last_seed = %lX\n", last_seed);
    printf("seed = %lX\n", seed);
    return count;
};

int main(void) {
    uint64_t poly = 0x3a0000500000;
    printf("%d-bit lfsr with poly = 0x%lX\n", 48, poly);
    printf("period = %d\n", lfsr_period(48, poly));
    return 0;
}
