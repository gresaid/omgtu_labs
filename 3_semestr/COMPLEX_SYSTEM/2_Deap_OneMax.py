import random

import matplotlib.pyplot as plt
from deap import base, creator, tools, algorithms

# === КОНСТАНТЫ ЗАДАЧИ И АЛГОРИТМА ===

ONE_MAX_LENGTH = 100

# параметры генетического алгоритма
POPULATION_SIZE = 200  # размер популяции (количество индивидуумов в одном поколении)
P_CROSSOVER = 0.9  # вероятность скрещивания (кроссовера) между двумя родителями
P_MUTATION = 0.1  # вероятность мутации для каждого потомка
MAX_GENERATIONS = 50  # максимальное количество поколений (ограничение по времени/итерациям)

# установка сида для воспроизводимости результатов
RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# === ОПРЕДЕЛЕНИЕ КЛАССОВ И ИНСТРУМЕНТОВ ===

# создание классов для фитнеса и индивидуума
creator.create("FitnessMax", base.Fitness, weights=(1.0,))  # Приспособленность (максимизация)
creator.create("Individual", list, fitness=creator.FitnessMax)  # Индивидуум как список с фитнесом

# инициализация инструментов DEAP
toolbox = base.Toolbox()
toolbox.register("attr_bool", random.randint, 0, 1)  # Генерация случайного бита (0 или 1)
toolbox.register("individual", tools.initRepeat, creator.Individual, toolbox.attr_bool, ONE_MAX_LENGTH)
toolbox.register("population", tools.initRepeat, list, toolbox.individual, POPULATION_SIZE)
toolbox.register("evaluate", lambda ind: (sum(ind),))  # Функция фитнеса: сумма единиц
toolbox.register("mate", tools.cxOnePoint)  # Одноточечный кроссовер
toolbox.register("mutate", tools.mutFlipBit, indpb=1.0 / ONE_MAX_LENGTH)  # Мутация: инверсия бита
toolbox.register("select", tools.selTournament, tournsize=3)  # Турнирный отбор (3 участника)


# === ОСНОВНОЙ ЦИКЛ ГЕНЕТИЧЕСКОГО АЛГОРИТМА ===

def run_genetic_algorithm():
    # инициализация популяции
    population = toolbox.population()
    stats = tools.Statistics(lambda ind: ind.fitness.values[0])
    stats.register("max", max)  # максимальный фитнес
    stats.register("avg", lambda x: sum(x) / len(x))  # средний фитнес

    # инициализация зала славы для хранения лучшего индивидуума
    hof = tools.HallOfFame(1)  # храним только одного лучшего индивидуума

    # списки для хранения максимального и среднего фитнеса по поколениям (для графика)
    max_fitness_history = []
    mean_fitness_history = []

    population, logbook = algorithms.eaSimple(
        population,
        toolbox,
        cxpb=P_CROSSOVER,
        mutpb=P_MUTATION,
        ngen=MAX_GENERATIONS,
        stats=stats,
        halloffame=hof,  # передаём HoF для обновления
        verbose=False  # отключаем встроенный вывод DEAP
    )

    # --- ЛОГИРОВАНИЕ И ВИЗУАЛИЗАЦИЯ ---
    for record in logbook:
        generation = record['gen']
        max_fitness = record['max']
        mean_fitness = record['avg']
        max_fitness_history.append(max_fitness)
        mean_fitness_history.append(mean_fitness)

        # выводим информацию о текущем поколении
        print(f"Поколение {generation}: Макс приспособ. = {max_fitness}, Средняя приспособ. = {mean_fitness}")

        if max_fitness == ONE_MAX_LENGTH:
            best_individual = max(population, key=lambda ind: ind.fitness.values[0])
            print("Лучший индивидуум = ", *best_individual, "\n")
            break

    print("Лучший индивидуум в Зале Славы = ", *hof[0], "\nФитнес = ", hof[0].fitness.values[0])

    # === ПОСТРОЕНИЕ ГРАФИКА ===
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


if __name__ == "__main__":
    run_genetic_algorithm()
