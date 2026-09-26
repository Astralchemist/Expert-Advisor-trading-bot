# Expert Advisor Trading Bot

An MQL5 Expert Advisor that places sell limit orders at resistance on the 1-minute chart, with fixed-risk position sizing, a daily loss limit and break-even stop management, plus Python helper scripts for connecting to MetaTrader 5.

## 🚀 Key Features

### Trading Logic
- **MACD Analysis**: Uses an `iMACD` indicator handle (12, 26, 9)
- **Fractal-Based Support/Resistance**: Swing highs and lows over the last `LookbackPeriod` candles, ranked by how often price touched them
- **Fair Value Gap Check**: The low two candles back and the current candle's high must straddle the resistance level
- **Fixed Timeframe**: All analysis runs on M1; the timeframe is fixed in the code

### Risk Management
- **Position Sizing**: Lot size from `RiskAmount` and the stop distance, capped at 5% of account equity
- **Daily Loss Limit**: Trading halts and open positions are closed when equity falls `MaxDailyLoss` below the start-of-day equity; open losses count. Resets each server day and survives EA restarts.
- **Spread Filter**: Skips signals when the spread is above 0.0003 in price, 3 pips on EURUSD/GBPUSD (fixed in the code)
- **Breakeven Management**: Moves the stop loss to entry at 1:1 R:R
- **Risk Cap**: Maximum 5% account risk per trade (fixed in the code)

### Technical Details
- **Error Logging**: Indicator, price data and order errors are logged
- **Modern MQL5 Syntax**: Uses current MetaTrader 5 functions and structures
- **Input Validation**: Risk, loss limit, R:R and pending expiry inputs are checked on start
- **Memory Management**: Indicator handle released on shutdown

## 📊 Trading Strategy

### Signal Generation
- **Bearish Reversal Detection**: At least 3 bullish candles 5 to 8 bars back, then a bearish current candle with a body over 1.5× the average of the previous 5
- **Fractal Support/Resistance**: Levels touched most often within the lookback window
- **Fair Value Gap Check**: Price range across the last three candles spans the resistance level
- **MACD Confluence**: MACD main line crosses below the signal line on the current bar while falling

### Execution Logic
- **Sell Limit Orders**: Placed at the resistance level
- **Risk-Reward**: Take profit at `MinRiskReward` × the entry-to-support distance (default 1:2)
- **Spread Validation**: Spread checked before each signal
- **Duplicate Prevention**: One open position or one resting sell limit at a time, a 60-second cooldown, and unfilled sell limits cancelled after `PendingExpiryMinutes`

### Position Management
- **Breakeven Automation**: Stop loss moved to entry when the trade reaches 1:1 R:R

## 🛠️ Requirements

### Software Requirements
- **MetaTrader 5** (Build 3340 or higher recommended)
- **Python 3.8+** (for auxiliary scripts and analysis)
- **MetaTrader5 Python package** (`pip install MetaTrader5`)

### Account Requirements
- Active MetaTrader 5 trading account
- Algorithmic trading enabled
- Sufficient margin for position sizing

### System Requirements
- Windows 10/11 (64-bit recommended)
- Stable internet connection
- Minimum 4GB RAM
- 1GB free disk space

## 📦 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/Astralchemist/Expert-Advisor-trading-bot.git
cd Expert-Advisor-trading-bot
```

### 2. Install Python Dependencies
```bash
pip install MetaTrader5
```

### 3. Setup MetaTrader 5 Expert Advisor
1. Copy `bot.mq5` to your MetaTrader 5 Experts folder:
   - Default path: `C:/Users/{Username}/AppData/Roaming/MetaQuotes/Terminal/{TerminalID}/MQL5/Experts/`
   - Alternative: `C:/Program Files/MetaTrader 5/MQL5/Experts/`

2. Compile the Expert Advisor in MetaEditor (F7)

3. Attach to chart:
   - Open MetaTrader 5
   - Navigate to Navigator → Expert Advisors
   - Drag `bot` onto your desired chart
   - Configure input parameters
   - Enable AutoTrading (Ctrl+E)

### 4. Configuration
1. Set the EA's input parameters when attaching it to the chart (the EA does not read `config.json`)
2. `config.json` is used only by the Python scripts; run `python config_manager.py` to validate it
3. Test connection with `python init-test.py`

## 🎯 Usage

### Quick Start
1. **Initialize Connection**: Run `python mt5-init.py` to establish MT5 connection
2. **Verify Account**: Run `python account-info.py` to check account status
3. **Test Functionality**: Run `python test-function.py` to test order placement. **This places real market orders (a BUY on EURUSD and a SELL on GBPUSD) on whichever account is logged in. Use a demo account.**
4. **Attach EA**: Add Expert Advisor to your trading chart

### Expert Advisor Parameters
| Parameter | Default | Description |
|-----------|---------|-------------|
| RiskAmount | 50.0 | Risk per trade in account currency |
| MaxDailyLoss | 200.0 | Maximum daily loss limit |
| LookbackPeriod | 20 | Candles for S/R analysis |
| MinRiskReward | 2.0 | Minimum risk:reward ratio |
| MagicNumber | 234567 | Unique EA identifier |
| EnableLogging | true | Enable detailed logging |
| PendingExpiryMinutes | 30 | Cancel unfilled sell limits after this many minutes |
| MaxDrawdownPercent | 15.0 | Stop for good if equity falls this % below its peak |

### Trading Conditions
The bot scans for:
1. **Bullish momentum** followed by **bearish reversal**
2. **Fractal support/resistance** levels with multiple touches
3. **Fair value gaps** aligned with key price levels
4. **MACD confirmation** with momentum and signal crossover
5. **Acceptable spread** conditions

### Order Execution
- Places **sell limit orders** at identified supply zones
- Implements **dynamic stop loss** and **take profit** levels
- Automatically moves SL to **breakeven** at 1:1 R:R
- Monitors and manages positions until closure

## ⚠️ Risk Management

### Position Sizing
- **Lot Calculation**: Based on `RiskAmount` and the stop distance
- **Maximum Risk**: 5% of account equity per trade (fixed in the code)
- **Minimum/Maximum Lots**: Respects broker limitations

### Loss Protection
- **Daily Loss Limit**: When the day's loss on equity, open trades included, reaches `MaxDailyLoss`, trading halts, open positions are closed and resting sell limits are cancelled
- **Drawdown Kill Switch**: When equity falls `MaxDrawdownPercent` below its highest point, the EA closes its positions, cancels its sell limits and stops trading for good. It stays stopped across restarts and new days. Withdrawals lower equity too, so they count toward the drawdown.
- **Spread Monitoring**: Spread checked before each signal
- **Error Handling**: Failed orders and data errors are logged

### Resetting the Kill Switch
The kill switch only resets by hand. In MetaTrader 5 open Tools → Global Variables (F3) and delete both `EA_<login>_<symbol>_<magic>_KillSwitch` and `EA_<login>_<symbol>_<magic>_PeakEquity`, then restart the EA. Deleting only the first one trips it again straight away, because the old peak is still stored.

### Trade Management
- **Breakeven Automation**: SL moved to entry when 1:1 R:R achieved
- **Risk-Reward Validation**: Ensures minimum R:R before execution
- **Duplicate Prevention**: One open position or resting sell limit at a time

## ⚙️ Customization

### Configuration File (`config.json`)
```json
{
  "trading": {
    "risk_amount": 50.0,
    "max_daily_loss": 200.0,
    "min_risk_reward": 2.0,
    "max_spread_pips": 3.0
  },
  "analysis": {
    "lookback_period": 20,
    "macd_fast": 12,
    "macd_slow": 26,
    "macd_signal": 9
  },
  "symbols": [
    {
      "name": "EURUSD",
      "enabled": true,
      "max_spread": 0.0003
    }
  ]
}
```

### Python Configuration Manager
```python
from config_manager import ConfigManager

