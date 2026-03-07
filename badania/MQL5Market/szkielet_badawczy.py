from datetime import datetime, timezone
import numpy as np
import pandas as pd
import MetaTrader5 as mt5

SYMBOL = "UHG"
TIMEFRAME = mt5.TIMEFRAME_H1
BARS = 5000

def load_rates(symbol: str, timeframe: int, bars: int) -> pd.DataFrame:
    if not mt5.initialize():
        raise RuntimeError(f"MT5 initialize failed: {mt5.last_error()}")
    try:
        rates = mt5.copy_rates_from_pos(symbol, timeframe, 0, bars)
        if rates is None:
            raise RuntimeError(f"copy_rates_from_pos failed: {mt5.last_error()}")
        df = pd.DataFrame(rates)
        df["time"] = pd.to_datetime(df["time"], unit="s", utc=True)
        return df
    finally:
        mt5.shutdown()

def detect_anchor_regime(df: pd.DataFrame, window: int = 50) -> pd.DataFrame:
    out = df.copy()
    out["ret"] = out["close"].pct_change()
    out["vol"] = out["ret"].rolling(window).std()
    out["range_pct"] = (out["high"] - out["low"]) / out["close"].replace(0, np.nan)
    out["anchor_score"] = (
        (out["vol"].rolling(window).mean().fillna(0) < 0.03).astype(int)
        + (out["range_pct"].rolling(window).mean().fillna(0) < 0.04).astype(int)
    )
    out["is_anchor_regime"] = out["anchor_score"] >= 2
    return out

def implied_p(price: float, deal_price: float, fallback: float) -> float:
    denom = (deal_price - fallback)
    if denom <= 0:
        raise ValueError("deal_price must be greater than fallback")
    p = (price - fallback) / denom
    return float(np.clip(p, 0.0, 1.0))

def monte_carlo_binary(
    p0: float,
    deal_price: float,
    fallback: float,
    sigma_eps: float = 0.01,
    n_paths: int = 100_000,
    seed: int = 20260307
) -> np.ndarray:
    rng = np.random.default_rng(seed)
    close_event = rng.random(n_paths) < p0
    noise = rng.normal(0.0, sigma_eps, n_paths)
    terminal = np.where(close_event, deal_price, fallback) + noise
    return terminal

if __name__ == "__main__":
    df = load_rates(SYMBOL, TIMEFRAME, BARS)
    df = detect_anchor_regime(df)

    last_price = float(df["close"].iloc[-1])
    p = implied_p(price=last_price, deal_price=1.18, fallback=0.70)
    terminal = monte_carlo_binary(p0=p, deal_price=1.18, fallback=0.70)

    print("Last price:", last_price)
    print("Implied p:", round(p, 4))
    print("MC quantiles:", np.quantile(terminal, [0.01, 0.05, 0.5, 0.95, 0.99]))