from sklearn import datasets
from sklearn import model_selection
from sklearn.neural_network import MLPClassifier


class MlpLayersTest:
    """
    Класс для оценки точности MLP с произвольным числом скрытых слоёв.
    Датасет — Iris (встроен в sklearn).
    """

    NUM_FOLDS = 5  # количество фолдов кросс‑валидации

    # ------------------------------------------------------------------
    #  Инициализация
    # ------------------------------------------------------------------
    def __init__(self, randomSeed: int):
        """
        :param randomSeed: фиксированное зерно для воспроизводимости
        """
        self.randomSeed = randomSeed
        self._load_iris()
        self._init_kfold()

    # ------------------------------------------------------------------
    #  Загрузка датасета
    # ------------------------------------------------------------------
    def _load_iris(self):
        """Iris – 150 образцов, 4 признака, 3 класса."""
        iris = datasets.load_iris()
        self.X = iris.data  # (150, 4)
        self.y = iris.target  # (150,)

    # ------------------------------------------------------------------
    #  KFold
    # ------------------------------------------------------------------
    def _init_kfold(self):
        self.kfold = model_selection.KFold(
            n_splits=self.NUM_FOLDS,
            random_state=self.randomSeed,
            shuffle=True  # перемешиваем, иначе кросс‑валидация будет «зашумлена»
        )

    # ------------------------------------------------------------------
    #  Преобразование генов → tuple размеров слоёв
    # ------------------------------------------------------------------
    def _convert_params(self, params):
        """
        params = [size_1, size_2, size_3, size_4]  (float, могут быть отрицательными)

        Возвращает кортеж (int, …) только тех слоёв, у которых size > 0.
        """
        sizes = []
        for p in params:
            sz = int(round(p))
            if sz > 0:  # только положительные размеры
                sizes.append(sz)
            else:
                break  # как только встретили ≤0 — дальше слои отбрасываем
        # минимум один слой (иначе MLP не создастся)
        if not sizes:
            sizes = [5]  # «защита от пустой сети»
        return tuple(sizes)

    # ------------------------------------------------------------------
    #  Оценка точности
    # ------------------------------------------------------------------
    def getAccuracy(self, params):
        """
        :param params: список из 4 вещественных чисел (хромосома)
        :return: средняя точность (float)
        """
        hidden_layer_sizes = self._convert_params(params)

        mlp = MLPClassifier(
            hidden_layer_sizes=hidden_layer_sizes,
            max_iter=1000,  # достаточно итераций
            random_state=self.randomSeed,
            early_stopping=True,
            n_iter_no_change=10,
            tol=1e-4
        )

        scores = model_selection.cross_val_score(
            mlp, self.X, self.y,
            cv=self.kfold,
            scoring='accuracy'
        )
        return scores.mean()

    # ------------------------------------------------------------------
    #  Форматированный вывод
    # ------------------------------------------------------------------
    def formatParams(self, params):
        """
        :return: строка вида  hidden_layer_sizes=(12, 8, 3)
        """
        return f"hidden_layer_sizes={self._convert_params(params)}"
