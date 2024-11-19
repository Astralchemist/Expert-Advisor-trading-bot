//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Strategy initialized");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Cleanup if needed
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Check for MACD confluence
   bool macdConfirmation = CheckMACD();

   // Detect significant bearish zones (after bullish push)
   bool isBearishZone = DetectBearishZone();

   // Identify Support and Resistance Zones
   double supportLevel = IdentifySupportZone();
   double resistanceLevel = IdentifyResistanceZone();

   // If the conditions are met (bearish zone and MACD confirmation)
   if (isBearishZone && macdConfirmation)
     {
      // Check for Fair Value Gap (FVG) and nearby resistance
      if (IsFVGAndResistanceAligned(supportLevel, resistanceLevel))
        {
         // Set Sell Limit at supply zone
         SetSellLimit(supportLevel, resistanceLevel);
        }
     }
  }
//+------------------------------------------------------------------+
//| Function to check MACD confirmation                              |
//+------------------------------------------------------------------+
bool CheckMACD()
  {
   // MACD parameters
   int macdFastPeriod = 12;
   int macdSlowPeriod = 26;
   int signalPeriod = 9;

   // Get the latest MACD values
   double macdMain = iCustom(Symbol(), PERIOD_M1, "MACD", macdFastPeriod, macdSlowPeriod, signalPeriod, MODE_MAIN, 0);
   double macdSignal = iCustom(Symbol(), PERIOD_M1, "MACD", macdFastPeriod, macdSlowPeriod, signalPeriod, MODE_SIGNAL, 0);

   if (macdMain == 0 || macdSignal == 0)
     {
      Print("Error retrieving MACD values");
      return false;
     }

   // MACD Confluence: Blue line (fast) crossing below Orange line (slow) indicates sell momentum
   return macdMain < macdSignal;
  }
//+------------------------------------------------------------------+
//| Function to detect significant bearish zone after bullish push   |
//+------------------------------------------------------------------+
bool DetectBearishZone()
  {
   double openPrev = iOpen(Symbol(), PERIOD_M1, 1);
   double closePrev = iClose(Symbol(), PERIOD_M1, 1);
   double openCurr = iOpen(Symbol(), PERIOD_M1, 0);
   double closeCurr = iClose(Symbol(), PERIOD_M1, 0);

   // Check if the previous candle is bullish and the current is bearish
   return openPrev < closePrev && openCurr > closeCurr;
  }
//+------------------------------------------------------------------+
//| Function to identify the support zone                            |
//+------------------------------------------------------------------+
double IdentifySupportZone()
  {
   double lowestLow = iLow(Symbol(), PERIOD_M1, 1);
   for (int i = 2; i <= 5; i++) // Check the last 5 candles for the lowest low
     {
      double low = iLow(Symbol(), PERIOD_M1, i);
      if (low < lowestLow)
        lowestLow = low;
     }
   return lowestLow;
  }
//+------------------------------------------------------------------+
//| Function to identify the resistance zone                         |
//+------------------------------------------------------------------+
double IdentifyResistanceZone()
  {
   double highestHigh = iHigh(Symbol(), PERIOD_M1, 1);
   for (int i = 2; i <= 5; i++) // Check the last 5 candles for the highest high
     {
      double high = iHigh(Symbol(), PERIOD_M1, i);
      if (high > highestHigh)
        highestHigh = high;
     }
   return highestHigh;
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
   double riskAmount = 50.0; // Risk $50
   double stopLoss = resistance + (resistance - support);
   double takeProfit = resistance - 3 * (resistance - support);

   // Calculate lot size
   double lotSize = CalculateLotSize(riskAmount, stopLoss, resistance);

   // Place a sell limit order
   int ticket = OrderSend(Symbol(), OP_SELLLIMIT, lotSize, resistance, 3, stopLoss, takeProfit, "Sell Limit", 0, 0, clrRed);
   if (ticket < 0)
      Print("Error placing sell limit: ", GetLastError());
  }
//+------------------------------------------------------------------+
//| Function to calculate lot size based on risk                     |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskAmount, double stopLoss, double entryPrice)
  {
   double accountBalance = AccountBalance();
   double pipValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double riskPerPip = riskAmount / (MathAbs(stopLoss - entryPrice));
   return NormalizeDouble(riskPerPip / pipValue, 2);
  }
