#property strict
#property copyright "COPYRIGHT 2026, KALIFX TRADE MANAGER"
#property link      "www.kalifxlab.com"
#property version   "1.00"
#property description "Kalifx Trade Manager (MT4 port)"

// --- BE & Trailing Inputs
input string sepBE                     = "=== BreakEven Settings ===";
input bool   EnableBE                  = true;
input double BE_TP_Percent             = 60.0;
input int    BE_OffsetPoints           = 20;
input int    StartBE_ButtonOffsetPoints= 10;

input string sepTS1                    = "=== Trailing Stop (Points-Based) ===";
input bool   EnableTrailingPoints      = false;
input int    TS_StartPoints            = 300;
input int    TS_StepPoints             = 50;
input int    TS_StopPoints             = 150;

input string sepTS2                    = "=== Trailing Stop (% of TP Based) ===";
input bool   EnableTrailingPercent     = false;
input double TS_StartTPPercent         = 60.0;
input int    TS_StepPoints2            = 20;
input double TS_ProfitLockPercent      = 50.0;

input string sepPanel                  = "=== Action Panel ===";
input bool   EnableActionPanel         = true;
input int    PanelX                    = 10;
input int    PanelY                    = 30;
input int    UiRefreshMs               = 100;

input int    MagicNumber               = 0;
input int    SlippagePoints            = 20;

bool g_BeRuntimeEnabled = true;
bool g_TrailingRuntimeEnabled = false;
bool g_ForceBEStart = false;
bool g_ForceTSStart = false;
bool g_TSPercentStartOverridden = false;
bool g_UseStartBEButtonOffset = false;

string PANEL2_BG     = "KFX4_PANEL2_BG";
string BTN_CLOSE_ALL = "KFX4_BTN_CLOSE_ALL";
string BTN_CLOSE_BUY = "KFX4_BTN_CLOSE_BUY";
string BTN_CLOSE_SELL= "KFX4_BTN_CLOSE_SELL";
string BTN_START_TS  = "KFX4_BTN_START_TS";
string BTN_START_BE  = "KFX4_BTN_START_BE";

int OnInit()
{
   g_BeRuntimeEnabled = EnableBE;
   g_TrailingRuntimeEnabled = (EnableTrailingPoints || EnableTrailingPercent);
   g_TSPercentStartOverridden = false;

   if(EnableActionPanel)
      CreateActionPanel();

   EventSetMillisecondTimer(MathMax(50, UiRefreshMs));
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   DeleteActionPanel();
}

void OnTick()
{
   ManageOpenOrders();
}

void OnTimer()
{
   if(!EnableActionPanel) return;
   ProcessPanelButtonStates();
   ChartRedraw();
}

void CreatePanelButton(string name,string text,int x,int y,int w,int h,color bg,color fg,int fs)
{
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,C'71,85,105');
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fs);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,1000);
}

void CreateActionPanel()
{
   DeleteActionPanel();
   int panel2Y = PanelY + 108;

   ObjectCreate(0,PANEL2_BG,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PANEL2_BG,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,PANEL2_BG,OBJPROP_XDISTANCE,PanelX);
   ObjectSetInteger(0,PANEL2_BG,OBJPROP_YDISTANCE,panel2Y);
   ObjectSetInteger(0,PANEL2_BG,OBJPROP_XSIZE,250);
   ObjectSetInteger(0,PANEL2_BG,OBJPROP_YSIZE,126);
   ObjectSetInteger(0,PANEL2_BG,OBJPROP_BGCOLOR,0x2A170F);
   ObjectSetInteger(0,PANEL2_BG,OBJPROP_COLOR,0x54422F);

   CreatePanelButton(BTN_CLOSE_ALL,"Close All",PanelX+6,panel2Y+8,237,28,0x54422F,clrWhite,11);
   CreatePanelButton(BTN_CLOSE_BUY,"Close Buy",PanelX+6,panel2Y+42,116,32,0x54422F,clrWhite,11);
   CreatePanelButton(BTN_CLOSE_SELL,"Close Sell",PanelX+127,panel2Y+42,116,32,0x54422F,clrWhite,11);
   CreatePanelButton(BTN_START_TS,"Start TS",PanelX+6,panel2Y+80,116,32,0x1E90FF,clrWhite,10);
   CreatePanelButton(BTN_START_BE,"Set BE",PanelX+127,panel2Y+80,116,32,0x1E90FF,clrWhite,10);
}

void DeleteActionPanel()
{
   ObjectDelete(0,PANEL2_BG);
   ObjectDelete(0,BTN_CLOSE_ALL);
   ObjectDelete(0,BTN_CLOSE_BUY);
   ObjectDelete(0,BTN_CLOSE_SELL);
   ObjectDelete(0,BTN_START_TS);
   ObjectDelete(0,BTN_START_BE);
}

