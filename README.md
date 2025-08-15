# Expert Advisor Trading Bot

A professional-grade MQL5 Expert Advisor with advanced risk management, comprehensive error handling, and modern Python integration tools. This trading bot implements sophisticated technical analysis algorithms and defensive security measures for automated forex trading.

## 🚀 Key Features

### Advanced Trading Logic
- **Modern MACD Analysis**: Uses current MQL5 syntax with proper indicator handles
- **Fractal-Based Support/Resistance**: Intelligent price level detection using fractal analysis
- **Enhanced Fair Value Gap Detection**: Sophisticated gap analysis with momentum confirmation
- **Multi-Timeframe Analysis**: Configurable timeframe support beyond just 1-minute charts

### Risk Management & Security
- **Dynamic Position Sizing**: Intelligent lot size calculation with account equity protection
- **Daily Loss Limits**: Automatic trading halt when daily loss threshold is reached
- **Spread Protection**: Real-time spread monitoring with configurable maximum limits
- **Breakeven Management**: Automatic stop loss adjustment to breakeven at 1:1 R:R
- **Account Safety**: Maximum 5% account risk per trade with validation

### Technical Improvements
- **Comprehensive Error Handling**: Robust error detection and logging throughout
- **Modern MQL5 Syntax**: Updated to use latest MetaTrader 5 functions and structures
- **Input Validation**: All parameters validated before execution
- **Memory Management**: Proper indicator handle management and cleanup

## 📊 Trading Strategy

### Signal Generation
- **Bearish Reversal Detection**: Advanced pattern recognition identifying significant bearish zones after bullish momentum
- **Fractal Support/Resistance**: Multi-touch level validation using fractal analysis over configurable lookback periods
- **Fair Value Gap Analysis**: Sophisticated gap detection with volume and momentum confirmation
- **MACD Confluence**: Cross-validation using MACD histogram and signal line crossovers

### Execution Logic
- **Sell Limit Orders**: Strategic order placement at identified supply zones
- **Dynamic Risk-Reward**: Configurable minimum R:R ratios (default 1:2)
- **Spread Validation**: Real-time spread checking before order execution
- **Duplicate Prevention**: Advanced logic to prevent multiple orders on same signal

### Position Management
- **Breakeven Automation**: Automatic stop loss adjustment when trade reaches 1:1 R:R
- **Trailing Stops**: Optional trailing stop functionality (configurable)
- **Position Monitoring**: Real-time position tracking and management

## 🛠️ Requirements

### Software Requirements
- **MetaTrader 5** (Build 3340 or higher recommended)
- **Python 3.8+** (for auxiliary scripts and analysis)
- **MetaTrader5 Python package** (`pip install MetaTrader5`)

### Account Requirements
- Active MetaTrader 5 trading account
- Algorithmic trading enabled
- Sufficient margin for position sizing
- DLL imports allowed (for enhanced functionality)

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
1. Edit `config.json` to customize trading parameters
2. Run `python config_manager.py` to validate configuration
3. Test connection with `python init-test.py`

## 🎯 Usage

### Quick Start
1. **Initialize Connection**: Run `python mt5-init.py` to establish MT5 connection
2. **Verify Account**: Run `python account-info.py` to check account status
3. **Test Functionality**: Run `python test-function.py` to test order placement
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
- **Dynamic Lot Calculation**: Based on account equity and risk percentage
- **Maximum Risk**: 5% of account equity per trade (configurable)
- **Minimum/Maximum Lots**: Respects broker limitations
- **Account Protection**: Validates against margin requirements

### Loss Protection
- **Daily Loss Limits**: Automatic trading halt when threshold reached
- **Spread Monitoring**: Real-time spread validation before execution
- **Equity Protection**: Continuous account equity monitoring
- **Error Handling**: Comprehensive error detection and response

### Trade Management
- **Breakeven Automation**: SL moved to entry when 1:1 R:R achieved
- **Position Monitoring**: Real-time position tracking
- **Risk-Reward Validation**: Ensures minimum R:R before execution
- **Duplicate Prevention**: Prevents multiple orders on same signal

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
- **Risk Parameters**: Risk amount, daily limits, R:R ratios
- **Technical Indicators**: MACD periods, lookback periods
- **Symbol Configuration**: Add/remove trading pairs
- **Timeframes**: Modify for different chart periods
- **Logging**: Detailed logging levels and options

## 📈 Testing & Validation

### Strategy Tester (MT5)
1. Open MetaTrader 5 Strategy Tester (Ctrl+R)
2. Select Expert Advisor: `bot`
3. Configure test parameters:
   - Symbol: EURUSD or GBPUSD
   - Timeframe: M1 (or configured timeframe)
   - Date range: Sufficient historical data
   - Model: Every tick (most accurate)
4. Set input parameters matching your live configuration
5. Run backtest and analyze results

### Python Testing Scripts
```bash
# Test MT5 connection
python init-test.py

# Verify account information
python account-info.py

# Test order functionality
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
- Verify DLL imports are allowed
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

- **Input Validation**: All parameters validated before use
- **Error Handling**: Comprehensive error detection and logging
- **Account Protection**: Multiple safety mechanisms
- **Defensive Coding**: Secure programming practices throughout
- **No Hardcoded Secrets**: Configuration-based sensitive data

## 📊 Monitoring & Analytics

### Real-time Monitoring
- Account equity and balance tracking
- Position monitoring and management
- Spread and market condition analysis
- Error detection and alerting

### Performance Analytics
- Trade history analysis
- Risk metrics calculation
- Drawdown monitoring
- Profit/loss tracking

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