config = ConfigManager()
config.set('trading.risk_amount', 75.0)
config.save_config()
```

### Supported Customizations
The EA is configured through its input parameters only (see the table above). MACD periods, timeframe, maximum spread and the 5% risk cap are fixed in `bot.mq5`. The symbol, timeframe and indicator fields in `config.json` are read by the Python scripts, not the EA.

## 📈 Testing & Validation

### Strategy Tester (MT5)
1. Open MetaTrader 5 Strategy Tester (Ctrl+R)
2. Select Expert Advisor: `bot`
3. Configure test parameters:
   - Symbol: EURUSD or GBPUSD
   - Timeframe: M1
   - Date range: Sufficient historical data
   - Model: Every tick based on real ticks (most accurate for limit order fills)
4. Set input parameters matching your live configuration
5. Run backtest and analyze results

### Python Testing Scripts
```bash
# Test MT5 connection
python init-test.py

# Verify account information
python account-info.py

# Test order functionality (places real orders, use a demo account)
python test-function.py

# Validate configuration
python config_manager.py
```

### Performance Metrics
- **Profit Factor**: Target > 1.3
- **Maximum Drawdown**: Keep < 20%
- **Win Rate**: Aim for > 40%
- **Risk-Reward**: Maintain configured minimum R:R
- **Sharpe Ratio**: Target > 1.0

## 📁 File Structure

```
Expert-Advisor-trading-bot/
├── bot.mq5                 # Main Expert Advisor (MQL5)
├── config.json             # Configuration settings
├── config_manager.py       # Python configuration manager
├── mt5-init.py            # MT5 connection initializer
├── account-info.py        # Account information display
├── test-function.py       # Order testing utilities
├── init-test.py           # Connection testing suite
└── README.md              # Documentation
```

## 🐛 Troubleshooting

### Common Issues

**Connection Problems**
- Ensure MetaTrader 5 is running and logged in
- Check algorithmic trading is enabled
- Run `python init-test.py` for diagnostics

**Trading Issues**
- Check account permissions and margin
- Verify spread conditions
- Review EA logs in MT5 Experts tab
- Validate configuration with `config_manager.py`

**Performance Issues**
- Monitor system resources
- Check internet connection stability
- Review log files for errors
- Adjust lookback periods if needed

## 🔒 Security Features

- **Input Validation**: Key inputs validated on start
- **Error Handling**: Order and data errors logged
- **No DLL Imports**: The EA uses only built-in MQL5 functions

## 📊 Monitoring

- EA activity, orders and errors are logged to the MT5 Experts tab when `EnableLogging` is on
- `python account-info.py` prints account balance, equity and margin status

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Development Guidelines
- Follow defensive security practices
- Add comprehensive error handling
- Include input validation
- Update documentation
- Test thoroughly before submission

## ⚖️ Disclaimer

**RISK WARNING**: Trading forex involves substantial risk and may not be suitable for all investors. Past performance does not guarantee future results. This software is provided for educational purposes only. Use at your own risk.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

- **GitHub**: [Astralchemist](https://github.com/Astralchemist)
- **Project**: Expert Advisor Trading Bot
- **Version**: 2.0 (Enhanced)

---

*For support, bug reports, or feature requests, please open an issue on GitHub.*

