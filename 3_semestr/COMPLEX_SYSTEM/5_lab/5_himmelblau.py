import random

import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
from deap import base
from deap import creator
from deap import tools

import elitism

# константы задачи:
DIMENSIONS = 2  # количество измерений
BOUND_LOW, BOUND_UP = -5.0, 5.0  # границы для всех измерений

# константы генетического алгоритма:
POPULATION_SIZE = 300  # размер популяции
P_CROSSOVER = 0.9  # вероятность кроссовера
P_MUTATION = 0.5  # вероятность мутации
MAX_GENERATIONS = 300  # максимальное количество поколений
HALL_OF_FAME_SIZE = 30  # размер зала славы
CROWDING_FACTOR = 20.0  # фактор скученности для кроссовера и мутации

# установка начального значения генератора случайных чисел:
RANDOM_SEED = 42  # попробуйте также 17, 13...
random.seed(RANDOM_SEED)

toolbox = base.Toolbox()

# определение стратегии минимизации с одним целевым значением:
creator.create("FitnessMin", base.Fitness, weights=(-1.0,))

# создание класса Individual на основе списка:
creator.create("Individual", list, fitness=creator.FitnessMin)


# вспомогательная функция для создания случайных вещественных чисел в заданном диапазоне [low, up]:
def randomFloat(low, up):
    return [random.uniform(a, b) for a, b in zip([low] * DIMENSIONS, [up] * DIMENSIONS)]


# создание оператора для генерации случайных чисел в заданном диапазоне и измерении:
toolbox.register("attr_float", randomFloat, BOUND_LOW, BOUND_UP)

# создание оператора для заполнения экземпляра Individual:
toolbox.register("individualCreator", tools.initIterate, creator.Individual, toolbox.attr_float)

# создание оператора популяции для генерации списка индивидуумов:
toolbox.register("populationCreator", tools.initRepeat, list, toolbox.individualCreator)


# функция Химмельблау как фитнес-функция для индивидуума:
def himmelblau(individual):
    x = individual[0]
    y = individual[1]
    f = (x ** 2 + y - 11) ** 2 + (x + y ** 2 - 7) ** 2
    return f,  # возвращает кортеж


toolbox.register("evaluate", himmelblau)

# генетические операторы:
toolbox.register("select", tools.selTournament, tournsize=2)
toolbox.register("mate", tools.cxSimulatedBinaryBounded, low=BOUND_LOW, up=BOUND_UP, eta=CROWDING_FACTOR)
toolbox.register("mutate", tools.mutPolynomialBounded, low=BOUND_LOW, up=BOUND_UP, eta=CROWDING_FACTOR,
                 indpb=1.0 / DIMENSIONS)


# поток генетического алгоритма:
def main():
    # создание начальной популяции (поколение 0):
    population = toolbox.populationCreator(n=POPULATION_SIZE)

    # подготовка объекта статистики:
    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("min", np.min)  # минимальная фитнес-оценка
    stats.register("avg", np.mean)  # средняя фитнес-оценка

    # определение объекта зала славы:
    hof = tools.HallOfFame(HALL_OF_FAME_SIZE)

    # выполнение потока генетического алгоритма с элитизмом:
    population, logbook = elitism.eaSimpleWithElitism(population, toolbox, cxpb=P_CROSSOVER, mutpb=P_MUTATION,
                                                      ngen=MAX_GENERATIONS, stats=stats, halloffame=hof, verbose=True)

    # вывод информации о лучшем найденном решении:
    best = hof.items[0]
    print("-- Лучший индивидуум = ", best)
    print("-- Лучшая фитнес-оценка = ", best.fitness.values[0])

    print("- Лучшие решения:")
    for i in range(HALL_OF_FAME_SIZE):
        print(i, ": ", hof.items[i].fitness.values[0], " -> ", hof.items[i])

    # построение графика расположения решений на плоскости x-y:
    plt.figure(1)
    globalMinima = [[3.0, 2.0], [-2.805118, 3.131312], [-3.779310, -3.283186], [3.584458, -1.848126]]
    plt.scatter(*zip(*globalMinima), marker='X', color='red', zorder=1)  # глобальные минимумы
    plt.scatter(*zip(*population), marker='.', color='blue', zorder=0)  # популяция
    plt.xlabel('X')
    plt.ylabel('Y')
    plt.title('Расположение решений на плоскости X-Y')

    # извлечение статистики:
    minFitnessValues, meanFitnessValues = logbook.select("min", "avg")

    # построение графика статистики:
    plt.figure(2)
    sns.set_style("whitegrid")
    plt.plot(minFitnessValues, color='red')
    plt.plot(meanFitnessValues, color='green')
    plt.xlabel('Поколение')
    plt.ylabel('Минимальная / Средняя фитнес-оценка')
    plt.title('Минимальная и средняя фитнес-оценка по поколениям')

    plt.show()


if __name__ == "__main__":
    main()
