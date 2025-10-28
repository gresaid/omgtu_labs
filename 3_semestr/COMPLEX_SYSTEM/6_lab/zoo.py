from pandas import read_csv
from sklearn import model_selection
from sklearn.tree import DecisionTreeClassifier


class Zoo:
    """Класс, инкапсулирующий тест Zoo для классификатора"""

    DATASET_PATH = 'zoo.data'  # путь к локальному файлу
    NUM_FOLDS = 5  # количество фолдов для кросс-валидации

    def __init__(self, randomSeed):
        """
        :param randomSeed: начальное значение для воспроизводимых результатов
        """
        self.randomSeed = randomSeed

        # чтение датасета, пропуская первый столбец (название животного):
        self.data = read_csv(self.DATASET_PATH, header=None, usecols=range(1, 18))

        # разделение на входные признаки и результирующую категорию (последний столбец):
        self.X = self.data.iloc[:, 0:16]
        self.y = self.data.iloc[:, 16]

        # разделение данных на группы для кросс-валидации:
        self.kfold = model_selection.KFold(n_splits=self.NUM_FOLDS, random_state=self.randomSeed, shuffle=True)

        self.classifier = DecisionTreeClassifier(random_state=self.randomSeed)

    def __len__(self):
        """
        :return: общее количество признаков, используемых в задаче классификации
        """
        return self.X.shape[1]

    def getMeanAccuracy(self, zeroOneList):
        """
        Возвращает среднюю точность классификатора, рассчитанную с помощью кросс-валидации,
        используя признаки, выбранные zeroOneList
        :param zeroOneList: список бинарных значений, соответствующих признакам в датасете.
        Значение '1' означает выбор признака, '0' — исключение признака.
        :return: средняя точность классификатора при использовании выбранных признаков
        """
        # удаление столбцов датасета, соответствующих невыбранным признакам:
        zeroIndices = [i for i, n in enumerate(zeroOneList) if n == 0]
        currentX = self.X.drop(self.X.columns[zeroIndices], axis=1)

        # выполнение кросс-валидации и определение точности классификатора:
        cv_results = model_selection.cross_val_score(self.classifier, currentX, self.y, cv=self.kfold,
                                                     scoring='accuracy')

        # возврат средней точности:
        return cv_results.mean()


# тестирование класса:
def main():
    # создание экземпляра задачи:
    zoo = Zoo(randomSeed=42)

    allOnes = [1] * len(zoo)
    print("-- Все признаки выбраны: ", allOnes, ", точность = ", zoo.getMeanAccuracy(allOnes))


if __name__ == "__main__":
    main()
