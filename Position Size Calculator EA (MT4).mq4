//+------------------------------------------------------------------+
//| Position Size Calculator EA (MT4)                                |
//+------------------------------------------------------------------+
#property strict
#property copyright   "COPYRIGHT 2025, KALIFX"
#property link        "kalifxlab.com"
#property description "Position size calculator by KALIFX"
#property version     "2.2"

input double DefaultRiskPercent = 1.0;    // default % risk per trade
input double DefaultFixedLots   = 0.01;   // default fixed lots
input double DefaultSLOffsetPips = 10;    // default SL offset from entry
input double DefaultTPOffsetPips = 20;    // default TP offset from entry
input color  PanelBorderColor   = clrBlack;
input color  PanelFillColor     = clrWhite;
input color  TextColor          = clrBlack;
input color  ResultColor        = clrBlack;
input int    MagicNumber        = 10001;

// ------------------- Panel geometry (pixel coordinates) -------------------
int P_X = 170;
int P_Y = 140;
int P_W = 310;
int P_H = 290;

// ------------------- Object names -------------------
string OBJ_BG         = "psc_bg";
string OBJ_MODE_BTN   = "psc_mode_btn";      // Risk % <-> Fixed Lots
string OBJ_MODE_EDIT  = "psc_mode_edit";     // value box
string OBJ_ORDER_BTN  = "psc_order_btn";     // market order <-> pending order
string OBJ_SELL_BTN   = "psc_sell_btn";
string OBJ_BUY_BTN    = "psc_buy_btn";
string OBJ_CANCEL_BTN = "psc_cancel_btn";
string OBJ_PLACE_BTN  = "psc_place_btn";
string OBJ_RESULT     = "psc_result";
string OBJ_RISK_LINE  = "psc_risk_line";

string LINE_ENTRY = "psc_entry";
string LINE_SL    = "psc_sl";
string LINE_TP    = "psc_tp";

// ------------------- State -------------------
bool   gUseRiskPercent = true;
bool   gUsePendingOrder = false;
int    gDirection = 0; // +1=buy, -1=sell, 0=none

//+------------------------------------------------------------------+
//| Utility                                                           |
//+------------------------------------------------------------------+
double PipSize(string sym=NULL)
{
   if(sym==NULL || sym=="") sym = Symbol();
   int digits = (int)MarketInfo(sym, MODE_DIGITS);

   if(StringFind(sym, "XAU", 0)==0 || StringFind(sym, "GOLD", 0)==0)
      return(Point * 10.0);

   if(digits==5 || digits==4) return(0.0001);
   if(digits==3 || digits==2) return(0.01);
   return(Point);
}

void DeleteObjectIfExists(string name)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
}

void CreateRectLabel(string name, int x, int y, int w, int h, color bg, color border)
{
   DeleteObjectIfExists(name);
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void CreateButton(string name, int x, int y, int w, int h, string txt)
{
   DeleteObjectIfExists(name);
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_COLOR, TextColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 11);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
}

void CreateEdit(string name, int x, int y, int w, int h, string val)
{
   DeleteObjectIfExists(name);
   ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_COLOR, TextColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 11);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_READONLY, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_TEXT, val);
}

void CreateLabel(string name, int x, int y, string txt, int size=11, color clr=clrBlack)
{
   DeleteObjectIfExists(name);
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
}

void CreateTradeLine(string name, double price, color clr)
{
   DeleteObjectIfExists(name);
   if(ObjectCreate(0, name, OBJ_HLINE, 0, 0, price))
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
}

bool ParseModeValue(double &outVal)
{
   string s = ObjectGetString(0, OBJ_MODE_EDIT, OBJPROP_TEXT);
   outVal = StrToDouble(s);
   if(outVal <= 0) return false;
   return true;
}

void UpdateModeCaptions()
{
   ObjectSetString(0, OBJ_MODE_BTN, OBJPROP_TEXT, gUseRiskPercent ? "Risk %" : "Fixed lots");
   ObjectSetString(0, OBJ_ORDER_BTN, OBJPROP_TEXT, gUsePendingOrder ? "pending order" : "market order");

   double v = gUseRiskPercent ? DefaultRiskPercent : DefaultFixedLots;
   string shown = ObjectGetString(0, OBJ_MODE_EDIT, OBJPROP_TEXT);
   if(shown == "" || StrToDouble(shown) <= 0)
   {
      ObjectSetString(0, OBJ_MODE_EDIT, OBJPROP_TEXT, gUseRiskPercent ? DoubleToString(v,1) : DoubleToString(v,2));
   }
}

