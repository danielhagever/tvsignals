# TVSignals — Chart Analysis & Buy/Sell Signals

A single-file web app that embeds a **TradingView chart** and layers its own
technical-analysis engine on top: multi-timeframe buy/sell signals, support /
resistance, a trade plan, backtesting, and alerts. No backend, no API keys.

> **Run it:** `python3 -m http.server 5197 --directory ~/tvsignals` then open
> http://localhost:5197 — or use the Claude Code preview server named `tvsignals`.

---

## What's real vs. what's pragmatic (read this first)

TradingView has **no official public API** for reading your account, watchlists,
or charts, and no OAuth to register for. So this tool does **not** ask for your
TradingView password or scrape your account. Instead:

| Concern | How it's actually done |
|---|---|
| **Chart + symbol search + "open the graph"** | TradingView's free, ToS-compliant [embeddable widget](https://www.tradingview.com/widget/) (`tv.js`). Click the symbol header to search TradingView's full universe. |
| **Signals / backtest data (crypto)** | [Binance klines](https://binance-docs.github.io/apidocs/) — keyless, CORS-open, all timeframes. |
| **Signals / backtest data (stocks)** | Yahoo Finance chart API via a public CORS proxy. Intraday on all TFs; 4h is resampled from 1h (Yahoo has no native 4h). Proxy can be slow/rate-limited — that's the trade-off for keyless. |
| **Watchlist** | Stored locally (`localStorage`). Add by searching a symbol. |
| **Alerts** | In-app toast + browser `Notification`; re-checks every 60s while the tab is open. |

If you want **account/watchlist sync** or **alerts that fire when the tab is
closed**, you need a small backend — see "Going further" below.

---

## Features

- **Signals chart** (default view) → your candles rendered with `lightweight-charts`,
  overlaid with **green ▲ BUY / red ▼ SELL arrows** at the best entry/exit points,
  plus EMA(50/200) lines and the top support/resistance levels. A tab switches to the
  full **TradingView** chart. The buy/sell arrows mark **momentum reversals** (MACD
  cross, RSI leaving oversold/overbought, Bollinger-band bounce, or Stochastic turn)
  and alternate cleanly entry → exit, so they fire at real turning points even against
  the larger trend. The banner shows the latest trigger and how many fired on this TF.
- **Chart legend** → a floating key on the Signals chart explains every line: EMA 50
  (orange, short-term trend), EMA 200 (blue, long-term trend), last price (gray dashed),
  support/resistance (purple dashed), and the ▲ Buy / ▼ Sell reversal arrows.
- **News & earnings** → a live headline feed for the selected symbol (Yahoo search
  endpoint, keyless — works for stocks and crypto), each headline a clickable source
  link. **Earnings dates** for stocks (next date, EPS estimate, and a "⚠ earnings
  within a week — expect volatility" warning) light up when you paste a free
  **Finnhub API key** in ⚙ Settings (Yahoo's earnings endpoint is now crumb-locked, so
  this is the reliable keyless-by-default path; the key is stored only in your browser).
- **Search any symbol** → TradingView chart loads instantly (crypto or stock toggle).
- **Symbol browser:** sidebar "Popular" groups (crypto: Majors/DeFi/Memes; stocks:
  Mega-cap tech / Semis / Finance / ETFs / Consumer / Energy) + a per-market
  watchlist. Tap to load.
- **Timeframes:** 5m / 15m / 1h / 4h / 1d. Each re-runs the engine.
- **Signal engine** (weighted, *explainable* — every score shows its reasons), now
  using **8 indicators**:
  - Trend: EMA(50) vs EMA(200)
  - **Trend strength: ADX / DMI** (gates the trend score; flags ranging markets)
  - Momentum: RSI(14)
  - **Stochastic(14,3)** overbought/oversold
  - MACD(12,26,9) crosses & histogram
  - Bollinger Bands(20,2) stretch
  - **OBV** volume confirmation
  - **ATR(14)** for volatility-scaled stops
- **My position · smart plan:** enter the price you bought at and get
  risk-managed buy/sell levels — a **sell target 1 & 2** (next resistance above the
  current price, ATR fallback), a **stop-loss** (1.5×ATR below entry, snapped just
  under support), an **add/buy zone** (nearest support below price), your live
  **unrealized P/L**, plan **risk:reward**, and a plain-English verdict that also
  reacts to the live engine signal (e.g. "up 3.9% & engine flipped SELL — take
  profit toward …"). Entry persists per symbol. Levels are derived from volatility
  and real support/resistance, never fixed percentages.
- **Multi-timeframe confluence:** all 5 TFs scored and weight-blended (higher TF =
  more weight); shows % agreement.
- **Scanner:** rank your whole watchlist by signal score on the current TF in one
  click — surfaces the strongest BUY/SELL setups across many symbols. Click a row to load it.
- **Support / resistance:** swing-pivot clustering weighted by touch count.
- **Trade plan:** entry, **ATR-based stop** (max of 1.5×ATR / swing low), 2R target,
  risk:reward, and the symbol's current volatility.
- **Backtester:** long/flat replay with ATR stop + target on the selected TF →
  trades, win rate, total return, avg R:R, and an equity sparkline.
- **Custom alerts:** build any number of rules per symbol — signal flips, turns
  BUY/SELL, price above/below, RSI above/below, or score above/below. Master toggle
  arms them; the engine re-checks every symbol with a rule every 60s while open
  (in-app toast + browser notification, with re-arm debounce so they don't spam).
- **Settings:** tune RSI length, EMA pair, and the signal threshold live.
- **Responsive:** sidebar collapses under ~1100px.

---

## How the signal score works

`signalAt()` scores the latest bar from **−100 (strong sell)** to **+100 (strong buy)**:

| Condition | Score |
|---|---|
| EMA50 > EMA200 (uptrend) | +22 / −22 |
| ADX > 25 with +DI/−DI direction (strong trend) | +12 / −12 (ADX < 20 → flagged "ranging") |
| RSI < 30 / > 70 | +18 / −18 |
| Stochastic < 20 / > 80 | +10 / −10 |
| MACD bullish / bearish cross | +18 / −18 (±7 if just histogram sign) |
| Close below / above Bollinger band | +13 / −13 |
| OBV above / below its SMA(20) (volume confirms) | +8 / −8 |

`action = BUY` if score ≥ threshold, `SELL` if ≤ −threshold, else `HOLD`
(threshold default 40, adjustable). Multi-timeframe confluence blends each TF's
score by weight `{5m:.5, 15m:.8, 1h:1, 4h:1.5, 1d:2}`.

The whole engine is **pure functions** (`indicators` + `signalAt`), so the live
panel and the backtester run identical logic — what you see is what gets tested.

---

## Code map (`index.html`, one file)

```
DATA LAYER      fetchCandles()      Binance (crypto) / Yahoo+proxy (stock)
INDICATORS      sma ema rsi macd bollinger pivotLevels
SIGNAL ENGINE   precompute() → signalAt()      multiTimeframe() + confluence()
BACKTESTER      backtest()
TV WIDGET       loadChart()
UI              renderWatchlist() paintSignal() drawEquity()
ORCHESTRATION   analyze() selectSymbol()
ALERTS          notify() toggleAlerts()
```

---

## Interpreting results (and a caution)

- A high-confluence **BUY** with agreement ≥ 80% across TFs is the strongest setup;
  conflicting TFs (low agreement) mean "wait."
- Always sanity-check the **backtest** on that symbol/TF before trusting a signal —
  a strategy that loses on history is a red flag, not a green light.
- This is an **educational tool, not financial advice.** Indicator-based signals
  lag, whipsaw in chop, and don't know about news or fundamentals. Size positions
  and manage risk yourself.

---

## Going further (optional backend)

To make it a product rather than a personal tool, add a small server
(Cloudflare Workers fits your stack):

- **Real watchlist sync** via the unofficial TradingView WebSocket (`@mathieuc/tradingview`) —
  works, but violates TradingView ToS and is fragile; flag it clearly.
- **Receive TradingView Pine alerts** through a webhook endpoint (the *sanctioned*
  integration path) and surface them in the panel.
- **Server-side alert evaluation** so alerts fire when no tab is open
  (Workers Cron → email/SMS/push).
- **Encrypt any TradingView session secret at rest** (AES-GCM, key in Worker
  secret store) — never put it in the browser.

---

## Limitations

- Stock data depends on a public CORS proxy → occasional slowness / rate limits.
- Yahoo has no native 4h; it's resampled from 1h.
- Alerts only run while the tab is open.
- No order execution — by design. This tool never trades.
