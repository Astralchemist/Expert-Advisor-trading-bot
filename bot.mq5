//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input double RiskAmount = 50.0;        // Risk amount per trade in account currency
input double MaxDailyLoss = 200.0;     // Maximum daily loss limit
input int LookbackPeriod = 20;         // Candles to analyze for S/R zones
input double MinRiskReward = 2.0;      // Minimum risk:reward ratio
input int MagicNumber = 234567;        // Unique EA identifier
input bool EnableLogging = true;       // Enable detailed logging
input int PendingExpiryMinutes = 30;   // Cancel unfilled sell limits after this many minutes
input double MaxDrawdownPercent = 15.0; // Stop for good if equity falls this % below its peak

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double dailyStartEquity;
datetime dailyStartDay = 0;
double peakEquity = 0;
bool killSwitchTripped = false;
bool tradingEnabled = true;
int macdHandle;
datetime lastTradeTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialize MACD indicator handle
   macdHandle = iMACD(Symbol(), PERIOD_M1, 12, 26, 9, PRICE_CLOSE);
   if(macdHandle == INVALID_HANDLE)
     {
      Print("Failed to create MACD indicator handle");
      return(INIT_FAILED);
     }
   
   // Store daily start equity (restored if the EA restarted mid-day)
   LoadDailyState();

   // Restore the equity peak and whether the kill switch has tripped
   LoadKillSwitchState();

   // Validate inputs
   if(RiskAmount <= 0 || MaxDailyLoss <= 0 || MinRiskReward <= 1.0 || PendingExpiryMinutes <= 0 ||
      MaxDrawdownPercent <= 0 || MaxDrawdownPercent >= 100)
     {
      Print("Invalid input parameters");
      return(INIT_FAILED);
     }
   
   Print("EA Trader initialized successfully");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(macdHandle != INVALID_HANDLE)
      IndicatorRelease(macdHandle);
   Print("EA Trader deinitialized. Reason: ", reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Start a new daily loss window when the server day rolls over
   ResetDailyEquityIfNewDay();

   // Stop for good once equity falls too far below its peak
   if(!CheckDrawdownKillSwitch())
     {
      ClosePositions();
      DeletePendingOrders(0);
      return;
     }

   // Manage existing positions before any check below can return early
   ManagePositions();

   // Check daily loss limit
   if(!CheckDailyLossLimit())
     {
      tradingEnabled = false;
      // Open losses count toward the limit, so stop them growing, and
      // resting sell limits could still fill after the limit is hit
      ClosePositions();
      DeletePendingOrders(0);
      return;
     }

   // Check if trading is enabled
   if(!tradingEnabled)
      return;

   // Cancel sell limits that have been resting too long
   DeletePendingOrders(PendingExpiryMinutes * 60);

   // Prevent multiple trades in same minute
   if(TimeCurrent() - lastTradeTime < 60)
      return;

   // Check for existing positions to avoid duplicates
   if(PositionsTotal() > 0)
      return;

   // Check for a resting sell limit to avoid stacking pending orders
   if(CountPendingOrders() > 0)
      return;

   // Check spread
   if(!IsSpreadAcceptable())
      return;
   
   // Check for MACD confluence
   bool macdConfirmation = CheckMACD();
   if(!macdConfirmation)
      return;

   // Detect significant bearish zones (after bullish push)
   bool isBearishZone = DetectBearishZone();
   if(!isBearishZone)
      return;

   // Identify Support and Resistance Zones
   double supportLevel = IdentifySupportZone();
   double resistanceLevel = IdentifyResistanceZone();
   
   // Validate support and resistance levels
   if(supportLevel <= 0 || resistanceLevel <= 0 || supportLevel >= resistanceLevel)
     {
      if(EnableLogging)
         Print("Invalid support/resistance levels: Support=", supportLevel, ", Resistance=", resistanceLevel);
      return;
     }

   // Check for Fair Value Gap (FVG) and nearby resistance
   if (IsFVGAndResistanceAligned(supportLevel, resistanceLevel))
     {
      // Set Sell Limit at supply zone
      SetSellLimit(supportLevel, resistanceLevel);
     }
  }
