def max_sum_submatrix(matrix):
    if not matrix:
        return 0

    rows, cols = len(matrix), len(matrix[0])
    max_sum = -float("inf")

    for left in range(cols):
        temp = [0] * rows
        for right in range(left, cols):
            for i in range(rows):
                temp[i] += matrix[i][right]

            current_max = temp[0]
            global_max = temp[0]

            for num in temp[1:]:
                current_max = max(num, current_max + num)
                global_max = max(global_max, current_max)

            max_sum = max(max_sum, global_max)

    return max_sum


matrix = [[1, -2, -1, 4], [1, -1, 1, 1], [-1, 2, 3, -1]]
print(max_sum_submatrix(matrix))  # (-1) + 4 + 1 + 1 + 3 + (-1) = 7
