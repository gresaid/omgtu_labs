import random

import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
from deap import base, creator, tools

import elitism
import mlp_hyperparameters_test

# === Границы гиперпараметров ===
# [size1, size2, size3, size4, act_idx, solver_idx, alpha, lr_idx]
BOUNDS_LOW = [5, -5, -10, -20, 0, 0, 0.0001, 0]
BOUNDS_HIGH = [15, 10, 10, 10, 2.999, 2.999, 2.0, 2.999]
NUM_OF_PARAMS = len(BOUNDS_HIGH)

# === Константы ГА ===
POPULATION_SIZE = 20
P_CROSSOVER = 0.9
P_MUTATION = 0.5
MAX_GENERATIONS = 5
HALL_OF_FAME_SIZE = 3
CROWDING_FACTOR = 10.0

# === Случайность ===
RANDOM_SEED = 42
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

# === Тестовый класс ===
test = mlp_hyperparameters_test.MlpHyperparametersTest(RANDOM_SEED)

# === DEAP настройка ===
toolbox = base.Toolbox()

creator.create("FitnessMax", base.Fitness, weights=(1.0,))
creator.create("Individual", list, fitness=creator.FitnessMax)

# Генераторы атрибутов
for i in range(NUM_OF_PARAMS):
    toolbox.register(
        f"attr_{i}",
        random.uniform,
        BOUNDS_LOW[i],
        BOUNDS_HIGH[i]
    )

# Кортеж генераторов
attributes = tuple(toolbox.__getattribute__(f"attr_{i}") for i in range(NUM_OF_PARAMS))

# Индивидуум и популяция
toolbox.register("individualCreator", tools.initCycle, creator.Individual, attributes, n=1)
toolbox.register("populationCreator", tools.initRepeat, list, toolbox.individualCreator)


# Фитнес
def classificationAccuracy(individual):
    return test.getAccuracy(individual),


toolbox.register("evaluate", classificationAccuracy)

# Генетические операторы
toolbox.register("select", tools.selTournament, tournsize=2)
toolbox.register("mate", tools.cxSimulatedBinaryBounded,
                 low=BOUNDS_LOW, up=BOUNDS_HIGH, eta=CROWDING_FACTOR)
toolbox.register("mutate", tools.mutPolynomialBounded,
                 low=BOUNDS_LOW, up=BOUNDS_HIGH, eta=CROWDING_FACTOR,
                 indpb=1.0 / NUM_OF_PARAMS)


# === Основной поток ===
def main():
    population = toolbox.populationCreator(n=POPULATION_SIZE)

    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("max", np.max)
    stats.register("avg", np.mean)

    hof = tools.HallOfFame(HALL_OF_FAME_SIZE)

    population, logbook = elitism.eaSimpleWithElitism(
        population, toolbox,
        cxpb=P_CROSSOVER, mutpb=P_MUTATION,
        ngen=MAX_GENERATIONS,
        stats=stats, halloffame=hof,
        verbose=True
    )

    # === Вывод лучших ===
    print("\n=== ЛУЧШИЕ РЕШЕНИЯ ===")
    for i, ind in enumerate(hof.items):
        print(f"\n#{i + 1}:")
        print(test.formatParams(ind))
        print(f" → ТОЧНОСТЬ = {ind.fitness.values[0]:.4f}")

    # === График ===
    max_fit, mean_fit = logbook.select("max", "avg")

    sns.set_style("whitegrid")
    plt.figure(figsize=(10, 6))
    plt.plot(max_fit, color='red', label='Максимальная точность', linewidth=2)
    plt.plot(mean_fit, color='green', label='Средняя точность', linewidth=2)
    plt.xlabel('Поколение')
    plt.ylabel('Точность')
    plt.title('Эволюция точности MLP по поколениям')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()