//+------------------------------------------------------------------+
//| Function to check MACD confirmation                              |
//+------------------------------------------------------------------+
bool CheckMACD()
  {
   double macdMain[], macdSignal[];

   // Index 0 is the current bar (MQL5 copies oldest first otherwise)
   ArraySetAsSeries(macdMain, true);
   ArraySetAsSeries(macdSignal, true);

   // Copy MACD values
   if(CopyBuffer(macdHandle, 0, 0, 3, macdMain) < 0 ||
      CopyBuffer(macdHandle, 1, 0, 3, macdSignal) < 0)
     {
      if(EnableLogging)
         Print("Error retrieving MACD values: ", GetLastError());
      return false;
     }
   
   // Check for valid values
   if(ArraySize(macdMain) < 3 || ArraySize(macdSignal) < 3)
     {
      if(EnableLogging)
         Print("Insufficient MACD data");
      return false;
     }

   // MACD Confluence: Main line crossing below Signal line indicates sell momentum
   // Also check for momentum confirmation (current < previous)
   bool crossBelow = macdMain[0] < macdSignal[0] && macdMain[1] >= macdSignal[1];
   bool bearishMomentum = macdMain[0] < macdMain[1];
   
   return crossBelow && bearishMomentum;
  }
//+------------------------------------------------------------------+
//| Function to detect significant bearish zone after bullish push   |
//+------------------------------------------------------------------+
bool DetectBearishZone()
  {
   double open[], close[], high[], low[];

   // Index 0 is the current bar (MQL5 copies oldest first otherwise)
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);

   // Get more candles for better analysis
   if(CopyOpen(Symbol(), PERIOD_M1, 0, 10, open) < 0 ||
      CopyClose(Symbol(), PERIOD_M1, 0, 10, close) < 0 ||
      CopyHigh(Symbol(), PERIOD_M1, 0, 10, high) < 0 ||
      CopyLow(Symbol(), PERIOD_M1, 0, 10, low) < 0)
     {
      if(EnableLogging)
         Print("Error getting price data for bearish zone detection");
      return false;
     }
   
   // Check for bullish momentum followed by bearish reversal
   int bullishCount = 0;
   for(int i = 5; i < 9; i++) // Check last 4 candles for bullish push
     {
      if(close[i] > open[i])
         bullishCount++;
     }
   
   // Require at least 3 bullish candles in the push
   bool hadBullishPush = bullishCount >= 3;
   
   // Check current candle is bearish with significant body
   bool currentBearish = close[0] < open[0];
   double currentBodySize = MathAbs(close[0] - open[0]);
   double avgBodySize = 0;
   
   for(int i = 1; i <= 5; i++)
      avgBodySize += MathAbs(close[i] - open[i]);
   avgBodySize /= 5;
   
   bool significantBearishCandle = currentBodySize > avgBodySize * 1.5;
   
   return hadBullishPush && currentBearish && significantBearishCandle;
  }
//+------------------------------------------------------------------+
//| Function to identify the support zone using fractal analysis    |
//+------------------------------------------------------------------+
double IdentifySupportZone()
  {
   double low[];
   
   if(CopyLow(Symbol(), PERIOD_M1, 0, LookbackPeriod + 5, low) < 0)
     {
      if(EnableLogging)
         Print("Error getting low prices for support zone");
      return 0;
     }
   
   double supportLevel = 0;
   int touchCount = 0;
   
   // Find fractal lows (swing lows)
   for(int i = 2; i < ArraySize(low) - 2; i++)
     {
      if(low[i] <= low[i-1] && low[i] <= low[i-2] && 
         low[i] <= low[i+1] && low[i] <= low[i+2])
        {
         // Check how many times price tested this level
         int currentTouches = 0;
         for(int j = 0; j < ArraySize(low); j++)
           {
            if(MathAbs(low[j] - low[i]) <= Point() * 5) // Within 5 pips
               currentTouches++;
           }
         
         if(currentTouches > touchCount)
           {
            touchCount = currentTouches;
            supportLevel = low[i];
           }
        }
     }
   
   return supportLevel;
  }
