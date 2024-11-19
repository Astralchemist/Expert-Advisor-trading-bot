import MetaTrader5 as mt5

# Initialize MetaTrader 5 connection
mt5.initialize("C:\\Program Files\\MetaTrader 5\\terminal64.exe")

# Check if initialization was successful
if not mt5.initialize():
    print("Failed to initialize MetaTrader 5:", mt5.last_error())
else:
    print("MetaTrader 5 initialized successfully")
