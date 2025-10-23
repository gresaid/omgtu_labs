from deap import base
from deap import creator
from deap import tools

import random
import numpy

import matplotlib.pyplot as plt
import seaborn as sns

import zoo
import elitism

# константы генетического алгоритма:
POPULATION_SIZE = 50  # размер популяции
P_CROSSOVER = 0.9  # вероятность кроссовера
P_MUTATION = 0.2  # вероятность мутации индивидуума
MAX_GENERATIONS = 50  # максимальное количество поколений
HALL_OF_FAME_SIZE = 5  # размер зала славы

FEATURE_PENALTY_FACTOR = 0.001  # коэффициент штрафа за использование признаков

# установка начального значения генератора случайных чисел:
RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# создание тестового класса Zoo率先
zoo = zoo.Zoo(RANDOM_SEED)

toolbox = base.Toolbox()

# определение стратегии максимизации с одним целевым значением:
creator.create("FitnessMax", base.Fitness, weights=(1.0,))

# создание класса Individual на основе списка:
creator.create("Individual", list, fitness=creator.FitnessMax)

# создание оператора, возвращающего случайное 0 или 1:
toolbox.register("zeroOrOne", random.randint, 0, 1)

# создание оператора для заполнения экземпляра Individual:
toolbox.register("individualCreator", tools.initRepeat, creator.Individual, toolbox.zeroOrOne, len(zoo))

# создание оператора популяции для генерации списка индивидуумов:
toolbox.register("populationCreator", tools.initRepeat, list, toolbox.individualCreator)

# вычисление фитнес-оценки:
def zooClassificationAccuracy(individual):
    numFeaturesUsed = sum(individual)
    if numFeaturesUsed == 0:
        return 0.0,
    else:
        accuracy = zoo.getMeanAccuracy(individual)
        return accuracy - FEATURE_PENALTY_FACTOR * numFeaturesUsed,  # возвращает кортеж

toolbox.register("evaluate", zooClassificationAccuracy)

# генетические операторы:

# турнирный отбор с размером турнира 2:
toolbox.register("select", tools.selTournament, tournsize=2)

# двухточечный кроссовер:
toolbox.register("mate", tools.cxTwoPoint)

# мутация переключения бита:
# indpb: независимая вероятность переключения каждого атрибута
toolbox.register("mutate", tools.mutFlipBit, indpb=1.0/len(zoo))

# поток генетического алгоритма:
def main():
    # создание начальной популяции (поколение 0):
    population = toolbox.populationCreator(n=POPULATION_SIZE)

    # подготовка объекта статистики:
    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("max", numpy.max)  # максимальная фитнес-оценка
    stats.register("avg", numpy.mean)  # средняя фитнес-оценка

    # определение объекта зала славы:
    hof = tools.HallOfFame(HALL_OF_FAME_SIZE)

    # выполнение потока генетического алгоритма с добавлением зала славы:
    population, logbook = elitism.eaSimpleWithElitism(population, toolbox, cxpb=P_CROSSOVER, mutpb=P_MUTATION,
                                                      ngen=MAX_GENERATIONS, stats=stats, halloffame=hof, verbose=True)

    # вывод лучших найденных решений:
    print("- Лучшие решения:")
    for i in range(HALL_OF_FAME_SIZE):
        print(i, ": ", hof.items[i], ", фитнес-оценка = ", hof.items[i].fitness.values[0],
              ", точность = ", zoo.getMeanAccuracy(hof.items[i]), ", признаки = ", sum(hof.items[i]))

    # извлечение статистики:
    maxFitnessValues, meanFitnessValues = logbook.select("max", "avg")

    # построение графика статистики:
    sns.set_style("whitegrid")
    plt.plot(maxFitnessValues, color='red')
    plt.plot(meanFitnessValues, color='green')
    plt.xlabel('Поколение')
    plt.ylabel('Максимальная / Средняя фитнес-оценка')
    plt.title('Максимальная и средняя фитнес-оценка по поколениям')
    plt.show()

if __name__ == "__main__":
    main()