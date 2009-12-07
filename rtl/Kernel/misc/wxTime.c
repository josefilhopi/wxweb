/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 11/12/2006 08:44:06
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxTime.c
 *                            
 *  Rotinas diversas sobre Data e Hora
 *
 *---------------------------------------------------------------------------*/
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbdate.h"
#include <wxweb.h>
#include <time.h>
#include <windows.h>
#include <wxTime.h>

WX_RES wxGetUCTTime( PUCTTimeStruct pTime )
{
  SYSTEMTIME stime;
  GetSystemTime(&stime);
    
  pTime->wYear          = stime.wYear;
  pTime->wMonth         = stime.wMonth;
  pTime->wDay           = stime.wDay;
  pTime->wDayOfWeek     = stime.wDayOfWeek;
  pTime->wHour          = stime.wHour;
  pTime->wMinute        = stime.wMinute;
  pTime->wSeconds       = stime.wSecond;
  pTime->wMilliseconds  = stime.wMilliseconds;
  return WX_SUCCESS;
}

/*
 * Retorna a data no formato GMT "Saturday, 31-Oct-2003 00:00:00 GMT", a função
 * que chamar esta rotina... deve liberar o buffer retornado com hb_xfree()
 * 11/12/2006 08:36:31
 */
char * wxGetUCTTimeAsGMT( PUCTTimeStruct pTime )
{
  char a[5], b[5];
  char *Temp;
  
  Temp = (char *)hb_xgrab(50);
  Temp[0]='\0';
  
  a[0]='\0';
  b[0]='\0';

  if (pTime->wDayOfWeek==0) strcat( a, "Sun");
  if (pTime->wDayOfWeek==1) strcat( a, "Mon");
  if (pTime->wDayOfWeek==2) strcat( a, "Tue");
  if (pTime->wDayOfWeek==3) strcat( a, "Wed");
  if (pTime->wDayOfWeek==4) strcat( a, "Thu");
  if (pTime->wDayOfWeek==5) strcat( a, "Fri");
  if (pTime->wDayOfWeek==6) strcat( a, "Sat");

  if (pTime->wMonth==1) strcat( b, "Jan");
  if (pTime->wMonth==2) strcat( b, "Feb");
  if (pTime->wMonth==3) strcat( b, "Mar");
  if (pTime->wMonth==4) strcat( b, "Apr");
  if (pTime->wMonth==5) strcat( b, "May");
  if (pTime->wMonth==6) strcat( b, "Jun");
  if (pTime->wMonth==7) strcat( b, "Jul");
  if (pTime->wMonth==8) strcat( b, "Aug");
  if (pTime->wMonth==9) strcat( b, "Sep");
  if (pTime->wMonth==10) strcat( b, "Oct");
  if (pTime->wMonth==11)strcat( b, "Nov"); 
  if (pTime->wMonth==12)strcat( b, "Dec" );
                                                                                                        
  sprintf(Temp, "%s, %02i-%s-%0004i %02i:%02i:%02i GMT\0", a, pTime->wDay, b, pTime->wYear, pTime->wHour, pTime->wMinute, pTime->wSeconds);
//sprintf(Temp, "%02i-%02i-%0004i %02i:%02i:%02i:%03i\0", stime.wDay, stime.wMonth, stime.wYear, stime.wHour, stime.wMinute, stime.wSeconds, stime.wMilliseconds);
  return Temp;
}
/*
static 
long TimeStr2Sec( char * pszTime )
{
   ULONG ulLen;
   ULONG ulTime = 0;

   HB_TRACE(HB_TR_DEBUG, ("TimeStr2Sec(%s)", pszTime));

   ulLen = strlen( pszTime );

   if( ulLen >= 1 )
      ulTime += ( ULONG ) hb_strVal( pszTime, ulLen ) * 3600;

   if( ulLen >= 4 )
      ulTime += ( ULONG ) hb_strVal( pszTime + 3, ulLen - 3 ) * 60;

   if( ulLen >= 7 )
      ulTime += ( ULONG ) hb_strVal( pszTime + 6, ulLen - 6 );

   return ulTime;
}
/***/
/*
 * Adiciona à data e hora atual, a qtde de segundos passadas como argumento.
 * 28/12/2006 11:26:22
 */
