def f(arr):
    result = [0] * len(arr)

    for i in range(len(arr)):
        for j in range(i + 1, len(arr)):
            if arr[j] > arr[i]:
                result[i] = arr[j]
                break

    return result


A = [1, 3, 2, 5, 3, 4]
result = f(A)
print(result)