void ProcessPanelButtonStates()
{
   if(ObjectFind(0,BTN_CLOSE_ALL)>=0 && ObjectGetInteger(0,BTN_CLOSE_ALL,OBJPROP_STATE))
   {
      ObjectSetInteger(0,BTN_CLOSE_ALL,OBJPROP_STATE,false);
      CloseAllOrders();
      return;
   }
   if(ObjectFind(0,BTN_CLOSE_BUY)>=0 && ObjectGetInteger(0,BTN_CLOSE_BUY,OBJPROP_STATE))
   {
      ObjectSetInteger(0,BTN_CLOSE_BUY,OBJPROP_STATE,false);
      CloseOrdersByType(OP_BUY);
      return;
   }
   if(ObjectFind(0,BTN_CLOSE_SELL)>=0 && ObjectGetInteger(0,BTN_CLOSE_SELL,OBJPROP_STATE))
   {
      ObjectSetInteger(0,BTN_CLOSE_SELL,OBJPROP_STATE,false);
      CloseOrdersByType(OP_SELL);
      return;
   }
   if(ObjectFind(0,BTN_START_TS)>=0 && ObjectGetInteger(0,BTN_START_TS,OBJPROP_STATE))
   {
      ObjectSetInteger(0,BTN_START_TS,OBJPROP_STATE,false);
      g_TrailingRuntimeEnabled = true;
      g_TSPercentStartOverridden = true;
      g_ForceTSStart = true;
      ManageOpenOrders();
      return;
   }
   if(ObjectFind(0,BTN_START_BE)>=0 && ObjectGetInteger(0,BTN_START_BE,OBJPROP_STATE))
   {
      ObjectSetInteger(0,BTN_START_BE,OBJPROP_STATE,false);
      g_BeRuntimeEnabled = true;
      g_UseStartBEButtonOffset = true;
      g_ForceBEStart = true;
      ManageOpenOrders();
      return;
   }
}

void ManageOpenOrders()
{
   bool hasManaged=false;
   double point = Point;

   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol()) continue;
      if(MagicNumber!=0 && OrderMagicNumber()!=MagicNumber) continue;
      if(OrderType()!=OP_BUY && OrderType()!=OP_SELL) continue;
      hasManaged=true;

      int type=OrderType();
      double open=OrderOpenPrice();
      double sl=OrderStopLoss();
      double tp=OrderTakeProfit();
      if(tp<=0) continue;

      double bid=Bid, ask=Ask;
      double distanceToTP=MathAbs(tp-open);
      double profitDistance=(type==OP_BUY)?(bid-open):(open-ask);

      if(g_BeRuntimeEnabled && (EnableBE || g_ForceBEStart))
      {
         double beTrigger = distanceToTP*BE_TP_Percent/100.0;
         if(g_ForceBEStart || profitDistance>=beTrigger)
         {
            int off=(g_UseStartBEButtonOffset?StartBE_ButtonOffsetPoints:BE_OffsetPoints);
            double newSL=(type==OP_BUY)?NormalizeDouble(open+off*point,Digits):NormalizeDouble(open-off*point,Digits);
            bool can=(type==OP_BUY)?((sl<=0||newSL>sl)&&newSL<bid):((sl<=0||newSL<sl)&&newSL>ask);
            if(can)
               OrderModify(OrderTicket(),OrderOpenPrice(),newSL,tp,0,clrNONE);
         }
      }

      if(g_TrailingRuntimeEnabled && EnableTrailingPoints)
      {
         double startDist=TS_StartPoints*point;
         if(profitDistance>=startDist)
         {
            double newSL=(type==OP_BUY)?NormalizeDouble(bid-TS_StopPoints*point,Digits):NormalizeDouble(ask+TS_StopPoints*point,Digits);
            bool can=(type==OP_BUY)?(sl<newSL-TS_StepPoints*point && newSL<bid):((sl<=0||sl>newSL+TS_StepPoints*point)&&newSL>ask);
            if(can)
               OrderModify(OrderTicket(),OrderOpenPrice(),newSL,tp,0,clrNONE);
         }
      }

      if(g_TrailingRuntimeEnabled && (EnableTrailingPercent || g_TSPercentStartOverridden || g_ForceTSStart))
      {
         double tsTrigger=distanceToTP*TS_StartTPPercent/100.0;
         if(g_TSPercentStartOverridden || g_ForceTSStart || profitDistance>=tsTrigger)
         {
            double targetSL=(type==OP_BUY)
               ? NormalizeDouble(open + (profitDistance*TS_ProfitLockPercent/100.0),Digits)
               : NormalizeDouble(open - (profitDistance*TS_ProfitLockPercent/100.0),Digits);
            bool can=(type==OP_BUY)?(sl<targetSL-TS_StepPoints2*point && targetSL<bid):((sl<=0||sl>targetSL+TS_StepPoints2*point)&&targetSL>ask);
            if(can)
               OrderModify(OrderTicket(),OrderOpenPrice(),targetSL,tp,0,clrNONE);
         }
      }
   }

   g_ForceBEStart=false;
   g_ForceTSStart=false;
   g_UseStartBEButtonOffset=false;
   if(!hasManaged)
      g_TSPercentStartOverridden=false;
}

void CloseAllOrders()
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol()) continue;
      if(MagicNumber!=0 && OrderMagicNumber()!=MagicNumber) continue;
      int t=OrderType();
      if(t==OP_BUY) OrderClose(OrderTicket(),OrderLots(),Bid,SlippagePoints,clrNONE);
      if(t==OP_SELL) OrderClose(OrderTicket(),OrderLots(),Ask,SlippagePoints,clrNONE);
   }
}

void CloseOrdersByType(int side)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol()) continue;
      if(MagicNumber!=0 && OrderMagicNumber()!=MagicNumber) continue;
      if(OrderType()!=side) continue;
      if(side==OP_BUY)  OrderClose(OrderTicket(),OrderLots(),Bid,SlippagePoints,clrNONE);
      if(side==OP_SELL) OrderClose(OrderTicket(),OrderLots(),Ask,SlippagePoints,clrNONE);
   }
}
