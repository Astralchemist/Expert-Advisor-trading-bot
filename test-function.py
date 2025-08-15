import MetaTrader5 as mt5
import sys
from datetime import datetime

def validate_symbol(symbol):
    """
    Validate if symbol is available for trading
    
    Args:
        symbol (str): Trading symbol
    
    Returns:
        bool: True if valid, False otherwise
    """
    symbol_info = mt5.symbol_info(symbol)
    if symbol_info is None:
        print(f"Symbol {symbol} not found")
        return False
    
    if not symbol_info.visible:
        print(f"Symbol {symbol} is not visible in Market Watch")
        if not mt5.symbol_select(symbol, True):
            print(f"Failed to add {symbol} to Market Watch")
            return False
    
    return True

def calculate_safe_lot_size(symbol, risk_amount, stop_loss_pips):
    """
    Calculate lot size based on risk amount and stop loss
    
    Args:
        symbol (str): Trading symbol
        risk_amount (float): Risk amount in account currency
        stop_loss_pips (int): Stop loss in pips
    
    Returns:
        float: Calculated lot size
    """
    try:
        symbol_info = mt5.symbol_info(symbol)
        if symbol_info is None:
            return 0.01  # Default minimum
        
        tick_value = symbol_info.trade_tick_value
        tick_size = symbol_info.trade_tick_size
        min_lot = symbol_info.volume_min
        max_lot = symbol_info.volume_max
        lot_step = symbol_info.volume_step
        
        # Calculate lot size
        pip_value = tick_value * (0.0001 / tick_size)  # For 4-digit brokers
        if symbol.endswith('JPY'):
            pip_value = tick_value * (0.01 / tick_size)  # For JPY pairs
        
        lot_size = risk_amount / (stop_loss_pips * pip_value)
        
        # Round to lot step
        lot_size = round(lot_size / lot_step) * lot_step
        
        # Apply limits
        lot_size = max(min_lot, min(lot_size, max_lot))
        
        return lot_size
        
    except Exception as e:
        print(f"Error calculating lot size: {e}")
        return min_lot if 'min_lot' in locals() else 0.01

def place_test_order(symbol="EURUSD", order_type="BUY", risk_amount=50.0):
    """
    Place a test order with proper error handling
    
    Args:
        symbol (str): Trading symbol
        order_type (str): Order type (BUY/SELL)
        risk_amount (float): Risk amount in account currency
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Initialize MT5 if not already done
        if not mt5.initialize():
            print(f"Failed to initialize MT5: {mt5.last_error()}")
            return False
        
        # Validate symbol
        if not validate_symbol(symbol):
            return False
        
        # Get current price
        tick = mt5.symbol_info_tick(symbol)
        if tick is None:
            print(f"Failed to get tick data for {symbol}")
            return False
        
        # Calculate lot size (example: 50 pip stop loss)
        stop_loss_pips = 50
        lot_size = calculate_safe_lot_size(symbol, risk_amount, stop_loss_pips)
        
        # Determine price and SL/TP based on order type
        if order_type.upper() == "BUY":
            price = tick.ask
            stop_loss = price - (stop_loss_pips * 0.0001)
            take_profit = price + (stop_loss_pips * 2 * 0.0001)  # 1:2 RR
            mt5_order_type = mt5.ORDER_TYPE_BUY
        else:
            price = tick.bid
            stop_loss = price + (stop_loss_pips * 0.0001)
            take_profit = price - (stop_loss_pips * 2 * 0.0001)  # 1:2 RR
            mt5_order_type = mt5.ORDER_TYPE_SELL
        
        # Adjust for JPY pairs
        if symbol.endswith('JPY'):
            stop_loss_pips *= 100  # JPY pairs use 0.01 instead of 0.0001
            if order_type.upper() == "BUY":
                stop_loss = price - (stop_loss_pips * 0.01)
                take_profit = price + (stop_loss_pips * 2 * 0.01)
            else:
                stop_loss = price + (stop_loss_pips * 0.01)
                take_profit = price - (stop_loss_pips * 2 * 0.01)
        
        # Create order request
        request = {
            "action": mt5.TRADE_ACTION_DEAL,
            "symbol": symbol,
            "volume": lot_size,
            "type": mt5_order_type,
            "price": price,
            "sl": stop_loss,
            "tp": take_profit,
            "deviation": 20,
            "magic": 234000,
            "comment": f"Test {order_type} order",
            "type_filling": mt5.ORDER_FILLING_IOC,
            "type_time": mt5.ORDER_TIME_GTC,
        }
        
        print(f"\nPlacing {order_type} order for {symbol}:")
        print(f"Volume: {lot_size}")
        print(f"Price: {price}")
        print(f"Stop Loss: {stop_loss}")
        print(f"Take Profit: {take_profit}")
        print(f"Risk Amount: {risk_amount}")
        
        # Send order
        result = mt5.order_send(request)
        
        if result.retcode != mt5.TRADE_RETCODE_DONE:
            print(f"\n❌ Order failed!")
            print(f"Return code: {result.retcode}")
            print(f"Comment: {result.comment}")
            
            # Common error explanations
            error_messages = {
                mt5.TRADE_RETCODE_INVALID_VOLUME: "Invalid volume",
                mt5.TRADE_RETCODE_INVALID_PRICE: "Invalid price",
                mt5.TRADE_RETCODE_INVALID_STOPS: "Invalid stop loss or take profit",
                mt5.TRADE_RETCODE_TRADE_DISABLED: "Trading is disabled",
                mt5.TRADE_RETCODE_MARKET_CLOSED: "Market is closed",
                mt5.TRADE_RETCODE_NO_MONEY: "Insufficient funds",
                mt5.TRADE_RETCODE_PRICE_CHANGED: "Price changed",
                mt5.TRADE_RETCODE_REJECT: "Request rejected",
                mt5.TRADE_RETCODE_INVALID_FILL: "Invalid order filling type"
            }
            
            if result.retcode in error_messages:
                print(f"Reason: {error_messages[result.retcode]}")
            
            return False
        else:
            print(f"\n✅ Order placed successfully!")
            print(f"Order ticket: {result.order}")
            print(f"Deal ticket: {result.deal}")
            print(f"Volume: {result.volume}")
            print(f"Price: {result.price}")
            print(f"Timestamp: {datetime.fromtimestamp(result.time)}")
            return True
            
    except Exception as e:
        print(f"\nException occurred: {e}")
        return False

def main():
    """Main function for testing orders"""
    try:
        print("MetaTrader 5 Order Testing Script")
        print("=" * 40)
        
        # Test buy order
        print("\nTesting BUY order...")
        success_buy = place_test_order("EURUSD", "BUY", 25.0)
        
        if success_buy:
            # Wait a moment then test sell order
            import time
            time.sleep(2)
            
            print("\nTesting SELL order...")
            success_sell = place_test_order("GBPUSD", "SELL", 25.0)
        
        print("\n" + "=" * 40)
        print("Testing completed.")
        
    except KeyboardInterrupt:
        print("\nTesting cancelled by user")
    except Exception as e:
        print(f"\nUnexpected error: {e}")
    finally:
        mt5.shutdown()

if __name__ == "__main__":
    main()
