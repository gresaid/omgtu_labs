def calculate(s: str) -> int:
    def update_stack(num, op):
        if op == "+":
            stack.append(num)
        elif op == "-":
            stack.append(-num)
        elif op == "*":
            stack.append(stack.pop() * num)
        elif op == "/":
            if num != 0:
                stack.append(int(stack.pop() / num))
            elif num == 0:
                raise ValueError("division by zero")

    balance = 0
    for char in s:
        if char == "(":
            balance += 1
        elif char == ")":
            balance -= 1
        if balance < 0:
            raise ValueError("unbalance")
    if balance != 0:
        raise ValueError("unbalance")

    stack = []
    num = 0
    op = "+"
    i = 0

    while i < len(s):
        char = s[i]
        if char.isdigit():
            num = num * 10 + int(char)
        elif char in "+-*/":
            update_stack(num, op)
            num = 0
            op = char
        elif char == "(":
            j = i + 1
            balance = 1
            while j < len(s):
                if s[j] == "(":
                    balance += 1
                elif s[j] == ")":
                    balance -= 1
                if balance == 0:
                    break
                j += 1
            num = calculate(s[i + 1 : j])
            i = j
        i += 1

    update_stack(num, op)
    return sum(stack)


# print(calculate(")2+2("))  # -7
# print(calculate("2 + (2 / 0) + ) + 2"))
# print(calculate("2 + (2 / ( 4 - 4 ))"))
