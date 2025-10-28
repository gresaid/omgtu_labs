import math

from sklearn import datasets
from sklearn import model_selection
from sklearn.exceptions import ConvergenceWarning
from sklearn.neural_network import MLPClassifier
from sklearn.utils._testing import ignore_warnings


class MlpHyperparametersTest:
    """
    Класс для оценки точности MLP с настройкой всех основных гиперпараметров.
    Датасет: Iris (встроен в sklearn).
    """

    NUM_FOLDS = 5  # количество фолдов кросс-валидации

    # ------------------------------------------------------------------
    # Инициализация
    # ------------------------------------------------------------------
    def __init__(self, randomSeed: int):
        """
        :param randomSeed: фиксированное зерно для воспроизводимости
        """
        self.randomSeed = randomSeed
        self._load_iris()
        self._init_kfold()

    # ------------------------------------------------------------------
    # Загрузка датасета
    # ------------------------------------------------------------------
    def _load_iris(self):
        """Iris: 150 образцов, 4 признака, 3 класса."""
        iris = datasets.load_wine()
        self.X = iris.data
        self.y = iris.target

    # ------------------------------------------------------------------
    # KFold
    # ------------------------------------------------------------------
    def _init_kfold(self):
        self.kfold = model_selection.KFold(
            n_splits=self.NUM_FOLDS,
            random_state=self.randomSeed,
            shuffle=True  # обязательно перемешиваем
        )

    # ------------------------------------------------------------------
    # Преобразование генов → параметры MLP
    # ------------------------------------------------------------------
    def _convert_params(self, params):
        """
        params = [
            size1, size2, size3, size4,
            act_idx, solver_idx, alpha, lr_idx
        ]
        """
        # --- Скрытые слои (только положительные) ---
        sizes = []
        for i in range(4):
            sz = int(round(params[i]))
            if sz > 0:
                sizes.append(sz)
            else:
                break
        if not sizes:
            sizes = [5]  # минимум один слой
        hidden_layer_sizes = tuple(sizes)

        # --- Категориальные параметры ---
        activation = ['tanh', 'relu', 'logistic'][int(math.floor(params[4]))]
        solver = ['sgd', 'adam', 'lbfgs'][int(math.floor(params[5]))]
        alpha = float(params[6])
        learning_rate = ['constant', 'invscaling', 'adaptive'][int(math.floor(params[7]))]

        return hidden_layer_sizes, activation, solver, alpha, learning_rate

    # ------------------------------------------------------------------
    # Оценка точности (с подавлением предупреждений о сходимости)
    # ------------------------------------------------------------------
    @ignore_warnings(category=ConvergenceWarning)
    def getAccuracy(self, params):
        """
        :param params: список из 8 чисел (хромосома)
        :return: средняя точность (float)
        """
        hidden_layer_sizes, activation, solver, alpha, learning_rate = self._convert_params(params)

        mlp = MLPClassifier(
            hidden_layer_sizes=hidden_layer_sizes,
            activation=activation,
            solver=solver,
            alpha=alpha,
            learning_rate=learning_rate,
            max_iter=1000,
            random_state=self.randomSeed,
            early_stopping=True,
            n_iter_no_change=15,
            tol=1e-4
        )

        scores = model_selection.cross_val_score(
            mlp, self.X, self.y,
            cv=self.kfold,
            scoring='accuracy'
        )
        return scores.mean()

    # ------------------------------------------------------------------
    # Форматированный вывод
    # ------------------------------------------------------------------
    def formatParams(self, params):
        hidden_layer_sizes, activation, solver, alpha, learning_rate = self._convert_params(params)
        return (
            f"hidden_layer_sizes={hidden_layer_sizes}\n"
            f"activation='{activation}'\n"
            f"solver='{solver}'\n"
            f"alpha={alpha:.6f}\n"
            f"learning_rate='{learning_rate}'"
        )
