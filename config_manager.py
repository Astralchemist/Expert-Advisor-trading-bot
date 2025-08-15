import json
import os
import sys
from typing import Dict, Any, Optional

class ConfigManager:
    """
    Configuration manager for the Expert Advisor trading bot
    Handles loading, validation, and access to configuration settings
    """
    
    def __init__(self, config_file: str = "config.json"):
        """
        Initialize configuration manager
        
        Args:
            config_file (str): Path to configuration file
        """
        self.config_file = config_file
        self.config = {}
        self.load_config()
    
    def load_config(self) -> bool:
        """
        Load configuration from JSON file
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            if not os.path.exists(self.config_file):
                print(f"Configuration file {self.config_file} not found")
                self.create_default_config()
                return False
            
            with open(self.config_file, 'r', encoding='utf-8') as f:
                self.config = json.load(f)
            
            if self.validate_config():
                print(f"Configuration loaded successfully from {self.config_file}")
                return True
            else:
                print("Configuration validation failed")
                return False
                
        except json.JSONDecodeError as e:
            print(f"Error parsing configuration file: {e}")
            return False
        except Exception as e:
            print(f"Error loading configuration: {e}")
            return False
    
    def validate_config(self) -> bool:
        """
        Validate configuration settings
        
        Returns:
            bool: True if valid, False otherwise
        """
        required_sections = ['trading', 'analysis', 'symbols', 'logging', 'mt5']
        
        for section in required_sections:
            if section not in self.config:
                print(f"Missing required configuration section: {section}")
                return False
        
        # Validate trading settings
        trading = self.config['trading']
        if trading['risk_amount'] <= 0:
            print("Risk amount must be positive")
            return False
        
        if trading['max_daily_loss'] <= 0:
            print("Max daily loss must be positive")
            return False
        
        if trading['min_risk_reward'] < 1.0:
            print("Minimum risk reward must be at least 1.0")
            return False
        
        # Validate symbols
        if not self.config['symbols']:
            print("At least one symbol must be configured")
            return False
        
        return True
    
    def get(self, key_path: str, default: Any = None) -> Any:
        """
        Get configuration value using dot notation
        
        Args:
            key_path (str): Configuration key path (e.g., 'trading.risk_amount')
            default (Any): Default value if key not found
            
        Returns:
            Any: Configuration value or default
        """
        try:
            keys = key_path.split('.')
            value = self.config
            
            for key in keys:
                value = value[key]
            
            return value
        except (KeyError, TypeError):
            return default
    
    def set(self, key_path: str, value: Any) -> bool:
        """
        Set configuration value using dot notation
        
        Args:
            key_path (str): Configuration key path
            value (Any): Value to set
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            keys = key_path.split('.')
            config_ref = self.config
            
            # Navigate to parent of target key
            for key in keys[:-1]:
                if key not in config_ref:
                    config_ref[key] = {}
                config_ref = config_ref[key]
            
            # Set the value
            config_ref[keys[-1]] = value
            return True
            
        except Exception as e:
            print(f"Error setting configuration value: {e}")
            return False
    
    def save_config(self) -> bool:
        """
        Save current configuration to file
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
            
            print(f"Configuration saved to {self.config_file}")
            return True
            
        except Exception as e:
            print(f"Error saving configuration: {e}")
            return False
    
    def create_default_config(self):
        """
        Create default configuration file
        """
        default_config = {
            "trading": {
                "risk_amount": 50.0,
                "max_daily_loss": 200.0,
                "min_risk_reward": 2.0,
                "max_spread_pips": 3.0,
                "max_risk_percent": 5.0,
                "magic_number": 234567
            },
            "analysis": {
                "lookback_period": 20,
                "macd_fast": 12,
                "macd_slow": 26,
                "macd_signal": 9,
                "support_resistance_touches": 2,
                "candle_body_threshold": 1.5
            },
            "symbols": [
                {
                    "name": "EURUSD",
                    "enabled": True,
                    "max_spread": 0.0003,
                    "timeframe": "M1"
                },
                {
                    "name": "GBPUSD",
                    "enabled": True,
                    "max_spread": 0.0004,
                    "timeframe": "M1"
                }
            ],
            "logging": {
                "enabled": True,
                "level": "INFO",
                "log_trades": True,
                "log_analysis": False
            },
            "mt5": {
                "terminal_paths": [
                    "C:\\Program Files\\MetaTrader 5\\terminal64.exe",
                    "C:\\Program Files (x86)\\MetaTrader 5\\terminal64.exe"
                ],
                "connection_timeout": 60,
                "retry_attempts": 3
            }
        }
        
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(default_config, f, indent=2, ensure_ascii=False)
            
            self.config = default_config
            print(f"Default configuration created: {self.config_file}")
            
        except Exception as e:
            print(f"Error creating default configuration: {e}")
    
    def get_trading_config(self) -> Dict[str, Any]:
        """Get trading configuration section"""
        return self.config.get('trading', {})
    
    def get_analysis_config(self) -> Dict[str, Any]:
        """Get analysis configuration section"""
        return self.config.get('analysis', {})
    
    def get_enabled_symbols(self) -> list:
        """Get list of enabled trading symbols"""
        symbols = self.config.get('symbols', [])
        return [s for s in symbols if s.get('enabled', False)]
    
    def get_mt5_config(self) -> Dict[str, Any]:
        """Get MT5 configuration section"""
        return self.config.get('mt5', {})
    
    def is_logging_enabled(self) -> bool:
        """Check if logging is enabled"""
        return self.config.get('logging', {}).get('enabled', True)
    
    def print_config(self):
        """Print current configuration in readable format"""
        print("\nCurrent Configuration:")
        print("=" * 50)
        print(json.dumps(self.config, indent=2))

def main():
    """Test configuration manager"""
    config = ConfigManager()
    
    print("Configuration Manager Test")
    print("=" * 30)
    
    # Test getting values
    print(f"Risk amount: {config.get('trading.risk_amount')}")
    print(f"MACD fast period: {config.get('analysis.macd_fast')}")
    print(f"Enabled symbols: {[s['name'] for s in config.get_enabled_symbols()]}")
    
    # Test setting values
    config.set('trading.risk_amount', 75.0)
    print(f"Updated risk amount: {config.get('trading.risk_amount')}")
    
    # Print full configuration
    config.print_config()

if __name__ == "__main__":
    main()