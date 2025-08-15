import MetaTrader5 as mt5
import sys
from datetime import datetime
import time

def test_connection():
    """
    Test MT5 connection and basic functionality
    
    Returns:
        bool: True if all tests pass, False otherwise
    """
    tests_passed = 0
    total_tests = 5
    
    print("Running MT5 Connection Tests...")
    print("=" * 40)
    
    # Test 1: Initialize MT5
    print("Test 1: MT5 Initialization... ", end="")
    try:
        if mt5.initialize():
            print("✅ PASSED")
            tests_passed += 1
        else:
            print("❌ FAILED")
            print(f"   Error: {mt5.last_error()}")
    except Exception as e:
        print("❌ FAILED")
        print(f"   Exception: {e}")
    
    # Test 2: Get terminal info
    print("Test 2: Terminal Information... ", end="")
    try:
        terminal_info = mt5.terminal_info()
        if terminal_info:
            print("✅ PASSED")
            print(f"   Build: {terminal_info.build}")
            print(f"   Path: {terminal_info.path}")
            tests_passed += 1
        else:
            print("❌ FAILED")
    except Exception as e:
        print("❌ FAILED")
        print(f"   Exception: {e}")
    
    # Test 3: Get account info
    print("Test 3: Account Information... ", end="")
    try:
        account_info = mt5.account_info()
        if account_info:
            print("✅ PASSED")
            print(f"   Account: {account_info.login}")
            print(f"   Server: {account_info.server}")
            print(f"   Currency: {account_info.currency}")
            tests_passed += 1
        else:
            print("❌ FAILED")
    except Exception as e:
        print("❌ FAILED")
        print(f"   Exception: {e}")
    
    # Test 4: Symbol data retrieval
    print("Test 4: Symbol Data Retrieval... ", end="")
    try:
        symbols_to_test = ["EURUSD", "GBPUSD", "USDJPY"]
        successful_symbols = 0
        
        for symbol in symbols_to_test:
            tick = mt5.symbol_info_tick(symbol)
            if tick:
                successful_symbols += 1
        
        if successful_symbols > 0:
            print("✅ PASSED")
            print(f"   Successfully retrieved data for {successful_symbols}/{len(symbols_to_test)} symbols")
            tests_passed += 1
        else:
            print("❌ FAILED")
            print("   No symbol data available")
    except Exception as e:
        print("❌ FAILED")
        print(f"   Exception: {e}")
    
    # Test 5: Trading permissions
    print("Test 5: Trading Permissions... ", end="")
    try:
        account_info = mt5.account_info()
        if account_info:
            if account_info.trade_allowed and account_info.trade_expert:
                print("✅ PASSED")
                print("   Trading and Expert Advisors allowed")
                tests_passed += 1
            else:
                print("⚠️ PARTIAL")
                print(f"   Trading allowed: {account_info.trade_allowed}")
                print(f"   EA allowed: {account_info.trade_expert}")
        else:
            print("❌ FAILED")
    except Exception as e:
        print("❌ FAILED")
        print(f"   Exception: {e}")
    
    print("\n" + "=" * 40)
    print(f"Tests completed: {tests_passed}/{total_tests} passed")
    
    return tests_passed == total_tests

def get_market_data(symbols=["EURUSD", "GBPUSD", "USDJPY"]):
    """
    Get current market data for specified symbols
    
    Args:
        symbols (list): List of symbols to get data for
    """
    print("\nCurrent Market Data:")
    print("=" * 60)
    print(f"{'Symbol':<10} {'Bid':<10} {'Ask':<10} {'Spread':<10} {'Time':<20}")
    print("-" * 60)
    
    for symbol in symbols:
        try:
            # Add symbol to Market Watch if not visible
            symbol_info = mt5.symbol_info(symbol)
            if symbol_info and not symbol_info.visible:
                mt5.symbol_select(symbol, True)
            
            tick = mt5.symbol_info_tick(symbol)
            if tick:
                spread = (tick.ask - tick.bid) / mt5.symbol_info(symbol).point
                timestamp = datetime.fromtimestamp(tick.time).strftime('%H:%M:%S')
                print(f"{symbol:<10} {tick.bid:<10.5f} {tick.ask:<10.5f} {spread:<10.1f} {timestamp:<20}")
            else:
                print(f"{symbol:<10} {'N/A':<10} {'N/A':<10} {'N/A':<10} {'N/A':<20}")
        except Exception as e:
            print(f"{symbol:<10} Error: {str(e)[:40]:<40}")

def check_system_requirements():
    """
    Check system requirements and settings
    """
    print("\nSystem Requirements Check:")
    print("=" * 40)
    
    try:
        terminal_info = mt5.terminal_info()
        if terminal_info:
            print(f"MT5 Build: {terminal_info.build}")
            print(f"DLL Allowed: {terminal_info.dlls_allowed}")
            print(f"Trade Allowed: {terminal_info.trade_allowed}")
            print(f"Connected: {terminal_info.connected}")
            
            if not terminal_info.dlls_allowed:
                print("⚠️  Warning: DLL imports not allowed")
            if not terminal_info.trade_allowed:
                print("⚠️  Warning: Trading not allowed")
            if not terminal_info.connected:
                print("❌ Error: Not connected to trading server")
        
    except Exception as e:
        print(f"Error checking system: {e}")

def main():
    """
    Main function to run all tests
    """
    try:
        print("MetaTrader 5 Connection Test Script")
        print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 50)
        
        # Run connection tests
        if test_connection():
            print("\n✅ All tests passed! MT5 is ready for trading.")
            
            # Show market data
            get_market_data()
            
            # Check system requirements
            check_system_requirements()
            
        else:
            print("\n❌ Some tests failed. Please check your MT5 setup.")
            print("\nTroubleshooting tips:")
            print("1. Ensure MT5 is running and logged in")
            print("2. Check internet connection")
            print("3. Verify trading account credentials")
            print("4. Enable algorithmic trading in MT5 (Tools > Options > Expert Advisors)")
            print("5. Allow DLL imports if using external libraries")
            
    except KeyboardInterrupt:
        print("\nTest cancelled by user")
    except Exception as e:
        print(f"\nUnexpected error: {e}")
    finally:
        print(f"\nCompleted at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        mt5.shutdown()

if __name__ == "__main__":
    main()

