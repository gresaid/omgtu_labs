def max_weight(s):
    n = len(s)
    max_weight_value = 0

    for L in range(1, n + 1):
        freq = {}
        for i in range(n - L + 1):
            substring = s[i : i + L]
            freq[substring] = freq.get(substring, 0) + 1
        if freq:
            max_freq = max(freq.values())
        else:
            max_freq = 0
        weight = max_freq * L
        max_weight_value = max(max_weight_value, weight)

    return max_weight_value


s = "abcab"
print(max_weight(s))
s2 = "aaaa"
print(max_weight(s2))
