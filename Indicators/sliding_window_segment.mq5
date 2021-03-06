//+------------------------------------------------------------------+
//|                                       sliding_window_segment.mq5 |
//| sliding window segment                    Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 1
#property indicator_plots 1

#property indicator_type1         DRAW_SECTION
#property indicator_color1        clrGold
#property indicator_width1 2


double SEG1[];

input int InpMaxRange=1000; // MaxRange
input double InpMaxError=5; // MaxError(Point)
double MaxError=InpMaxError*_Point;

int min_rates_total=InpMaxRange+2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   SetIndexBuffer(0,SEG1,INDICATOR_DATA);
//---
   return(0);

  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int i,first;
   if(rates_total<=min_rates_total) return(0);
//---
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;
   else   ArrayFill(SEG1,0,begin_pos+1,EMPTY_VALUE);

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      SEG1[i]=EMPTY_VALUE;
      if(i<rates_total-1)continue;

      int calc_start=i-InpMaxRange;
      int calc_end=i-1;

      //---
      double result[][4];
      int sz=0;
      ArrayResize(result,0,InpMaxRange);
      //---
      while(!IsStopped())
        {
         double x0,y0,x1,y1;
         //---
         int iend=calc_start;
         //---
         create_segment(x0,y0,x1,y1,close,calc_start,calc_end);
         //---
         double err=0;
         while(iend<calc_end)
           {
            double x0_,y0_,x1_,y1_;
            iend++;
            create_segment(x0_,y0_,x1_,y1_,close,calc_start,iend);

            err=compute_error(close,x0_,x1_);
            if(err<=MaxError)
              {
               x0=x0_;
               y0=y0_;
               x1=x1_;
               y1=y1_;
              }
            else
               break;

           }
         ArrayResize(result,sz+1,InpMaxRange);
         result[sz][0]=x0;
         result[sz][1]=y0;
         result[sz][2]=x1;
         result[sz][3]=y1;

         sz++;
         if(iend>=calc_end)break;
         calc_start=iend;

        }
      for(int n=0;n<sz;n++)
        {
         SEG1[int(result[n][0])]=result[n][1];
         SEG1[int(result[n][2])]=result[n][3];
        }
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
void create_segment(double  &x0,double  &y0,double  &x1,double  &y1,const double &close[],const int istart,const int iend)
  {
   x0=istart;
   y0=close[istart];
   x1=iend;
   y1=close[iend];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double compute_error(const double  &close[],const double x0,const double x1)
  {
   double X[];
   double Y[];
   int sz=int(x1-x0)+1;
   ArrayResize(X,sz);
   ArrayResize(Y,sz);
   int n=0;
   for(int x=int(x0);x<=int(x1);x++)
     {
      Y[n]=close[x];
      n++;
     }
//--
   double a=0;
   double b=0;
//--
   regression(a,b,Y,sz);
//-- residuals
   double yy=b;
   double s=0;
   for(n=0;n<sz;n++)
     {
      s+=pow(Y[n]-yy,2);
      yy+=a;

     }
   return s;

  }
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
void regression(double  &a,double  &b,const double  &Y[],const int cnt)
  {
//--- 
   double sumy=0.0; double sumx=0.0; double sumxy=0.0; double sumx2=0.0;
   int x=1;

//--- 
   for(int n=0; n<cnt; n++)
     {
      //---
      sumx+=(n+1);
      sumx2+= (n+1)*(n+1);
      sumy += Y[n];
      sumxy+= Y[n]*(n+1);

     }
//---
   double c=sumx2*cnt-sumx*sumx;
   if(c==0.0)
     {
      a=0.0;
      b=sumy/cnt;
     }
   else
     {
      a=(sumxy*cnt-sumx*sumy)/c;
      b=(sumy-sumx*a)/cnt;
     }
  }
//+------------------------------------------------------------------+
