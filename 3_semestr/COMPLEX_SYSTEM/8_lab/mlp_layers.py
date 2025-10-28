import random

import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
from deap import base
from deap import creator
from deap import tools

import elitism
import mlp_layers_test

# границы для размеров скрытых слоёв MLP:
# [слой 1, слой 2, слой 3, слой 4]
BOUNDS_LOW = [5, -5, -10, -20]  # нижние границы
BOUNDS_HIGH = [15, 10, 10, 10]  # верхние границы
NUM_OF_PARAMS = len(BOUNDS_HIGH)  # количество параметров

# константы генетического алгоритма:
POPULATION_SIZE = 20  # размер популяции
P_CROSSOVER = 0.9  # вероятность кроссовера
P_MUTATION = 0.5  # вероятность мутации
MAX_GENERATIONS = 10  # максимальное количество поколений
HALL_OF_FAME_SIZE = 3  # размер зала славы
CROWDING_FACTOR = 10.0  # фактор скученности

# установка начального значения генератора случайных чисел:
RANDOM_SEED = 42
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

# создание класса для тестирования архитектуры MLP:
test = mlp_layers_test.MlpLayersTest(RANDOM_SEED)

toolbox = base.Toolbox()

# стратегия максимизации (чем выше точность — тем лучше):
creator.create("FitnessMax", base.Fitness, weights=(1.0,))

# создание класса Individual на основе списка:
creator.create("Individual", list, fitness=creator.FitnessMax)

# регистрация генераторов для каждого слоя:
for i in range(NUM_OF_PARAMS):
    toolbox.register(
        f"layer_size_{i}",
        random.uniform,
        BOUNDS_LOW[i],
        BOUNDS_HIGH[i]
    )

# кортеж генераторов:
layer_size_generators = tuple(
    toolbox.__getattribute__(f"layer_size_{i}") for i in range(NUM_OF_PARAMS)
)

# оператор создания индивидуума:
toolbox.register(
    "individualCreator",
    tools.initCycle,
    creator.Individual,
    layer_size_generators,
    n=1
)

# оператор создания популяции:
toolbox.register(
    "populationCreator",
    tools.initRepeat,
    list,
    toolbox.individualCreator
)


# функция оценки (точность классификации):
def classificationAccuracy(individual):
    return test.getAccuracy(individual),


toolbox.register("evaluate", classificationAccuracy)

# генетические операторы:
toolbox.register("select", tools.selTournament, tournsize=2)

toolbox.register(
    "mate",
    tools.cxSimulatedBinaryBounded,
    low=BOUNDS_LOW,
    up=BOUNDS_HIGH,
    eta=CROWDING_FACTOR
)

toolbox.register(
    "mutate",
    tools.mutPolynomialBounded,
    low=BOUNDS_LOW,
    up=BOUNDS_HIGH,
    eta=CROWDING_FACTOR,
    indpb=1.0 / NUM_OF_PARAMS
)


# основной поток алгоритма:
def main():
    # начальная популяция
    population = toolbox.populationCreator(n=POPULATION_SIZE)

    # статистика
    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("max", np.max)  # максимальная точность
    stats.register("avg", np.mean)  # средняя точность

    # зал славы
    hof = tools.HallOfFame(HALL_OF_FAME_SIZE)

    # запуск эволюции с элитизмом
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

    # вывод лучших решений
    print("\n=== Лучшие архитектуры MLP ===")
    for i, ind in enumerate(hof.items):
        sizes = [int(round(x)) for x in ind]
        print(f"{i + 1}. {test.formatParams(ind)} → точность = {ind.fitness.values[0]:.4f}")

    # график эволюции
    maxFitnessValues, meanFitnessValues = logbook.select("max", "avg")

    sns.set_style("whitegrid")
    plt.figure(figsize=(10, 6))
    plt.plot(maxFitnessValues, color='red', label='Максимальная точность', linewidth=2)
    plt.plot(meanFitnessValues, color='green', label='Средняя точность', linewidth=2)
    plt.xlabel('Поколение')
    plt.ylabel('Точность')
    plt.title('Эволюция точности MLP по поколениям')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