void BuildPanel()
{
   CreateRectLabel(OBJ_BG, P_X, P_Y, P_W, P_H, PanelFillColor, PanelBorderColor);

   CreateButton(OBJ_MODE_BTN,  P_X+12,  P_Y+18, 70, 28, "Risk %");
   CreateEdit  (OBJ_MODE_EDIT, P_X+88,  P_Y+18, 36, 28, DoubleToString(DefaultRiskPercent,1));
   CreateButton(OBJ_ORDER_BTN, P_X+198, P_Y+18, 100, 28, "market order");

   CreateButton(OBJ_SELL_BTN,  P_X+12,  P_Y+68, 112, 52, "Sell");
   CreateButton(OBJ_BUY_BTN,   P_X+198, P_Y+68, 100, 52, "Buy");

   CreateButton(OBJ_CANCEL_BTN,P_X+12,  P_Y+136, 140, 58, "cancel");
   CreateButton(OBJ_PLACE_BTN, P_X+174, P_Y+136, 124, 58, "place order");

   CreateLabel (OBJ_RESULT,    P_X+14,  P_Y+210, "Lots:0.00 | sl : 0 points\nActual Risk:0.00", 12, ResultColor);
   UpdateModeCaptions();
}

void ClearTradeLines()
{
   DeleteObjectIfExists(LINE_ENTRY);
   DeleteObjectIfExists(LINE_SL);
   DeleteObjectIfExists(LINE_TP);
   gDirection = 0;
   ObjectSetString(0, OBJ_RESULT, OBJPROP_TEXT, "Lots:0.00 | sl : 0 points\nActual Risk:0.00");
}

void SetupLinesForDirection(int dir)
{
   gDirection = dir;
   double ask = MarketInfo(Symbol(), MODE_ASK);
   double bid = MarketInfo(Symbol(), MODE_BID);
   double base = (dir>0 ? ask : bid);
   double pip = PipSize();

   double entry = base;
   double sl = base - (dir*DefaultSLOffsetPips*pip);
   double tp = base + (dir*DefaultTPOffsetPips*pip);

   if(gUsePendingOrder)
      entry = base - (dir*3.0*pip);

   CreateTradeLine(LINE_ENTRY, NormalizeDouble(entry, Digits), clrRoyalBlue);
   CreateTradeLine(LINE_SL,    NormalizeDouble(sl, Digits),    clrCrimson);
   CreateTradeLine(LINE_TP,    NormalizeDouble(tp, Digits),    clrLimeGreen);
}

double CalculateLotsAndRisk(double &slPoints, double &actualRisk)
{
   slPoints = 0;
   actualRisk = 0;

   if(ObjectFind(0, LINE_ENTRY)<0 || ObjectFind(0, LINE_SL)<0)
      return 0.0;

   double entry = ObjectGetDouble(0, LINE_ENTRY, OBJPROP_PRICE);
   double sl    = ObjectGetDouble(0, LINE_SL, OBJPROP_PRICE);

   double stopDistance = MathAbs(entry - sl);
   if(stopDistance <= 0) return 0.0;

   slPoints = stopDistance / Point;

   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
   if(tickValue<=0 || tickSize<=0) return 0.0;

   double valuePerPriceUnitPerLot = tickValue / tickSize;
   double riskPerLot = stopDistance * valuePerPriceUnitPerLot;
   if(riskPerLot <= 0) return 0.0;

   double step   = MarketInfo(Symbol(), MODE_LOTSTEP); if(step<=0) step = 0.01;
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);

   double lots = 0;
   double modeVal = 0;
   if(!ParseModeValue(modeVal)) return 0.0;

   if(gUseRiskPercent)
   {
      double riskMoney = AccountBalance() * modeVal / 100.0;
      lots = riskMoney / riskPerLot;
   }
   else
   {
      lots = modeVal;
   }

   lots = MathFloor(lots/step)*step;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;

   int lotDigits = (int)MathMax(0, MathRound(-MathLog10(step)));
   lots = NormalizeDouble(lots, lotDigits);

   actualRisk = lots * riskPerLot;
   return lots;
}

void UpdateRealtimePanel()
{
   double slPts, actualRisk;
   double lots = CalculateLotsAndRisk(slPts, actualRisk);

   string txt = "Lots:" + DoubleToString(lots,2) +
                " | sl : " + DoubleToString(slPts,0) + " points" +
                "\nActual Risk:" + DoubleToString(actualRisk,2);

   ObjectSetString(0, OBJ_RESULT, OBJPROP_TEXT, txt);
}

int PendingTypeFromDirection(int dir, double entry, double bid, double ask)
{
   if(dir > 0)
      return (entry < ask ? OP_BUYLIMIT : OP_BUYSTOP);
   return (entry > bid ? OP_SELLLIMIT : OP_SELLSTOP);
}

