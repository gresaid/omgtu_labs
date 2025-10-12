import random
import matplotlib.pyplot as plt

# === КОНСТАНТЫ ЗАДАЧИ И АЛГОРИТМА ===

# Длина битовой строки, которую нужно оптимизировать (цель: получить строку из 100 единиц)
ONE_MAX_LENGTH = 100

# Параметры генетического алгоритма
# чем больше размер популяции тем быстрее вырабатывается приспособленность
POPULATION_SIZE = 100  # Размер популяции (количество индивидуумов в одном поколении)
# высокая вероятность усиливает исследование пространства решений,
# но слишком низкая может привести к стагнации (популяция эволюционирует медленно).
P_CROSSOVER = 0.1  # Вероятность скрещивания (кроссовера) между двумя родителями
# cлишком низкая — риск застревания; слишком высокая- алгоритм становится похожим на случайный поиск
P_MUTATION = 0.1  # Вероятность мутации для каждого потомка
MAX_GENERATIONS = 50  # Максимальное количество поколений (ограничение по времени/итерациям)

# Установка сида для воспроизводимости результатов
RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# === ОПРЕДЕЛЕНИЕ КЛАССОВ ===

# Класс для хранения значения приспособленности (фитнеса) индивидуума
class FitnessMax:
    def __init__(self):
        self.values = [0]  # Приспособленность хранится как список (для совместимости с DEAP, если бы использовался)

# Класс индивидуума — наследуется от list, чтобы можно было работать с битовой строкой как со списком
class Individual(list):
    def __init__(self, *args):
        super().__init__(*args)  # Инициализируем базовый класс list
        self.fitness = FitnessMax()  # Каждый индивидуум имеет свой объект фитнеса

# === ФУНКЦИИ ДЛЯ РАСЧЁТА ФИТНЕСА И СОЗДАНИЯ ПОПУЛЯЦИИ ===

# Функция вычисления фитнеса для задачи OneMax: сумма всех битов (чем больше 1, тем лучше)
def calculate_fitness(individual):
    return sum(individual)  # Возвращает количество единиц в строке

# Функция создания одного случайного индивидуума (битовая строка длины ONE_MAX_LENGTH)
def create_individual():
    return Individual([random.randint(0, 1) for _ in range(ONE_MAX_LENGTH)])

# Функция создания начальной популяции из n индивидуумов
def create_population(population_size):
    return [create_individual() for _ in range(population_size)]

# === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===

# Функция клонирования индивидуума (с сохранением его фитнеса)
def clone_individual(individual):
    ind = Individual(individual[:])  # Создаём копию списка (глубокое копирование)
    ind.fitness.values[0] = individual.fitness.values[0]  # Копируем значение фитнеса
    return ind

# Турнирный отбор: выбираем population_size индивидуумов, каждый раз выбирая лучшего из трёх случайных
# Старый код:
# def selTournament(population, p_len):
#     offspring = []  # Список потомков
#     for n in range(p_len):
#         # Генерируем три случайных индекса (пока не будут различными)
#         i1 = i2 = i3 = 0
#         while i1 == i2 or i1 == i3 or i2 == i3:
#             i1, i2, i3 = random.randint(0, p_len - 1), random.randint(0, p_len - 1), random.randint(0, p_len - 1)
#         # Выбираем лучшего из трёх по фитнесу
#         selected = max([population[i1], population[i2], population[i3]], key=lambda ind: ind.fitness.values[0])
#         offspring.append(selected)
#     return offspring
def select_tournament(population, population_size):
    offspring = []
    for _ in range(population_size):
        # Выбираем три случайных уникальных индекса с помощью random.sample
        indices = random.sample(range(len(population)), 3)
        # Выбираем лучшего по фитнесу
        best_individual = max([population[i] for i in indices], key=lambda ind: ind.fitness.values[0])
        offspring.append(best_individual)
    return offspring

# Одноточечный кроссовер: обмен участками между двумя родителями
def crossover_one_point(child1, child2):
    s = random.randint(1, len(child1) - 1)  # Точка разреза (весь диапазон, кроме краёв)
    # Меняем местами части строк после точки s
    child1[s:], child2[s:] = child2[s:], child1[s:]

# Мутация: инверсия бита с заданной вероятностью
# Старый код:
# def mutFlipBit(mutant, indpb=0.01):
#     for idx in range(len(mutant)):
#         if random.random() < indpb:  # Если случайное число меньше вероятности мутации
# #             mutant[idx] = 0 if mutant[idx] == 1 else 1  # Инвертируем бит
# Вместо проверки каждого бита с вероятностью indpb,
# теперь выбираются случайные индексы для мутации с помощью
# random.sample(range(len(mutant)), k=int(len(mutant) * indpb)).
# Это быстрее, так как уменьшает количество генераций случайных чисел.
def mutate_flip_bit(mutant, indpb=0.01):
    # Выбираем случайные индексы для мутации (в среднем indpb * длина строки)
    mutation_indices = random.sample(range(len(mutant)), k=int(len(mutant) * indpb))
    for idx in mutation_indices:
        mutant[idx] = 0 if mutant[idx] == 1 else 1  # Инвертируем бит

