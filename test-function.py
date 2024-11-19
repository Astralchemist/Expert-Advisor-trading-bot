# Example: Send a buy order for EUR/USD
symbol = "EURUSD"
lot_size = 0.01
price = mt5.symbol_info_tick(symbol).ask
slippage = 10  # Max allowed slippage
stop_loss = price - 0.0010  # Example stop loss
take_profit = price + 0.0020  # Example take profit

# Create a request for a buy order
request = {
    "action": mt5.TRADE_ACTION_DEAL,
    "symbol": symbol,
    "volume": lot_size,
    "type": mt5.ORDER_TYPE_BUY,
    "price": price,
    "sl": stop_loss,
    "tp": take_profit,
    "deviation": slippage,
    "magic": 234000,  # Unique identifier for the order
    "comment": "test buy order",
    "type_filling": mt5.ORDER_FILLING_IOC,
    "type_time": mt5.ORDER_TIME_GTC,
}

# Send the request
result = mt5.order_send(request)
if result.retcode != mt5.TRADE_RETCODE_DONE:
    print(f"Failed to place order: {result.retcode}")
else:
    print(f"Order placed successfully: {result}")
