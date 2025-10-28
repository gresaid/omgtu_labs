import random

import matplotlib.pyplot as plt
import numpy
import seaborn as sns
from deap import base
from deap import creator
from deap import tools

import elitism
import hyperparameter_tuning_genetic_test

# границы для гиперпараметров AdaBoost:
# "n_estimators": 1..100
# "learning_rate": 0.01..1.00
# "algorithm": 0 (SAMME), 1 (SAMME.R)
BOUNDS_LOW = [1, 0.01]
BOUNDS_HIGH = [100, 1.00]
NUM_OF_PARAMS = len(BOUNDS_HIGH)
# константы генетического алгоритма:
POPULATION_SIZE = 20  # размер популяции
P_CROSSOVER = 0.9  # вероятность кроссовера
P_MUTATION = 0.5  # вероятность мутации
MAX_GENERATIONS = 5  # максимальное количество поколений
HALL_OF_FAME_SIZE = 5  # размер зала славы
CROWDING_FACTOR = 20.0  # фактор скученности для кроссовера и мутации

# установка начального значения генератора случайных чисел:
RANDOM_SEED = 42
random.seed(RANDOM_SEED)
numpy.random.seed(RANDOM_SEED)

# создание класса для тестирования точности классификатора:
test = hyperparameter_tuning_genetic_test.HyperparameterTuningGenetic(RANDOM_SEED)

toolbox = base.Toolbox()

# определение стратегии максимизации с одним целевым значением:
creator.create("FitnessMax", base.Fitness, weights=(1.0,))

# создание класса Individual на основе списка:
creator.create("Individual", list, fitness=creator.FitnessMax)

# определение генераторов для каждого гиперпараметра:
for i in range(NUM_OF_PARAMS):
    toolbox.register(f"hyperparameter_{i}",
                     random.uniform,
                     BOUNDS_LOW[i],
                     BOUNDS_HIGH[i])

# создание кортежа генераторов для всех гиперпараметров:
hyperparameters = tuple(toolbox.__getattribute__(f"hyperparameter_{i}") for i in range(NUM_OF_PARAMS))

# создание оператора для генерации индивидуума:
toolbox.register("individualCreator",
                 tools.initCycle,
                 creator.Individual,
                 hyperparameters,
                 n=1)

# создание оператора популяции:
toolbox.register("populationCreator",
                 tools.initRepeat,
                 list,
                 toolbox.individualCreator)


# функция вычисления фитнес-оценки (точность классификатора):
def classificationAccuracy(individual):
    return test.getAccuracy(individual),


toolbox.register("evaluate", classificationAccuracy)

# генетические операторы:
toolbox.register("select", tools.selTournament, tournsize=2)  # турнирный отбор
toolbox.register("mate",
                 tools.cxSimulatedBinaryBounded,
                 low=BOUNDS_LOW,
                 up=BOUNDS_HIGH,
                 eta=CROWDING_FACTOR)  # кроссовер SBX
toolbox.register("mutate",
                 tools.mutPolynomialBounded,
                 low=BOUNDS_LOW,
                 up=BOUNDS_HIGH,
                 eta=CROWDING_FACTOR,
                 indpb=1.0 / NUM_OF_PARAMS)  # полиномиальная мутация


# основной поток генетического алгоритма:
def main():
    # создание начальной популяции:
    population = toolbox.populationCreator(n=POPULATION_SIZE)

    # подготовка статистики:
    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("max", numpy.max)  # максимальная точность
    stats.register("avg", numpy.mean)  # средняя точность

    # создание зала славы:
    hof = tools.HallOfFame(HALL_OF_FAME_SIZE)

    # запуск генетического алгоритма с элитизмом:
    population, logbook = elitism.eaSimpleWithElitism(
        population,
        toolbox,
        cxpb=P_CROSSOVER,
        mutpb=P_MUTATION,
        ngen=MAX_GENERATIONS,
        stats=stats,
        halloffame=hof,
        verbose=True
    )

    # вывод лучшего решения:
    best = hof.items[0]
    print("- Лучшее решение:")
    print("Гиперпараметры = ", test.formatParams(best))
    print(f"Точность = {best.fitness.values[0]:.5f}")

    # извлечение статистики:
    maxFitnessValues, meanFitnessValues = logbook.select("max", "avg")

    # построение графика:
    sns.set_style("whitegrid")
    plt.figure(figsize=(10, 6))
    plt.plot(maxFitnessValues, color='red', label='Максимальная точность')
    plt.plot(meanFitnessValues, color='green', label='Средняя точность')
    plt.xlabel('Поколение')
    plt.ylabel('Точность')
    plt.title('Максимальная и средняя точность по поколениям')
    plt.legend()
    plt.grid(True)
    plt.show()


if __name__ == "__main__":
    main()