//+------------------------------------------------------------------+
//| Function to identify the resistance zone using fractal analysis |
//+------------------------------------------------------------------+
double IdentifyResistanceZone()
  {
   double high[];
   
   if(CopyHigh(Symbol(), PERIOD_M1, 0, LookbackPeriod + 5, high) < 0)
     {
      if(EnableLogging)
         Print("Error getting high prices for resistance zone");
      return 0;
     }
   
   double resistanceLevel = 0;
   int touchCount = 0;
   
   // Find fractal highs (swing highs)
   for(int i = 2; i < ArraySize(high) - 2; i++)
     {
      if(high[i] >= high[i-1] && high[i] >= high[i-2] && 
         high[i] >= high[i+1] && high[i] >= high[i+2])
        {
         // Check how many times price tested this level
         int currentTouches = 0;
         for(int j = 0; j < ArraySize(high); j++)
           {
            if(MathAbs(high[j] - high[i]) <= Point() * 5) // Within 5 pips
               currentTouches++;
           }
         
         if(currentTouches > touchCount)
           {
            touchCount = currentTouches;
            resistanceLevel = high[i];
           }
        }
     }
   
   return resistanceLevel;
  }
//+------------------------------------------------------------------+
//| Function to check if FVG and resistance are aligned              |
//+------------------------------------------------------------------+
bool IsFVGAndResistanceAligned(double support, double resistance)
  {
   double fvgStart = iLow(Symbol(), PERIOD_M1, 2);
   double fvgEnd = iHigh(Symbol(), PERIOD_M1, 0);

   // Check FVG is within the resistance range
   return (fvgStart < resistance && fvgEnd > resistance);
  }
//+------------------------------------------------------------------+
//| Function to set a sell limit order at the supply zone            |
//+------------------------------------------------------------------+
void SetSellLimit(double support, double resistance)
  {
   double entryPrice = resistance;
   double stopLoss = resistance + (resistance - support) * 0.5; // More conservative SL
   double riskRewardDistance = entryPrice - support;
   double takeProfit = entryPrice - (riskRewardDistance * MinRiskReward);
   
   // Validate levels
   if(stopLoss <= entryPrice || takeProfit >= entryPrice)
     {
      if(EnableLogging)
         Print("Invalid SL/TP levels. Entry: ", entryPrice, ", SL: ", stopLoss, ", TP: ", takeProfit);
      return;
     }

   // Calculate lot size with proper validation
   double lotSize = CalculateLotSize(RiskAmount, stopLoss, entryPrice);
   if(lotSize <= 0)
     {
      if(EnableLogging)
         Print("Invalid lot size calculated: ", lotSize);
      return;
     }

   // Create trade request
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_PENDING;
   request.symbol = Symbol();
   request.volume = lotSize;
   request.type = ORDER_TYPE_SELL_LIMIT;
   request.price = entryPrice;
   request.sl = stopLoss;
   request.tp = takeProfit;
   request.magic = MagicNumber;
   request.comment = "EA Sell Limit";
   request.type_filling = GetFillingMode();

   // Send order
   if(!OrderSend(request, result))
     {
      if(EnableLogging)
         Print("Order failed. Error: ", GetLastError(), ", Retcode: ", result.retcode);
     }
   else
     {
      lastTradeTime = TimeCurrent();
      if(EnableLogging)
         Print("Sell limit order placed. Ticket: ", result.order, ", Entry: ", entryPrice, ", SL: ", stopLoss, ", TP: ", takeProfit);
     }
  }
//+------------------------------------------------------------------+
//| Function to pick a filling mode the broker allows for the symbol |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode()
  {
   long filling = SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE);

   // Keep IOC where the broker allows it, else fall back
   if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
  }
//+------------------------------------------------------------------+
//| Function to calculate lot size based on risk with validation     |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskAmount, double stopLoss, double entryPrice)
  {
   if(riskAmount <= 0 || stopLoss <= 0 || entryPrice <= 0)
     {
      if(EnableLogging)
         Print("Invalid parameters for lot size calculation");
      return 0;
     }
   
   double riskDistance = MathAbs(stopLoss - entryPrice);
   if(riskDistance <= 0)
     {
      if(EnableLogging)
         Print("Invalid risk distance: ", riskDistance);
      return 0;
     }
   
   // Get symbol information
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   
   if(tickValue <= 0 || tickSize <= 0)
     {
      if(EnableLogging)
         Print("Invalid symbol tick information");
      return 0;
     }
   
   // Calculate lot size
   double riskInTicks = riskDistance / tickSize;
   double lotSize = riskAmount / (riskInTicks * tickValue);
   
   // Normalize to lot step
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   
   // Apply limits
   if(lotSize < minLot)
      lotSize = minLot;
   if(lotSize > maxLot)
      lotSize = maxLot;
   
   // Final validation
   double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double maxRiskPercent = 0.05; // 5% max risk per trade
   double maxAllowedLot = (accountEquity * maxRiskPercent) / (riskInTicks * tickValue);
   
   if(lotSize > maxAllowedLot)
     {
      if(EnableLogging)
         Print("Lot size exceeds 5% account risk. Adjusted from ", lotSize, " to ", maxAllowedLot);
      lotSize = maxAllowedLot;
     }
   
   return NormalizeDouble(lotSize, 2);
  }