void PlaceOrderNow()
{
   if(gDirection == 0)
   {
      ObjectSetString(0, OBJ_RESULT, OBJPROP_TEXT, "Lots:0.00 | sl : 0 points\nActual Risk:0.00");
      return;
   }

   if(ObjectFind(0, LINE_ENTRY)<0 || ObjectFind(0, LINE_SL)<0 || ObjectFind(0, LINE_TP)<0)
      return;

   double slPts, actualRisk;
   double lots = CalculateLotsAndRisk(slPts, actualRisk);
   if(lots <= 0)
   {
      ObjectSetString(0, OBJ_RESULT, OBJPROP_TEXT, "Lots invalid. Check mode value/SL.");
      return;
   }

   RefreshRates();
   double bid = MarketInfo(Symbol(), MODE_BID);
   double ask = MarketInfo(Symbol(), MODE_ASK);

   double entry = NormalizeDouble(ObjectGetDouble(0, LINE_ENTRY, OBJPROP_PRICE), Digits);
   double sl    = NormalizeDouble(ObjectGetDouble(0, LINE_SL, OBJPROP_PRICE), Digits);
   double tp    = NormalizeDouble(ObjectGetDouble(0, LINE_TP, OBJPROP_PRICE), Digits);

   int type;
   double price;

   if(gUsePendingOrder)
   {
      type = PendingTypeFromDirection(gDirection, entry, bid, ask);
      price = entry;
   }
   else
   {
      type = (gDirection > 0 ? OP_BUY : OP_SELL);
      price = (gDirection > 0 ? ask : bid);
   }

   int slippage = 3;
   int ticket = OrderSend(Symbol(), type, lots, price, slippage, sl, tp, "CalcOrder", MagicNumber, 0, clrNONE);

   if(ticket < 0)
   {
      int err = GetLastError();
      ObjectSetString(0, OBJ_RESULT, OBJPROP_TEXT, "OrderSend failed. Error: " + IntegerToString(err));
      ResetLastError();
      return;
   }

   ObjectSetString(0, OBJ_RESULT, OBJPROP_TEXT,
      "Placed ticket: " + IntegerToString(ticket) +
      "\nLots:" + DoubleToString(lots,2) + " Risk:" + DoubleToString(actualRisk,2));
}

void DeletePanel()
{
   DeleteObjectIfExists(OBJ_BG);
   DeleteObjectIfExists(OBJ_MODE_BTN);
   DeleteObjectIfExists(OBJ_MODE_EDIT);
   DeleteObjectIfExists(OBJ_ORDER_BTN);
   DeleteObjectIfExists(OBJ_SELL_BTN);
   DeleteObjectIfExists(OBJ_BUY_BTN);
   DeleteObjectIfExists(OBJ_CANCEL_BTN);
   DeleteObjectIfExists(OBJ_PLACE_BTN);
   DeleteObjectIfExists(OBJ_RESULT);
   DeleteObjectIfExists(OBJ_RISK_LINE);
   ClearTradeLines();
}

//+------------------------------------------------------------------+
//| Expert lifecycle                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   BuildPanel();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   DeletePanel();
}

void OnTick()
{
   UpdateRealtimePanel();
}

void OnTimer()
{
   UpdateRealtimePanel();
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == OBJ_MODE_BTN)
      {
         gUseRiskPercent = !gUseRiskPercent;
         if(gUseRiskPercent)
            ObjectSetString(0, OBJ_MODE_EDIT, OBJPROP_TEXT, DoubleToString(DefaultRiskPercent,1));
         else
            ObjectSetString(0, OBJ_MODE_EDIT, OBJPROP_TEXT, DoubleToString(DefaultFixedLots,2));
         UpdateModeCaptions();
      }
      else if(sparam == OBJ_ORDER_BTN)
      {
         gUsePendingOrder = !gUsePendingOrder;
         UpdateModeCaptions();
      }
      else if(sparam == OBJ_SELL_BTN)
      {
         SetupLinesForDirection(-1);
      }
      else if(sparam == OBJ_BUY_BTN)
      {
         SetupLinesForDirection(1);
      }
      else if(sparam == OBJ_CANCEL_BTN)
      {
         ClearTradeLines();
      }
      else if(sparam == OBJ_PLACE_BTN)
      {
         PlaceOrderNow();
      }
   }

   if(id == CHARTEVENT_OBJECT_DRAG)
   {
      if(sparam == LINE_ENTRY || sparam == LINE_SL || sparam == LINE_TP)
         UpdateRealtimePanel();
   }

   if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == OBJ_MODE_EDIT)
   {
      double tmp;
      if(!ParseModeValue(tmp))
      {
         if(gUseRiskPercent)
            ObjectSetString(0, OBJ_MODE_EDIT, OBJPROP_TEXT, DoubleToString(DefaultRiskPercent,1));
         else
            ObjectSetString(0, OBJ_MODE_EDIT, OBJPROP_TEXT, DoubleToString(DefaultFixedLots,2));
      }
      UpdateRealtimePanel();
   }
}
//+------------------------------------------------------------------+
