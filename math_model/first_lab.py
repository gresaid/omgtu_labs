import pulp
import matplotlib.pyplot as plt

# Создаем задачу минимизации
problem = pulp.LpProblem("Production_Plan_Optimization", pulp.LpMinimize)

# Данные
cost_delivery = {(1, 1): 4, (1, 2): 5, (2, 1): 6, (2, 2): 7}
cost_production = {1: 3, 2: 4}
supply_limits = {(1, 1): 100, (1, 2): 150, (2, 1): 120, (2, 2): 130}
demand = {1: 80, 2: 70}
raw_materials_needed = {(1, 1): 2, (1, 2): 3, (2, 1): 1, (2, 2): 4}

# Переменные: количество сырья, доставляемого из пунктов
x = pulp.LpVariable.dicts("RawMaterial", cost_delivery.keys(), lowBound=0, cat='Continuous')

# Переменные: количество произведенной продукции
y = pulp.LpVariable.dicts("Product", cost_production.keys(), lowBound=0, cat='Continuous')

# Целевая функция: минимизация затрат на доставку сырья и производство продукции
problem += pulp.lpSum([cost_delivery[i, j] * x[i, j] for (i, j) in cost_delivery]) + \
           pulp.lpSum([cost_production[k] * y[k] for k in cost_production])

# Ограничения на запасы сырья
for (i, j) in supply_limits:
    problem += x[i, j] <= supply_limits[i, j], f"SupplyLimit_RawMaterial_{i}_{j}"

# Ограничения на минимальные потребности в продукции
for k in demand:
    problem += y[k] >= demand[k], f"Demand_Product_{k}"

# Ограничения на использование сырья для производства продукции
for i in range(1, 3):
    for j in range(1, 3):
        problem += pulp.lpSum([raw_materials_needed[k, i] * y[k] for k in demand]) <= \
                   pulp.lpSum([x[i, j] for j in range(1, 3)]), f"RawMaterial_Use_{i}_{j}"

# Решаем задачу
problem.solve()

# Выводим статус и общую стоимость
status = pulp.LpStatus[problem.status]
total_cost = pulp.value(problem.objective)
print("Статус:", status)
print(f"Общая стоимость: {total_cost}")

# Сохраним значения переменных для построения графиков
raw_materials_used = {key: x[key].varValue for key in x}
products_made = {key: y[key].varValue for key in y}

# График распределения сырья по пунктам
raw_materials_per_point = {}
for (material, point), quantity in raw_materials_used.items():
    if point not in raw_materials_per_point:
        raw_materials_per_point[point] = 0
    raw_materials_per_point[point] += quantity

points = list(raw_materials_per_point.keys())
quantities = list(raw_materials_per_point.values())

plt.figure(figsize=(12, 6))
names = ['Поставщик 1', 'Поставщик 2']
# График доставки сырья по пунктам
plt.subplot(1, 2, 1)
plt.bar(names, quantities, color='black')
plt.title("Количество доставленного сырья по поставщикам")
plt.xlabel("Поставщик")
plt.ylabel("Количество сырья")

# График произведенной продукции по типам
product_types = list(products_made.keys())
product_quantities = list(products_made.values())

names = ['Продукт 1', 'Продукт 2']
plt.subplot(1, 2, 2)
plt.bar(names, product_quantities, color='black')
plt.title("Произведенная продукция по типам")
plt.xlabel("Тип продукции")
plt.ylabel("Количество продукции")

# Добавляем текст с выводом статуса и общей стоимости на график
plt.figtext(0.5, 0.02, f"Статус решения: {status}", ha="center", fontsize=12, color='black')
plt.figtext(0.5, 0.05, f"Общая стоимость: {total_cost}", ha="center", fontsize=12, color='black')

plt.tight_layout()
plt.show()