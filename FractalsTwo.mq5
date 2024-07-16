//MAYBE THIS CODE WILL GIVE US GOOD PROFITS, MODIFY
//STOP INFINITE ORDERS I DON'T KNOW IN A SECOND ARCHIVE FOR SECURITY
#include <Trade/Trade.mqh>

CTrade trade;

input ENUM_TIMEFRAMES timeframe = PERIOD_M5;

int barsTotal;
int fractalHandle;
int data;
int maDef;
int alligatorDef;
double lots = 0.1;
double slPoints = 65;
double tpPoints = 65;
double maArray[];
MqlRates priceArray[];
double fracUpArray[], fracDownArray[];
double jawsArray[], teethArray[], lipsArray[];

ulong postTicket;

int OnInit() {

   fractalHandle = iFractals(_Symbol, timeframe);
   barsTotal = iBars(_Symbol, timeframe);
   data=CopyRates(_Symbol,timeframe,0,3,priceArray);
   maDef=iMA(_Symbol,timeframe,50,0,MODE_EMA,PRICE_CLOSE);
   alligatorDef=iAlligator(_Symbol,timeframe,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {
   int bars = iBars(_Symbol, timeframe);
   
     //with barsTotal= bars; the orders are less and less profitable than without the code line
     //interesting...
     
     ArraySetAsSeries(fracUpArray,true);
     ArraySetAsSeries(fracDownArray,true);
     ArraySetAsSeries(jawsArray,true);
     ArraySetAsSeries(teethArray,true);
     ArraySetAsSeries(lipsArray,true);
     
     CopyBuffer(fractalHandle, UPPER_LINE,2,1,fracUpArray);
     CopyBuffer(fractalHandle, LOWER_LINE,2,1,fracDownArray);
     CopyBuffer(alligatorDef,0,0,3,jawsArray);
     CopyBuffer(alligatorDef,1,0,3,teethArray);
     CopyBuffer(alligatorDef,2,0,3,lipsArray);
     CopyBuffer(maDef,0,0,3,maArray);
     
     double fracUpValue=NormalizeDouble(fracUpArray[0],5);
     double fracDownValue=NormalizeDouble(fracDownArray[0],5);
     double closingPrice=priceArray[0].close;
     double maValue=NormalizeDouble(maArray[0],6);
     double jawsValue=NormalizeDouble(jawsArray[0],5);
     double teethValue=NormalizeDouble(teethArray[0],5);
     double lipsValue=NormalizeDouble(lipsArray[0],5);
     
     bool isBuy=false;
     bool isSell=false;
     
     ArraySetAsSeries(priceArray,true);
     ArraySetAsSeries(maArray,true);
     
     CopyBuffer(maDef,0,0,3,maArray);
     
     /*STRATEGY ONE: Fractals highs and lows
     Lower arrow --> Fractals Low 
     Upper arrow --> Fractals High
     */
     if(fracUpValue==EMPTY_VALUE){
       fracUpValue=0;
     }
     if(fracDownValue==EMPTY_VALUE){
       fracDownValue=0;
     }
     
     if(fracUpValue>0){
       
       if(postTicket>0){
         if(PositionSelectByTicket(postTicket)){
           if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
             if(trade.PositionClose(postTicket)){
               postTicket=0;
             }
           }
         }else{
           postTicket=0;
         }
       }
       if(postTicket<=0){
         isBuy=true; //buying
       
         double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double sl=ask-slPoints*_Point;
         double tp=ask+tpPoints*_Point;
       
         if(trade.Buy(lots,_Symbol,ask,sl,tp)){
           postTicket=trade.ResultOrder();
         }
       }
       
     }
     if(fracDownValue>0){
       
       if(postTicket>0){
         if(PositionSelectByTicket(postTicket)){
           if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
             if(trade.PositionClose(postTicket)){
               postTicket=0;
             }
           }
         }else{
           postTicket=0;
         }
       }
       if(postTicket<=0){
        
         isSell=true; //selling
       
         double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         double sl=bid+slPoints*_Point;
         double tp=bid-tpPoints*_Point;
       
         if(trade.Sell(lots,_Symbol,bid,sl,tp)){
           postTicket=trade.ResultOrder();
         }
       }
       
     }
    
     /*STRATEGY TWO: Fractals with MA
     The closing price > MA and Lower arrow generated --> buy signal
     The closing price < MA and Higher arrow generated --> sell signal
     */
     if(closingPrice<maValue && fracDownValue!=EMPTY_VALUE){
       if(postTicket>0){
         if(PositionSelectByTicket(postTicket)){
           if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
             if(trade.PositionClose(postTicket)){
               postTicket=0;
             }
           }
         }else{
           postTicket=0;
         }
       }
       if(postTicket<=0){
         isBuy=true; //buying
       
         double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double sl=ask-slPoints*_Point;
         double tp=ask+tpPoints*_Point;
       
         if(trade.Buy(lots,_Symbol,ask,sl,tp)){
           postTicket=trade.ResultOrder();
         }
       }
     }
     if(closingPrice>maValue && fracUpValue!=EMPTY_VALUE){
       if(postTicket>0){
         if(PositionSelectByTicket(postTicket)){
           if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
             if(trade.PositionClose(postTicket)){
               postTicket=0;
             }
           }
         }else{
           postTicket=0;
         }
       }
       if(postTicket<=0){
         isSell=true; //selling
       
         double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         double sl=bid+slPoints*_Point;
         double tp=bid-tpPoints*_Point;
       
         if(trade.Sell(lots,_Symbol,bid,sl,tp)){
           postTicket=trade.ResultOrder();
         }
       }
     }
     
     //STRATEGY THREE: Fractals with Alligator
     //The lips > the teeth and the jaws, the teeth > the jaws, the closing price > the teeth, and the Fractals signal is a lower arrow --> buy signal
     //The lips < the teeth and the jaws, the teeth < the jaws, the closing price < the teeth, and the Fractals signal is an upper arrow --> sell signal
     
     if(lipsValue>teethValue && lipsValue>jawsValue && teethValue>jawsValue
       && closingPrice>teethValue && fracDownValue != EMPTY_VALUE){
       
       if(postTicket>0){
         if(PositionSelectByTicket(postTicket)){
           if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
             if(trade.PositionClose(postTicket)){
               postTicket=0;
             }
           }
         }else{
           postTicket=0;
         }
       }
       if(postTicket<=0){
         isBuy=true; //buying
       
         double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double sl=ask-slPoints*_Point;
         double tp=ask+tpPoints*_Point;
       
         if(trade.Buy(lots,_Symbol,ask,sl,tp)){
           postTicket=trade.ResultOrder();
         }
       }
     }
     if(lipsValue<teethValue && lipsValue<jawsValue && teethValue<jawsValue 
       && closingPrice<teethValue && fracUpValue != EMPTY_VALUE){
       if(postTicket>0){
         if(PositionSelectByTicket(postTicket)){
           if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
             if(trade.PositionClose(postTicket)){
               postTicket=0;
             }
           }
         }else{
           postTicket=0;
         }
       }
       if(postTicket<=0){
         isSell=true; //selling
       
         double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         double sl=bid+slPoints*_Point;
         double tp=bid-tpPoints*_Point;
       
         if(trade.Sell(lots,_Symbol,bid,sl,tp)){
           postTicket=trade.ResultOrder();
         }
       }
     }
     
   
}

/* 
   if(trade.Buy(Lotsss,_Symbol,entry,sl,tp)){
     posTicket=trade.ResultOrder();
   }
*/
