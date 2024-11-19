import MetaTrader5 as mt5

# Initialize MetaTrader 5 (if not already initialized)
if not mt5.initialize():
    print("Failed to initialize MetaTrader 5:", mt5.last_error())
else:
    print("MetaTrader 5 initialized successfully")

# Request current quote for EUR/USD
symbol = "EURUSD"
price = mt5.symbol_info_tick(symbol)
if price:
    print(f"Current price for {symbol}: Bid={price.bid}, Ask={price.ask}")
else:
    print(f"Failed to retrieve data for {symbol}")

