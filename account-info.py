import MetaTrader5 as mt5

# Initialize MetaTrader 5 (if not already initialized)
if not mt5.initialize():
    print("Failed to initialize MetaTrader 5:", mt5.last_error())
else:
    print("MetaTrader 5 initialized successfully")

# Get account information
account_info = mt5.account_info()
if account_info is not None:
    print(f"Account ID: {account_info.login}")
    print(f"Balance: {account_info.balance}")
    print(f"Equity: {account_info.equity}")
else:
    print("Failed to get account information")
