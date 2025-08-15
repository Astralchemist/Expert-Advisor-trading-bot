import MetaTrader5 as mt5
import os
import sys
from datetime import datetime

def initialize_mt5(terminal_path=None):
    """
    Initialize MetaTrader 5 connection with error handling
    
    Args:
        terminal_path (str): Path to MT5 terminal executable
    
    Returns:
        bool: True if initialization successful, False otherwise
    """
    try:
        # Try default initialization first
        if not terminal_path:
            if not mt5.initialize():
                # Try common installation paths
                common_paths = [
                    "C:\\Program Files\\MetaTrader 5\\terminal64.exe",
                    "C:\\Program Files (x86)\\MetaTrader 5\\terminal64.exe",
                    "C:\\Users\\{}\\AppData\\Roaming\\MetaQuotes\\Terminal\\*\\terminal64.exe".format(os.getenv('USERNAME'))
                ]
                
                for path in common_paths:
                    if os.path.exists(path):
                        if mt5.initialize(path):
                            print(f"MetaTrader 5 initialized successfully using: {path}")
                            return True
                
                print("Failed to initialize MetaTrader 5 with default paths")
                return False
        else:
            if not mt5.initialize(terminal_path):
                print(f"Failed to initialize MetaTrader 5 with path: {terminal_path}")
                print(f"Error: {mt5.last_error()}")
                return False
        
        # Verify connection
        account_info = mt5.account_info()
        if account_info is None:
            print("Failed to get account information")
            return False
        
        print(f"MetaTrader 5 initialized successfully")
        print(f"Connected to account: {account_info.login}")
        print(f"Server: {account_info.server}")
        print(f"Connection time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        return True
        
    except Exception as e:
        print(f"Exception during MT5 initialization: {e}")
        return False

def main():
    """Main function to initialize MT5"""
    if not initialize_mt5():
        print("\nTroubleshooting tips:")
        print("1. Ensure MetaTrader 5 is installed")
        print("2. Check if MT5 terminal is running")
        print("3. Verify your trading account credentials")
        print("4. Check if algorithmic trading is enabled in MT5")
        sys.exit(1)
    
    print("\nInitialization complete. You can now run your trading scripts.")

if __name__ == "__main__":
    main()
