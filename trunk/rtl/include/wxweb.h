/*
 * WxWeb Project source code:
 * for xHarbour & Harbour Compiler
 *
 * Original ideia by Vailton Renato
 * 14/05/2006 09:40:24
 */
/**
#define HB_THREAD_SUPPORT
#define HB_THREAD_OPTIMIZE_STACK
/**/
#ifndef WXWEB
   #define WXWEB
   
   //#define WEB_DEBUG
   #define WX_RES      int
   #define WX_PTR      void * 
   #define CALC_LEN   (-1)
   #define WX_EXPIRES { 59, 31, 110 }
                     // 09  01   10        - 10/01/2009  
         
   #include "wxWebFramework.ch" 
#endif
