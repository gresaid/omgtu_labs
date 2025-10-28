import random

import matplotlib.pyplot as plt
import numpy
import seaborn as sns
from deap import base
from deap import creator
from deap import tools

import elitism
import friedman

NUM_OF_FEATURES = 15  # количество признаков
NUM_OF_SAMPLES = 60  # количество образцов

# константы генетического алгоритма:
POPULATION_SIZE = 30  # размер популяции
P_CROSSOVER = 0.9  # вероятность кроссовера
P_MUTATION = 0.2  # вероятность мутации индивидуума
MAX_GENERATIONS = 30  # максимальное количество поколений
HALL_OF_FAME_SIZE = 5  # размер зала славы

# установка начального значения генератора случайных чисел:
RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# создание тестового класса Фридмана-1:
friedman = friedman.Friedman1Test(NUM_OF_FEATURES, NUM_OF_SAMPLES, RANDOM_SEED)

toolbox = base.Toolbox()

# определение стратегии минимизации с одним целевым значением:
creator.create("FitnessMin", base.Fitness, weights=(-1.0,))

# создание класса Individual на основе списка:
creator.create("Individual", list, fitness=creator.FitnessMin)

# создание оператора, возвращающего случайное 0 или 1:
toolbox.register("zeroOrOne", random.randint, 0, 1)

# создание оператора для заполнения экземпляра Individual:
toolbox.register("individualCreator", tools.initRepeat, creator.Individual, toolbox.zeroOrOne, len(friedman))

# создание оператора популяции для генерации списка индивидуумов:
toolbox.register("populationCreator", tools.initRepeat, list, toolbox.individualCreator)


# вычисление фитнес-оценки:
def friedmanTestScore(individual):
    return friedman.getMSE(individual),  # возвращает кортеж


toolbox.register("evaluate", friedmanTestScore)

# генетические операторы для бинарного списка:
toolbox.register("select", tools.selTournament, tournsize=2)
toolbox.register("mate", tools.cxTwoPoint)
toolbox.register("mutate", tools.mutFlipBit, indpb=1.0 / len(friedman))


# поток генетического алгоритма:
def main():
    # создание начальной популяции (поколение 0):
    population = toolbox.populationCreator(n=POPULATION_SIZE)

    # подготовка объекта статистики:
    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("min", numpy.min)  # минимальная фитнес-оценка
    stats.register("avg", numpy.mean)  # средняя фитнес-оценка

    # определение объекта зала славы:
    hof = tools.HallOfFame(HALL_OF_FAME_SIZE)

    # выполнение потока генетического алгоритма с добавлением зала славы:
    population, logbook = elitism.eaSimpleWithElitism(population, toolbox, cxpb=P_CROSSOVER, mutpb=P_MUTATION,
                                                      ngen=MAX_GENERATIONS, stats=stats, halloffame=hof, verbose=True)

    # вывод лучшего найденного решения:
    best = hof.items[0]
    print("-- Лучший индивидуум = ", best)
    print("-- Лучшая фитнес-оценка = ", best.fitness.values[0])

    # извлечение статистики:
    minFitnessValues, meanFitnessValues = logbook.select("min", "avg")

    # построение графика статистики:
    sns.set_style("whitegrid")
    plt.plot(minFitnessValues, color='red')
    plt.plot(meanFitnessValues, color='green')
    plt.xlabel('Поколение')
    plt.ylabel('Минимальная / Средняя фитнес-оценка')
    plt.title('Минимальная и средняя фитнес-оценка по поколениям')
    plt.show()


if __name__ == "__main__":
    main()
