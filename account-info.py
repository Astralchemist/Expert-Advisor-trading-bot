import MetaTrader5 as mt5
import sys
from datetime import datetime

def get_detailed_account_info():
    """
    Get comprehensive account information with error handling
    
    Returns:
        dict: Account information or None if failed
    """
    try:
        # Initialize if not already done
        if not mt5.initialize():
            print(f"Failed to initialize MetaTrader 5: {mt5.last_error()}")
            return None
        
        # Get account information
        account_info = mt5.account_info()
        if account_info is None:
            print("Failed to get account information")
            print(f"Last error: {mt5.last_error()}")
            return None
        
        # Convert to dictionary for easier handling
        account_data = {
            'login': account_info.login,
            'server': account_info.server,
            'name': account_info.name,
            'company': account_info.company,
            'currency': account_info.currency,
            'balance': account_info.balance,
            'equity': account_info.equity,
            'margin': account_info.margin,
            'free_margin': account_info.margin_free,
            'margin_level': account_info.margin_level,
            'profit': account_info.profit,
            'trade_allowed': account_info.trade_allowed,
            'trade_expert': account_info.trade_expert,
            'leverage': account_info.leverage,
            'margin_so_mode': account_info.margin_so_mode,
            'margin_so_call': account_info.margin_so_call,
            'margin_so_so': account_info.margin_so_so
        }
        
        return account_data
        
    except Exception as e:
        print(f"Exception occurred while getting account info: {e}")
        return None

def print_account_summary(account_data):
    """
    Print formatted account summary
    
    Args:
        account_data (dict): Account information dictionary
    """
    if not account_data:
        print("No account data available")
        return
    
    print("\n" + "="*50)
    print("           ACCOUNT INFORMATION")
    print("="*50)
    print(f"Account ID: {account_data['login']}")
    print(f"Server: {account_data['server']}")
    print(f"Company: {account_data['company']}")
    print(f"Account Name: {account_data['name']}")
    print(f"Currency: {account_data['currency']}")
    print(f"Leverage: 1:{account_data['leverage']}")
    print("\n" + "-"*30)
    print("         FINANCIAL DATA")
    print("-"*30)
    print(f"Balance: {account_data['balance']:.2f} {account_data['currency']}")
    print(f"Equity: {account_data['equity']:.2f} {account_data['currency']}")
    print(f"Profit/Loss: {account_data['profit']:.2f} {account_data['currency']}")
    print(f"Free Margin: {account_data['free_margin']:.2f} {account_data['currency']}")
    print(f"Margin Level: {account_data['margin_level']:.2f}%")
    print("\n" + "-"*30)
    print("        TRADING STATUS")
    print("-"*30)
    print(f"Trading Allowed: {'✓' if account_data['trade_allowed'] else '✗'}")
    print(f"Expert Advisors: {'✓' if account_data['trade_expert'] else '✗'}")
    print(f"Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*50)

def check_trading_conditions(account_data):
    """
    Check if account is ready for trading
    
    Args:
        account_data (dict): Account information dictionary
    
    Returns:
        bool: True if ready for trading, False otherwise
    """
    if not account_data:
        return False
    
    warnings = []
    errors = []
    
    # Check trading permissions
    if not account_data['trade_allowed']:
        errors.append("Trading is not allowed on this account")
    
    if not account_data['trade_expert']:
        errors.append("Expert Advisors are not allowed")
    
    # Check margin level
    if account_data['margin_level'] < 100:
        errors.append(f"Low margin level: {account_data['margin_level']:.2f}%")
    elif account_data['margin_level'] < 200:
        warnings.append(f"Margin level is low: {account_data['margin_level']:.2f}%")
    
    # Check free margin
    if account_data['free_margin'] < 100:
        warnings.append(f"Low free margin: {account_data['free_margin']:.2f}")
    
    # Print warnings and errors
    if warnings:
        print("\n⚠️  WARNINGS:")
        for warning in warnings:
            print(f"   - {warning}")
    
    if errors:
        print("\n❌ ERRORS:")
        for error in errors:
            print(f"   - {error}")
        return False
    
    if not warnings and not errors:
        print("\n✅ Account is ready for trading!")
    
    return True

def main():
    """Main function"""
    try:
        print("Retrieving account information...")
        account_data = get_detailed_account_info()
        
        if account_data:
            print_account_summary(account_data)
            check_trading_conditions(account_data)
        else:
            print("\nFailed to retrieve account information.")
            print("Please ensure:")
            print("1. MetaTrader 5 is running")
            print("2. You are logged into a trading account")
            print("3. The account has proper permissions")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)
    finally:
        mt5.shutdown()

if __name__ == "__main__":
    main()
