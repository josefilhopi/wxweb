/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 11/12/2006 08:44:57
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxTime.h
 *                            
 *  Rotinas diversas sobre Data e Hora
 *
 *---------------------------------------------------------------------------*/
typedef struct 
{
  int wYear;
  int wMonth;
  int wDay;
  int wDayOfWeek;
  int wHour;
  int wMinute;
  int wSeconds;
  int wMilliseconds;
} TUCTTimeStruct;

typedef TUCTTimeStruct * PUCTTimeStruct;

WX_RES wxGetUCTTime( PUCTTimeStruct pTime );
char * wxGetUCTTimeAsGMT( PUCTTimeStruct pTime );
WX_RES wxAddSeconds( PUCTTimeStruct pTime, LONG Seconds );
WX_RES wxAddDays( PUCTTimeStruct pTime, int Days );