//+------------------------------------------------------------------+
//| Function to check daily loss limit                              |
//+------------------------------------------------------------------+
bool CheckDailyLossLimit()
  {
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyLoss = dailyStartEquity - currentEquity;
   
   if(dailyLoss >= MaxDailyLoss)
     {
      if(EnableLogging)
         Print("Daily loss limit reached: ", dailyLoss, " >= ", MaxDailyLoss);
      return false;
     }
   
   return true;
  }
//+------------------------------------------------------------------+
//| Function to get the start of the current server day              |
//+------------------------------------------------------------------+
datetime CurrentServerDay()
  {
   return (datetime)((long)TimeCurrent() / 86400 * 86400);
  }
//+------------------------------------------------------------------+
//| Function to reset daily start equity on a new server day         |
//+------------------------------------------------------------------+
void ResetDailyEquityIfNewDay()
  {
   datetime today = CurrentServerDay();
   if(today == dailyStartDay)
      return;

   dailyStartDay = today;
   dailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   tradingEnabled = true;
   SaveDailyState();

   if(EnableLogging)
      Print("New trading day. Daily start equity reset to ", dailyStartEquity);
  }
//+------------------------------------------------------------------+
//| Function to build the terminal global variable name prefix       |
//+------------------------------------------------------------------+
string StatePrefix()
  {
   return "EA_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "_" +
          Symbol() + "_" + IntegerToString(MagicNumber) + "_";
  }
//+------------------------------------------------------------------+
//| Function to save the daily start equity so restarts keep it      |
//+------------------------------------------------------------------+
void SaveDailyState()
  {
   GlobalVariableSet(StatePrefix() + "Day", (double)dailyStartDay);
   GlobalVariableSet(StatePrefix() + "StartEquity", dailyStartEquity);
  }
//+------------------------------------------------------------------+
//| Function to restore today's start equity, or start a new day     |
//+------------------------------------------------------------------+
void LoadDailyState()
  {
   string dayVar = StatePrefix() + "Day";
   string equityVar = StatePrefix() + "StartEquity";

   if(GlobalVariableCheck(dayVar) && GlobalVariableCheck(equityVar) &&
      (datetime)GlobalVariableGet(dayVar) == CurrentServerDay())
     {
      dailyStartDay = (datetime)GlobalVariableGet(dayVar);
      dailyStartEquity = GlobalVariableGet(equityVar);
      if(EnableLogging)
         Print("Restored daily start equity ", dailyStartEquity, " from earlier today");
      return;
     }

   dailyStartDay = CurrentServerDay();
   dailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   SaveDailyState();
  }
//+------------------------------------------------------------------+
//| Function to restore the equity peak and kill switch state        |
//+------------------------------------------------------------------+
void LoadKillSwitchState()
  {
   string peakVar = StatePrefix() + "PeakEquity";
   string killVar = StatePrefix() + "KillSwitch";
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   peakEquity = equity;
   if(GlobalVariableCheck(peakVar))
      peakEquity = MathMax(GlobalVariableGet(peakVar), equity);
   GlobalVariableSet(peakVar, peakEquity);

   killSwitchTripped = GlobalVariableCheck(killVar) && GlobalVariableGet(killVar) != 0;
   if(killSwitchTripped)
      Print("Drawdown kill switch is tripped. Delete global variables ", killVar,
            " and ", peakVar, " to trade again");
  }
