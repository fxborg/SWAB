//+------------------------------------------------------------------+
//|                                            bottom_up_segment.mq5 |
//| Bottom-up Segment                         Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <Arrays\ArrayDouble.mqh> 
#include <Arrays\ArrayObj.mqh> 

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1         DRAW_SECTION
#property indicator_color1        clrRed
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
      //---
      CArrayObj    *segments=new CArrayObj;
      CArrayObj    *mergesegments=new CArrayObj;
      CArrayDouble *item;
      CArrayDouble *mergecosts=new CArrayDouble;
      //---
      int n=0;
      for(int j=(i-InpMaxRange-1);j<i;j++)
        {
         item=new CArrayDouble;
         item.Add(j-1);
         item.Add(close[j-1]);
         item.Add(j);
         item.Add(close[j]);
         segments.Add(item);
        }
      for(n=0;n<InpMaxRange;n++)
        {
         double x0,y0,x1,y1;
         int a=int( ((CArrayDouble *)segments.At(n)).At(0) );
         int b=int( ((CArrayDouble *)segments.At(n+1)).At(2) );
         create_segment(x0,y0,x1,y1,close,a,b);
         item=new CArrayDouble;
         item.Add(x0);
         item.Add(y0);
         item.Add(x1);
         item.Add(y1);
         mergesegments.Add(item);
         mergecosts.Add(compute_error(close,x0,x1));
        }


      while(true)
        {
         int idx=mergecosts.Minimum(0,mergecosts.Total());
         if(mergecosts.At(idx)>=MaxError)break;
         ((CArrayDouble *)segments.At(idx)).Update(0,( (CArrayDouble *)mergesegments.At(idx)).At(0));
         ((CArrayDouble *)segments.At(idx)).Update(1,( (CArrayDouble *)mergesegments.At(idx)).At(1));
         ((CArrayDouble *)segments.At(idx)).Update(2,( (CArrayDouble *)mergesegments.At(idx)).At(2));
         ((CArrayDouble *)segments.At(idx)).Update(3,( (CArrayDouble *)mergesegments.At(idx)).At(3));

         segments.Delete(idx+1);

         if(idx>0)
           {
            int a=int( ((CArrayDouble *)segments.At(idx-1)).At(0) );
            int b=int( ((CArrayDouble *)segments.At(idx)).At(2) );
            double x0,y0,x1,y1;

            create_segment(x0,y0,x1,y1,close,a,b);
            ((CArrayDouble *)mergesegments.At(idx-1)).Update(0,x0);
            ((CArrayDouble *)mergesegments.At(idx-1)).Update(1,y0);
            ((CArrayDouble *)mergesegments.At(idx-1)).Update(2,x1);
            ((CArrayDouble *)mergesegments.At(idx-1)).Update(3,y1);
            mergecosts.Update(idx-1,compute_error(close,x0,x1));

           }

         else if(idx+1<mergecosts.Total())
           {
            int a=int( ((CArrayDouble *)segments.At(idx)).At(0) );
            int b=int( ((CArrayDouble *)segments.At(idx+1)).At(2) );
            double x0,y0,x1,y1;
            create_segment(x0,y0,x1,y1,close,a,b);
            ((CArrayDouble *)mergesegments.At(idx+1)).Update(0,x0);
            ((CArrayDouble *)mergesegments.At(idx+1)).Update(1,y0);
            ((CArrayDouble *)mergesegments.At(idx+1)).Update(2,x1);
            ((CArrayDouble *)mergesegments.At(idx+1)).Update(3,y1);
            mergecosts.Update(idx+1,compute_error(close,x0,x1));

           }

         mergesegments.Delete(idx);
         mergecosts.Delete(idx);

        }

      for(int j=0;j<mergecosts.Total();j++)
        {
         int idx0=int(((CArrayDouble *)segments.At(j)).At(0));
         SEG1[idx0]=((CArrayDouble *)segments.At(j)).At(1);
         int idx1=int(((CArrayDouble *)segments.At(j)).At(2));
         SEG1[idx1]=((CArrayDouble *)segments.At(j)).At(3);
        }
      delete mergesegments;
      delete mergecosts;
      delete segments;
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
