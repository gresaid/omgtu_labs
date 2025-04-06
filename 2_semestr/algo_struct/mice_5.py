import random


def find_mice_arrangement(n, m, k, l, s):

    for _ in range(10000):
        mice = [0] * n + [1] * m
        random.shuffle(mice)
        mice_copy = mice.copy()

        start_position = 0
        while start_position < len(mice_copy) and mice_copy[start_position] != 0:
            start_position = (start_position + 1) % len(mice_copy)

        if start_position >= len(mice_copy):
            continue

        position = start_position

        while len(mice_copy) > (k + l):
            for _ in range(s - 1):
                position = (position + 1) % len(mice_copy)

            mice_copy.pop(position)

            if position == len(mice_copy):
                position = 0

        if mice_copy.count(0) == k and mice_copy.count(1) == l:
            return " ".join(["G" if mouse == 0 else "W" for mouse in mice])

    return "Не удалось найти решение"


print(find_mice_arrangement(5, 3, 2, 1, 3))
