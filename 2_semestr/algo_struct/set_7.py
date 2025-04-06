def peresech(set1, set2):
    if not set1 or not set2:
        return set()
    temp = {}
    for x in set1:
        temp[x] = True
    res = []
    for x in set2:
        if x in temp:
            res.append(x)
    return set(res)


# set1 = {1, 2, 3, 4, 5}
# set2 = {4, 5, 6, 7, 8}
# print(peresech(set1, set2))


def max_peresech_size(sets):
    mx = 0
    for i in range(len(sets)):
        for j in range(i + 1, len(sets)):
            temp = peresech(sets[i], sets[j])
            if len(temp) > mx:
                mx = len(temp)
    return mx


sets = [{1, 2, 3}, {1, 2, 3}, {7, 8, 9}]
print(max_peresech_size(sets))