WX_RES wxAddSeconds( PUCTTimeStruct pTime, LONG Seconds )
{
  long nOneDaySeconds = 86400;  // 24hs * 60mins * 60secs
  long nSecs;
  int nSecsToAdd;
  int nDaysAdded;
  long uiValue;
  char pszTime[10];
                    
  if (nSecsToAdd == 0)
     return WX_SUCCESS;

  /* Converte tudo pra segundos! */ 
  nSecs      = (pTime->wHour * 3600) + (pTime->wMinute * 60) + (pTime->wSeconds);
  /* Somamos a qtde de segundos desejada */ 
  nSecs     += Seconds;  
  /* Calculamos qtos dias deve-se somar a mais na data! */
  nDaysAdded = (int ) ( nSecs / nOneDaySeconds );              
  /* Retornamos a qtde certa de segundos por dia */
  nSecs      = nSecs - nDaysAdded;

  uiValue = ( USHORT ) ( ( nSecs / 3600 ) % 24 );
  pszTime[ 0 ] = ( char ) ( uiValue / 10 ) + '0';
  pszTime[ 1 ] = ( char ) ( uiValue % 10 ) + '0';
  pszTime[ 2 ] = '\0';  

//std::cout << "wHour    " << pszTime << "" << std::endl;
  pTime->wHour  = atoi( pszTime );
   
  uiValue = ( USHORT ) ( ( nSecs / 60 ) % 60 );
  pszTime[ 0 ] = ( char ) ( uiValue / 10 ) + '0';
  pszTime[ 1 ] = ( char ) ( uiValue % 10 ) + '0';
  pszTime[ 2 ] = '\0';
  
//std::cout << "wMinute  " << pszTime << "" << std::endl;
  pTime->wMinute    = atoi( pszTime );
  
  uiValue = ( USHORT ) ( nSecs % 60 );
  pszTime[ 0 ] = ( char ) ( uiValue / 10 ) + '0';
  pszTime[ 1 ] = ( char ) ( uiValue % 10 ) + '0';
  pszTime[ 2 ] = '\0';

//std::cout << "wSeconds " << pszTime << "" << std::endl;
  pTime->wSeconds   = atoi( pszTime );  
  
  return wxAddDays( pTime, nDaysAdded );
}

/*
 * Adiciona à data e hora atual, a qtde de dias passados como argumento.
 * 28/12/2006 11:26:22
 */
WX_RES wxAddDays( PUCTTimeStruct pTime, int Days )
{
//std::cout << "bool TwxTimeStruct::AddDays( " << Days << " )" << std::endl;
   int iYear, iMonth, iDay;
   PHB_ITEM pItem;   

   if (Days == 00)                     
      return WX_SUCCESS;
   
   pItem = hb_itemNew( NULL );
   
   hb_itemPutD( pItem, pTime->wYear, pTime->wMonth, pTime->wDay );
   hb_itemPutDL( pItem, (LONG) hb_itemGetND( pItem ) + (long) Days );

   hb_dateDecode( hb_itemGetND( pItem ), &iYear, &iMonth, &iDay );

   hb_itemClear( pItem );
   hb_itemRelease( pItem );
   
   /*
    * Setamos os valores com base nas funções interna do xHB!
    */
   pTime->wYear       = iYear;
   pTime->wMonth      = iMonth;
   pTime->wDay        = iDay;
   pTime->wDayOfWeek  = (int) hb_dateDOW( iYear, iMonth, iDay );
//std::cout << iDay << "/" << iMonth << "/" << iYear << std::endl;      
   return WX_SUCCESS;
}

/*******************************************************************************
 * Retorna a data do dia no padrão UTC! 
 * 28/12/2006 11:10:07
 */
HB_FUNC(UTCDATE)
{
   TUCTTimeStruct stime;
   wxGetUCTTime( &stime );
      
   hb_retd( (long) stime.wYear, (long) stime.wMonth, (long) stime.wDay);
}

/* 
 * Retorna uma 
 * 28/12/2006 11:14:09
 */
HB_FUNC(UTCTIME)
{
   TUCTTimeStruct stime;
   char Temp[15];

   wxGetUCTTime( &stime );

   Temp[0] = '\0';
   sprintf(Temp, "%02i:%02i:%02i:%03i", stime.wHour, stime.wMinute, stime.wSeconds, stime.wMilliseconds);  
   hb_retc( Temp );
}

/*
 * Daylight saving time interval...
 * 
 * Explanation
 *    http://en.wikipedia.org/wiki/Daylight_saving_time
 *
 * Worl Map
 *    http://www.worldtimezone.com/
 *
 * 19/07/2008 - 21:06:29
 */
HB_FUNC( UCT2DSTDIFF )
{
  SYSTEMTIME stime;
  SYSTEMTIME ltime;
  BOOL Neg = FALSE;
  int Diff;
  
  GetSystemTime( &stime );
  GetLocalTime( &ltime );

  if (stime.wDay > ltime.wDay)
  {
      stime.wHour += 24;
      Neg = TRUE;
  } else {
     if (ltime.wDay > stime.wDay)
     {
         ltime.wHour += 24;
         Neg = TRUE;
     }
  }      

  if (ltime.wDay == stime.wDay)
     Neg = ( stime.wHour > ltime.wHour );
  
  Diff = stime.wHour - ltime.wHour;   
  if (Neg)
     Diff = Diff * -1;

  hb_retni( Diff );  
}
