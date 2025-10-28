import numpy as np

from deap import base
from deap import creator
from deap import tools

# константы:
DIMENSIONS = 2  # количество измерений
POPULATION_SIZE = 20  # размер популяции
MAX_GENERATIONS = 500  # максимальное количество поколений
MIN_START_POSITION, MAX_START_POSITION = -5, 5  # начальные границы позиции
MIN_SPEED, MAX_SPEED = -3, 3  # границы скорости
MAX_LOCAL_UPDATE_FACTOR = MAX_GLOBAL_UPDATE_FACTOR = 2.0  # максимальные факторы обновления

# установка начального значения генератора случайных чисел:
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

toolbox = base.Toolbox()

# определение стратегии минимизации с одним целевым значением:
creator.create("FitnessMin", base.Fitness, weights=(-1.0,))

# определение класса частицы на основе ndarray:
creator.create("Particle", np.ndarray, fitness=creator.FitnessMin, speed=None, best=None)


# создание и инициализация новой частицы:
def createParticle():
    particle = creator.Particle(np.random.uniform(MIN_START_POSITION,
                                                  MAX_START_POSITION,
                                                  DIMENSIONS))
    particle.speed = np.random.uniform(MIN_SPEED, MAX_SPEED, DIMENSIONS)
    return particle


# создание оператора 'particleCreator' для заполнения экземпляра частицы:
toolbox.register("particleCreator", createParticle)

# создание оператора 'population' для генерации списка частиц:
toolbox.register("populationCreator", tools.initRepeat, list, toolbox.particleCreator)


# обновление частицы:
def updateParticle(particle, best):
    # создание случайных факторов:
    localUpdateFactor = np.random.uniform(0, MAX_LOCAL_UPDATE_FACTOR, particle.size)
    globalUpdateFactor = np.random.uniform(0, MAX_GLOBAL_UPDATE_FACTOR, particle.size)

    # вычисление локального и глобального обновления скорости:
    localSpeedUpdate = localUpdateFactor * (particle.best - particle)
    globalSpeedUpdate = globalUpdateFactor * (best - particle)

    # вычисление обновленной скорости:
    particle.speed = particle.speed + (localSpeedUpdate + globalSpeedUpdate)

    # ограничение обновленной скорости:
    particle.speed = np.clip(particle.speed, MIN_SPEED, MAX_SPEED)

    # обновление позиции частицы:
    particle[:] = particle + particle.speed


toolbox.register("update", updateParticle)


# функция Химмельблау:
def himmelblau(particle):
    x = particle[0]
    y = particle[1]
    f = (x ** 2 + y - 11) ** 2 + (x + y ** 2 - 7) ** 2
    return f,  # возвращает кортеж


toolbox.register("evaluate", himmelblau)


# основной поток алгоритма:
def main():
    # создание популяции частиц:
    population = toolbox.populationCreator(n=POPULATION_SIZE)

    # подготовка объекта статистики:
    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("min", np.min)  # минимальная фитнес-оценка
    stats.register("avg", np.mean)  # средняя фитнес-оценка

    logbook = tools.Logbook()
    logbook.header = ["поколение", "оценки"] + stats.fields

    best = None

    for generation in range(MAX_GENERATIONS):
        # оценка всех частиц в популяции:
        for particle in population:
            # определение фитнес-оценки частицы:
            particle.fitness.values = toolbox.evaluate(particle)

            # обновление лучшей позиции частицы:
            if particle.best is None or particle.best.size == 0 or particle.best.fitness < particle.fitness:
                particle.best = creator.Particle(particle)
                particle.best.fitness.values = particle.fitness.values

            # обновление глобальной лучшей позиции:
            if best is None or best.size == 0 or best.fitness < particle.fitness:
                best = creator.Particle(particle)
                best.fitness.values = particle.fitness.values

        # обновление скорости и позиции каждой частицы:
        for particle in population:
            toolbox.update(particle, best)

        # запись статистики для текущего поколения и вывод:
        logbook.record(gen=generation, evals=len(population), **stats.compile(population))
        print(logbook.stream)

    # вывод информации о лучшем найденном решении:
    print("-- Лучшая частица = ", best)
    print("-- Лучшая фитнес-оценка = ", best.fitness.values[0])


if __name__ == "__main__":
    main()
