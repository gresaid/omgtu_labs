import random

import matplotlib.pyplot as plt
import numpy as np
from deap import base, creator, tools
from matplotlib.animation import FuncAnimation

# === КОНСТАНТЫ ЗАДАЧИ И АЛГОРИТМА ===

ONE_MAX_LENGTH = 100

# параметры генетического алгоритма
POPULATION_SIZE = 200  # размер популяции (количество индивидуумов в одном поколении)
P_CROSSOVER = 0.9  # вероятность скрещивания (кроссовера) между двумя родителями
P_MUTATION = 0.1  # вероятность мутации для каждого потомка
MAX_GENERATIONS = 50  # максимальное количество поколений (ограничение по времени/итераций)

RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# === ОПРЕДЕЛЕНИЕ КЛАССОВ И ИНСТРУМЕНТОВ ===

creator.create("FitnessMax", base.Fitness, weights=(1.0,))  # Приспособленность (максимизация)
creator.create("Individual", list, fitness=creator.FitnessMax)  # Индивидуум как список с фитнесом

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

    # инициализация Зала Славы для хранения лучшего индивидуума
    hof = tools.HallOfFame(1)  # храним только одного лучшего индивидуума

    # список для хранения фитнесов всех индивидуумов по поколениям (для анимации)
    fitness_history = []

    # вычисляем начальные фитнесы для популяции
    fitnesses = [toolbox.evaluate(ind)[0] for ind in population]
    for ind, fit in zip(population, fitnesses):
        ind.fitness.values = (fit,)
    fitness_history.append(fitnesses)

    for gen in range(MAX_GENERATIONS):
        population = toolbox.select(population, len(population))
        population = [toolbox.clone(ind) for ind in population]

        for child1, child2 in zip(population[::2], population[1::2]):
            if random.random() < P_CROSSOVER:
                toolbox.mate(child1, child2)
                del child1.fitness.values
                del child2.fitness.values

        for mutant in population:
            if random.random() < P_MUTATION:
                toolbox.mutate(mutant)
                del mutant.fitness.values

        fitnesses = [toolbox.evaluate(ind)[0] for ind in population]
        for ind, fit in zip(population, fitnesses):
            ind.fitness.values = (fit,)
        fitness_history.append(fitnesses)

        hof.update(population)

        # --- ЛОГИРОВАНИЕ ---
        max_fitness = max(fitnesses)
        mean_fitness = sum(fitnesses) / len(fitnesses)
        print(f"Поколение {gen + 1}: Макс приспособ. = {max_fitness}, Средняя приспособ. = {mean_fitness}")

        if max_fitness == ONE_MAX_LENGTH:
            best_individual = max(population, key=lambda ind: ind.fitness.values[0])
            print("Лучший индивидуум = ", *best_individual, "\n")
            break

    print("Лучший индивидуум в Зале Славы = ", *hof[0], "\nФитнес = ", hof[0].fitness.values[0])

    # === ПОСТРОЕНИЕ АНИМАЦИИ ===
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.set_xlabel('Индивидуум', fontsize=12)
    ax.set_ylabel('Приспособленность', fontsize=12)
    ax.set_title('Приспособленность индивидуумов по поколениям', fontsize=14)
    ax.grid(True, linestyle='--', alpha=0.7)
    ax.set_xlim(-0.5, POPULATION_SIZE - 0.5)
    ax.set_ylim(0, ONE_MAX_LENGTH + 5)

    scatter = ax.scatter([], [], color='#FF4500', s=20, alpha=0.6)

    gen_text = ax.text(0.02, 0.98, '', transform=ax.transAxes, fontsize=12, verticalalignment='top')

    def init():
        scatter.set_offsets(np.empty((0, 2)))  # Пустой массив для начальной инициализации
        gen_text.set_text('')
        return scatter, gen_text

    # функция обновления анимации для каждого кадра (поколения)
    def update(frame):
        # x - индексы индивидуумов, y - их фитнесы
        x = np.arange(POPULATION_SIZE)
        y = np.array(fitness_history[frame])
        scatter.set_offsets(np.column_stack((x, y)))  # формируем массив [[x1, y1], [x2, y2], ...]
        gen_text.set_text(f'Поколение {frame + 1}')
        return scatter, gen_text

    ani = FuncAnimation(fig, update, frames=len(fitness_history), init_func=init,
                        blit=True, interval=200)  # 200 мс между кадрами
    plt.tight_layout()
    ani.save('fitness_evolution.gif', writer='pillow', fps=5)
    plt.show()


if __name__ == "__main__":
    run_genetic_algorithm()
