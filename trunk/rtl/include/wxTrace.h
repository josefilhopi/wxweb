/*
 * WxWeb Project source code:
 * for xHarbour & Harbour Compiler
 *
 * Original ideia by Vailton Renato
 * 14/05/2006 09:40:24
 */
#ifdef WEB_DEBUG
   #undef HB_TRACE
   #undef HB_TRACEEX
   
   #define HB_TRACE(l,x)   (wxTraceLog x);
   #define HB_TRACEEX(l,x) (wxTraceLog x);

//   #define HB_TRACE(l,x)   (printf x);printf("\n");
//   #define HB_TRACEEX(l,x) (printf x);printf("\n");

//   #define HB_TRACE(l,x) ;
//   #define HB_TRACEEX(l,x);

   extern HB_EXPORT void wxTraceLog( const char * sTraceMsg, ... );
   extern void wxTraceInit( void );
   extern void wxTraceExit( void );
#else
   #undef HB_TRACE
   #undef HB_TRACEEX

   #define HB_TRACE(l,x) ;
   #define HB_TRACEEX(l,x);

   #define wxTraceLog(l,x);
   #define wxTraceInit();
   #define wxTraceExit();
#endif