//+------------------------------------------------------------------+
//| Function to check equity drawdown from its peak                  |
//+------------------------------------------------------------------+
bool CheckDrawdownKillSwitch()
  {
   if(killSwitchTripped)
      return false;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > peakEquity)
     {
      peakEquity = equity;
      GlobalVariableSet(StatePrefix() + "PeakEquity", peakEquity);
     }

   if(peakEquity <= 0)
      return true;

   double drawdownPercent = (peakEquity - equity) / peakEquity * 100.0;
   if(drawdownPercent < MaxDrawdownPercent)
      return true;

   killSwitchTripped = true;
   GlobalVariableSet(StatePrefix() + "KillSwitch", 1);
   Print("Drawdown kill switch tripped: equity ", equity, " is ", drawdownPercent,
         "% below peak ", peakEquity, ". Trading stopped until reset");
   return false;
  }
//+------------------------------------------------------------------+
//| Function to count this EA's pending orders on the current symbol |
//+------------------------------------------------------------------+
int CountPendingOrders()
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 &&
         OrderGetString(ORDER_SYMBOL) == Symbol() &&
         OrderGetInteger(ORDER_MAGIC) == MagicNumber)
         count++;
     }
   return count;
  }
//+------------------------------------------------------------------+
//| Function to delete this EA's pending orders older than a limit   |
//| (pass 0 to delete all of them)                                   |
//+------------------------------------------------------------------+
void DeletePendingOrders(int olderThanSeconds)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 ||
         OrderGetString(ORDER_SYMBOL) != Symbol() ||
         OrderGetInteger(ORDER_MAGIC) != MagicNumber)
         continue;

      datetime setupTime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(TimeCurrent() - setupTime < olderThanSeconds)
         continue;

      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_REMOVE;
      request.order = ticket;

      if(!OrderSend(request, result))
        {
         if(EnableLogging)
            Print("Failed to delete pending order ", ticket, ". Error: ", GetLastError(), ", Retcode: ", result.retcode);
        }
      else if(EnableLogging)
         Print("Pending order deleted: ", ticket);
     }
  }
//+------------------------------------------------------------------+
//| Function to close this EA's open positions on the current symbol |
//+------------------------------------------------------------------+
void ClosePositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 ||
         PositionGetString(POSITION_SYMBOL) != Symbol() ||
         PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      bool isSell = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL;

      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_DEAL;
      request.symbol = Symbol();
      request.position = ticket;
      request.volume = PositionGetDouble(POSITION_VOLUME);
      request.type = isSell ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      request.price = isSell ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
      request.deviation = 10;
      request.magic = MagicNumber;
      request.type_filling = GetFillingMode();

      if(!OrderSend(request, result))
        {
         if(EnableLogging)
            Print("Failed to close position ", ticket, ". Error: ", GetLastError(), ", Retcode: ", result.retcode);
        }
      else if(EnableLogging)
         Print("Position closed: ", ticket);
     }
  }
//+------------------------------------------------------------------+
//| Function to check if spread is acceptable                       |
//+------------------------------------------------------------------+
bool IsSpreadAcceptable()
  {
   double spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * Point();
   double maxSpread = 0.0003; // 3 pips max for EURUSD/GBPUSD
   
   if(spread > maxSpread)
     {
      if(EnableLogging)
         Print("Spread too high: ", spread, " > ", maxSpread);
      return false;
     }
   
   return true;
  }
//+------------------------------------------------------------------+
//| Function to manage existing positions (move SL to breakeven)    |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(PositionSelectByTicket(PositionGetTicket(i)))
        {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
           {
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double stopLoss = PositionGetDouble(POSITION_SL);
            double takeProfit = PositionGetDouble(POSITION_TP);
            
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {
               // A sell's stop loss sits above the entry
               double riskDistance = stopLoss - openPrice;
               double currentProfit = openPrice - currentPrice;

               // Move SL to breakeven when 1:1 RR is reached
               // (riskDistance <= 0 means no SL or already at breakeven)
               if(riskDistance > 0 && currentProfit >= riskDistance)
                 {
                  MqlTradeRequest request = {};
                  MqlTradeResult result = {};
                  
                  request.action = TRADE_ACTION_SLTP;
                  request.symbol = Symbol();
                  request.sl = openPrice;
                  request.tp = takeProfit;
                  request.position = PositionGetTicket(i);
                  
                  if(OrderSend(request, result) && EnableLogging)
                     Print("Stop loss moved to breakeven for position: ", PositionGetTicket(i));
                 }
              }
           }
        }
     }
  }