# === ОСНОВНОЙ ЦИКЛ ГЕНЕТИЧЕСКОГО АЛГОРИТМА ===

def run_genetic_algorithm():
    # Инициализация популяции и вычисление начального фитнеса
    population = create_population(POPULATION_SIZE)
    generation_counter = 0  # Счётчик текущего поколения
    fitness_values = [calculate_fitness(ind) for ind in population]
    for individual, fitness_value in zip(population, fitness_values):
        individual.fitness.values[0] = fitness_value

    # Списки для хранения максимального и среднего фитнеса по поколениям (для графика)
    max_fitness_history = []
    mean_fitness_history = []

    # Главный цикл: продолжаем пока не достигнем максимума (все 100 единиц) или не исчерпаем поколения
    while max(fitness_values) < ONE_MAX_LENGTH and generation_counter < MAX_GENERATIONS:
        generation_counter += 1  # Увеличиваем счётчик поколений

        # --- ЭТАП 1: ОТБОР (SELECTION) ---
        # Отбираем родителей методом турнирного отбора
        offspring = select_tournament(population, POPULATION_SIZE)
        # Клонируем выбранных родителей (чтобы не менять оригинальные особи при кроссовере/мутации)
        offspring = [clone_individual(ind) for ind in offspring]

        # --- ЭТАП 2: КРОССОВЕР (CROSSOVER) ---
        # Применяем одноточечный кроссовер к парам родителей (каждая пара: чётный и следующий нечётный)
        for child1, child2 in zip(offspring[::2], offspring[1::2]):
            if random.random() < P_CROSSOVER:  # С вероятностью P_CROSSOVER применяем кроссовер
                crossover_one_point(child1, child2)

        # --- ЭТАП 3: МУТАЦИЯ (MUTATION) ---
        # Применяем мутацию к каждому потомку
        for mutant in offspring:
            if random.random() < P_MUTATION:  # С вероятностью P_MUTATION
                # Вероятность мутации каждого бита: 1 / длина строки (чтобы в среднем один бит мутировал)
                mutate_flip_bit(mutant, indpb=1.0 / ONE_MAX_LENGTH)

        # --- ЭТАП 4: ВЫЧИСЛЕНИЕ ФИТНЕСА ДЛЯ НОВОГО ПОКОЛЕНИЯ ---
        fitness_values = [calculate_fitness(ind) for ind in offspring]  # Вычисляем фитнес для потомков
        # Обновляем значения фитнеса в объектах Individual
        for individual, fitness_value in zip(offspring, fitness_values):
            individual.fitness.values[0] = fitness_value

        # --- ЭТАП 5: ЗАМЕНА ПОПУЛЯЦИИ ---
        # Заменяем старую популяцию на новое поколение потомков
        population[:] = offspring

        # --- ЭТАП 6: ЛОГИРОВАНИЕ И ВИЗУАЛИЗАЦИЯ ---
        # Обновляем список значений фитнеса текущей популяции
        fitness_values = [ind.fitness.values[0] for ind in population]
        # Находим максимальный и средний фитнес
        max_fitness = max(fitness_values)
        mean_fitness = sum(fitness_values) / len(population)
        # Сохраняем в историю для графика
        max_fitness_history.append(max_fitness)
        mean_fitness_history.append(mean_fitness)

        # Выводим информацию о текущем поколении
        print(f"Поколение {generation_counter}: Макс приспособ. = {max_fitness}, Средняя приспособ. = {mean_fitness}")

        # Находим индекс лучшего индивидуума и выводим его
        best_index = fitness_values.index(max(fitness_values))
        print("Лучший индивидуум = ", *population[best_index], "\n")

    # === ПОСТРОЕНИЕ ГРАФИКА ===
    # Строим график зависимости максимальной и средней приспособленности от поколения
    plt.figure(figsize=(10, 6))  # Увеличенный размер графика
    plt.plot(max_fitness_history, color='#FF4500', linewidth=2, label='Максимальная приспособленность')
    plt.plot(mean_fitness_history, color='#32CD32', linewidth=2, label='Средняя приспособленность')
    plt.xlabel('Поколение', fontsize=12)
    plt.ylabel('Приспособленность', fontsize=12)
    plt.title('Зависимость максимальной и средней приспособленности от поколения', fontsize=14)
    plt.legend(fontsize=10)
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.savefig('fitness_evolution.png', dpi=300)  # Сохранение графика в файл
    plt.show()

# Запуск алгоритма
if __name__ == "__main__":
    run_genetic_algorithm()