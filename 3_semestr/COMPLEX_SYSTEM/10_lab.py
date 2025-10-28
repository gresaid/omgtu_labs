import numpy as np

# выборка: [длина, ширина]
x_train = np.array([
    [70, 65], [75, 70], [68, 62], [80, 75], [72, 68],  # Яблоки
    [180, 40], [170, 35], [190, 45], [165, 38], [175, 42]  # Бананы
])

# -1 — яблоко, +1 — банан
y_train = np.array([-1, -1, -1, -1, -1, 1, 1, 1, 1, 1])

# вычисление средних для каждого класса
mean_apple = np.mean(x_train[y_train == -1], axis=0)  # [длина, ширина]
mean_banana = np.mean(x_train[y_train == 1], axis=0)

# вычисление дисперсий (с ddof=1 — несмещённая оценка)
var_apple = np.var(x_train[y_train == -1], axis=0, ddof=1)
var_banana = np.var(x_train[y_train == 1], axis=0, ddof=1)

print("Яблоко (ср):", mean_apple)
print("Банан (ср):", mean_banana)
print("Яблоко (дисп):", var_apple)
print("Банан (дисп):", var_banana)

# априорные вероятности
p_apple = np.mean(y_train == -1)  # 5/10 = 0.5
p_banana = np.mean(y_train == 1)  # 5/10 = 0.5


# лямбда-функции: логарифм апостериорной вероятности (без const)
def log_posterior_apple(x):
    return -np.log(var_apple[0]) - (x[0] - mean_apple[0]) ** 2 / (2 * var_apple[0]) \
        - np.log(var_apple[1]) - (x[1] - mean_apple[1]) ** 2 / (2 * var_apple[1])


def log_posterior_banana(x):
    return -np.log(var_banana[0]) - (x[0] - mean_banana[0]) ** 2 / (2 * var_banana[0]) \
        - np.log(var_banana[1]) - (x[1] - mean_banana[1]) ** 2 / (2 * var_banana[1])


# тестируем на новом фрукте
x_test = [73, 67]  # похоже на яблоко
# x_test = [172, 39]  # похоже на банан

pred = np.argmax([log_posterior_apple(x_test), log_posterior_banana(x_test)]) * 2 - 1
print(f"\nТестовый фрукт: длина={x_test[0]}, ширина={x_test[1]}")
print("Предсказанный класс:", "Яблоко (-1)" if pred == -1 else "Банан (+1)")

# проверка на обучающей выборке (доля ошибок)
predictions = []
for x in x_train:
    pred = np.argmax([log_posterior_apple(x), log_posterior_banana(x)]) * 2 - 1
    predictions.append(pred)

error_rate = np.mean(np.array(predictions) != y_train)
print(f"\nДоля ошибок на обучающей выборке: {error_rate:.2%}")
