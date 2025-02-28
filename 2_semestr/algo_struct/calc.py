def calculate(s: str) -> int:
    def update_stack(num, op):
        if op == "+":
            stack.append(num)
        elif op == "-":
            stack.append(-num)
        elif op == "*":
            stack.append(stack.pop() * num)
        elif op == "/":
            stack.append(int(stack.pop() / num))

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


print(calculate("150 * (2 - 1)"))
print(calculate("-(3 + 4)"))  # -7
