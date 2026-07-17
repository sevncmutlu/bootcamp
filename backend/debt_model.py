import numpy as np
import pandas as pd
import lightgbm as lgb
import logging

logger = logging.getLogger("maki_debt_model")

class DebtPredictor:
    def __init__(self):
        self.model = None
        self.initialized = False

    def train_model(self):
        try:
            logger.info("Generating synthetic data for LightGBM debt model...")
            np.random.seed(42)
            n_samples = 2000

            # Generate synthetic features
            total_balance = np.random.uniform(1000, 50000, n_samples)
            avg_interest_rate = np.random.uniform(5, 40, n_samples)
            monthly_budget = np.random.uniform(200, 5000, n_samples)
            
            # Ensure min payment is logically smaller than monthly budget and balance
            min_payment = np.random.uniform(20, 1500, n_samples)
            min_payment = np.minimum(min_payment, monthly_budget * 0.8)
            min_payment = np.minimum(min_payment, total_balance * 0.1)

            strategy = np.random.randint(0, 2, n_samples) # 1: avalanche, 0: snowball

            # Ratios
            budget_to_balance_ratio = monthly_budget / total_balance
            min_payment_to_budget_ratio = min_payment / monthly_budget

            # Heuristic for repayment success probability
            # Base probability is 0.4
            # More budget relative to total balance increases success probability
            # High interest rates decrease success probability
            # High minimum payment relative to budget decreases safety margin and success probability
            # Avalanche strategy provides a minor efficiency boost
            p = (
                0.4 
                + 1.5 * budget_to_balance_ratio 
                - 0.008 * avg_interest_rate 
                - 0.3 * min_payment_to_budget_ratio 
                + 0.05 * strategy
            )
            p = np.clip(p, 0.05, 0.95)

            # Generate target label: 1 if success, 0 if fail/default
            y = (np.random.rand(n_samples) < p).astype(int)

            # Build DataFrame
            df = pd.DataFrame({
                "total_balance": total_balance,
                "avg_interest_rate": avg_interest_rate,
                "budget_to_balance_ratio": budget_to_balance_ratio,
                "min_payment_to_budget_ratio": min_payment_to_budget_ratio,
                "strategy": strategy
            })

            # Train LightGBM model
            train_data = lgb.Dataset(df, label=y)
            params = {
                "objective": "binary",
                "metric": "binary_logloss",
                "boosting_type": "gbdt",
                "learning_rate": 0.05,
                "num_leaves": 15,
                "max_depth": 4,
                "verbose": -1,
                "seed": 42
            }
            
            self.model = lgb.train(params, train_data, num_boost_round=100)
            self.initialized = True
            logger.info("LightGBM debt model trained successfully.")
        except Exception as e:
            logger.error(f"Failed to train LightGBM debt model: {e}", exc_info=True)

    def predict_success_probability(
        self, 
        total_balance: float, 
        avg_interest_rate: float, 
        monthly_budget: float, 
        total_min_payment: float, 
        strategy: str
    ) -> float:
        if not self.initialized:
            self.train_model()
        
        if not self.initialized or self.model is None:
            # Fallback heuristic if training failed
            ratio = monthly_budget / total_balance if total_balance > 0 else 1.0
            return min(0.99, max(0.01, 0.5 + ratio - (avg_interest_rate / 100.0)))

        strategy_encoded = 1 if strategy.lower() == 'avalanche' else 0
        budget_to_balance = monthly_budget / total_balance if total_balance > 0 else 0.0
        min_payment_to_budget = total_min_payment / monthly_budget if monthly_budget > 0 else 0.0

        features = pd.DataFrame([{
            "total_balance": total_balance,
            "avg_interest_rate": avg_interest_rate,
            "budget_to_balance_ratio": budget_to_balance,
            "min_payment_to_budget_ratio": min_payment_to_budget,
            "strategy": strategy_encoded
        }])

        pred = self.model.predict(features)
        return float(pred[0])

debt_predictor = DebtPredictor()
