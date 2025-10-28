from pandas import read_csv
from sklearn import model_selection
from sklearn.ensemble import AdaBoostClassifier


class HyperparameterTuningGenetic:
    """Генетическая настройка гиперпараметров AdaBoost (Wine, локальный файл)"""

    NUM_FOLDS = 5  # количество фолдов кросс‑валидации

    def __init__(self, randomSeed):
        """
        :param randomSeed: фиксированное зерно для воспроизводимости
        """
        self.randomSeed = randomSeed
        self._load_wine_dataset()
        self._init_kfold()

    # ------------------------------------------------------------------ #
    #  Загрузка датасета
    # ------------------------------------------------------------------ #
    def _load_wine_dataset(self):
        """Читает wine.data из текущей папки."""
        file_path = 'wine.data'  # <-- файл в той же директории
        data = read_csv(file_path, header=None)

        # столбец 0 – класс, остальные – признаки
        self.X = data.iloc[:, 1:].values  # numpy‑массив признаков
        self.y = data.iloc[:, 0].values  # numpy‑массив меток

    # ------------------------------------------------------------------ #
    #  KFold
    # ------------------------------------------------------------------ #
    def _init_kfold(self):
        self.kfold = model_selection.KFold(
            n_splits=self.NUM_FOLDS,
            random_state=self.randomSeed,
            shuffle=True  # обязательно перемешиваем
        )

    # ------------------------------------------------------------------ #
    #  Преобразование генов → параметры AdaBoost
    # ------------------------------------------------------------------ #
    def _convert_params(self, params):
        """
        params = [n_estimators, learning_rate, algorithm_index]
        algorithm_index теперь игнорируется (оставлен только SAMME)
        """
        n_estimators = int(round(params[0]))  # 1 … 100 → целое
        learning_rate = float(params[1])  # 0.01 … 1.00
        return n_estimators, learning_rate

    # ------------------------------------------------------------------ #
    #  Оценка точности
    # ------------------------------------------------------------------ #
    def getAccuracy(self, params):
        """
        :param params: список из 3 чисел (хромосома)
        :return: средняя точность (float)
        """
        n_estimators, learning_rate = self._convert_params(params)

        clf = AdaBoostClassifier(
            n_estimators=n_estimators,
            learning_rate=learning_rate,
            # algorithm='SAMME'   # можно явно указать, но необязательно
            random_state=self.randomSeed
        )

        scores = model_selection.cross_val_score(
            clf, self.X, self.y,
            cv=self.kfold,
            scoring='accuracy'
        )
        return scores.mean()

    def formatParams(self, params):
        n_estimators, learning_rate = self._convert_params(params)
        return (f"n_estimators={n_estimators}, "
                f"learning_rate={learning_rate:.4f}, "
                f"algorithm='SAMME'")
