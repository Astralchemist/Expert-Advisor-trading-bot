﻿# Expert-Advisor-trading-bot
# MQL5 Trading Bot - EA Trader

This is an MQL5 trading bot designed for automated trading strategies in MetaTrader 5. The bot is built to identify market conditions and execute trades based on a combination of technical analysis and a risk-reward strategy. It specifically targets **EUR/USD** and **GBP/USD** pairs on the **1-minute timeframe**.

## Features

- **Significant Bearish Zones**: The bot identifies significant bearish zones that occur after a bullish push.
- **Support & Resistance**: The bot detects support and resistance zones based on price action and failure to break key levels.
- **Fair Value Gap (FVG)**: Looks for fair value gaps where no wicks or candles have filled the gap, aligning with nearby resistance zones.
- **MACD Confirmation**: The bot uses the MACD (12, 26, 9) to confirm momentum before executing trades.
- **Risk-Reward Strategy**: The bot aims for a 1:3 risk-reward ratio and automatically moves the stop loss to breakeven once a 1:1 risk-reward is reached.
- **Trade Size Calculation**: Risk management ensures a constant risk of **$50 per trade**.

## Requirements

- **MetaTrader 5** with an active trading account.
- **MQL5 Expert Advisor** (`EA`) file compiled and ready for use.
- **MACD Indicator**: The bot uses the standard MACD with settings (12, 26, 9).

## Installation

1. Download the **`EA-Trader.mq5`** file and place it into the `MQL5/Experts` directory of your MetaTrader 5 installation folder.
   - For example, `C:/Program Files/MetaTrader 5/MQL5/Experts/EA-Trader.mq5`.
   
2. Open MetaTrader 5.
3. In the **Navigator** window, locate the **EA-Trader** under the **Expert Advisors** section.
4. Drag and drop the EA onto the chart you want to trade.
5. Make sure **AutoTrading** is enabled in MetaTrader 5 for the bot to start functioning.

## Usage

Once installed, you can configure the bot by attaching it to any chart. The bot will automatically start scanning for the following conditions:

1. **Bullish push** followed by a **bearish zone**.
2. **Support zone detection**.
3. **Resistance zone failure**.
4. Confirmation from the **MACD** indicator for **buy/sell momentum**.

The bot will place sell limit orders at **supply zones**, aiming for a **1:3 risk-reward ratio**. Once the trade reaches a 1:1 risk-reward, the stop loss will automatically be moved to break even.

## Risk Management

- The bot will calculate trade sizes based on a fixed risk amount of **$50 per trade**.
- Stop loss and take profit are dynamically adjusted based on the price levels identified by the strategy.

## Customization

You can customize various parameters in the bot to fit your trading preferences:

- **Risk Amount**: Modify the amount of risk per trade.
- **MACD Settings**: Adjust the MACD periods to fit your strategy.
- **Timeframe**: The bot is designed to work on the **1-minute timeframe**, but you can modify it for other timeframes.
- **Pairs**: It currently targets EUR/USD and GBP/USD but can be adjusted to other pairs.

## Backtesting

To test the bot on historical data:

1. Open MetaTrader 5 and go to the **Strategy Tester**.
2. Select **EA-Trader** as the Expert Advisor.
3. Choose the trading pair and timeframe (1-minute).
4. Click on **Start** to run the backtest and analyze the results.

## Contributing

Feel free to fork this repository and submit improvements or bug fixes. Open issues if you encounter problems or have suggestions for enhancement.

## License

This project is licensed under the MIT License.


 Author 
- [GitHub Profile](https://github.com/Astralchemist)

