/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 15/07/2008 - 09:28:42
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxWebCGI.c
 *                            
 *  Rotinas diversas para controle e gerenciamento de memoria
 *
 *---------------------------------------------------------------------------*/
#include <wxweb.h>
#include <wxConnManager.h>
#include "hbapi.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbapifs.h"

#ifdef HB_OS_WIN
   #include <windows.h>
#endif
#include <stdlib.h>
#include <wxTrace.h>

/*
 * Funcao auxiliar para alguns wrappers
 * 05/10/2008 - 16:01:59
 */
static
char * wxMakeRepeaterResult( char *Buffer, int nCount )
{   
   char *szText, *Ptr;
   int   nSize;
   
   if (nCount < 1)
      nCount = 1;
         
   nSize  = strlen( Buffer ) * nCount;
   szText = (char *) hb_xgrab( nSize +1 );
   Ptr    = szText;
   
   szText[0] = '\0';
   
   for (nSize=1; nSize <= nCount; nSize ++ )
       strcat( szText, Buffer );

   return Ptr;     
} 

/*
 * Funcao auxiliar para alguns wrappers
 * 05/10/2008 - 16:01:59
 */
static
char * wxMakeWrapperResultFormatted( char *Tag, char *Text, ULONG *Length )
{
   char *Buff, *Ptr;
   ULONG Size;
   int   Len = strlen( Tag );
      
   if ( !Text || Length < 1 )
   {
     *Length = (Len*2) + 6;
      Buff   = (char *) hb_xgrab( *Length + 1 );
     *Buff   = '\0'; 
      sprintf( Buff, "<%s></%s>", Tag, Tag );
      return Buff;
   }   
   
   Size = Len + hb_parclen(1) + Len + 5; /* <></> */
   Buff = (char *) hb_xgrab( Size +1 );
   Ptr  = Buff;   
   Buff[Size] = '\0';   
   
   sprintf( Buff, "<%s>", Tag );
   Buff += 2 + Len;
   
   memcpy( Buff, Text, *Length );
   Buff += *Length;
       
   sprintf( Buff, "</%s>", Tag );   
  *Length = Size;              
   return Ptr;     
} 

/*
 * Returns/writes HTML Line Break tag <br>.
 * 05/10/2008 - 12:04:05
 */
HB_FUNC( BR )
{
   hb_retcAdopt( wxMakeRepeaterResult( "<br>", hb_parni(1) ));     
}

/*
 * Returns/writes HTML space tag &nbsp;
 * 05/10/2008 - 17:13:47
 */
HB_FUNC( NBSP )
{
   hb_retcAdopt( wxMakeRepeaterResult( "&nbsp;", hb_parni(1) ));     
}

/*
 * Returns/writes Carriage Return / Line Feed
 * 05/10/2008 - 17:24:09
 */
HB_FUNC( CR )
{
   hb_retcAdopt( wxMakeRepeaterResult( "\r\n", hb_parni(1) ));     
}

/*
 * Returns/writes HTML horizontal line tag <HR>
 * 05/10/2008 - 17:28:14
 */
HB_FUNC( HR )
{
   hb_retc( "<hr />");     
}

/*
 * Returns/writes wrapper for Big font tag <Big>Text</Big>
 * 05/10/2008 - 15:43:43
 */
HB_FUNC( BIG )
{
   ULONG Size = hb_parclen(1);
   char *Text = wxMakeWrapperResultFormatted( "big", hb_parc(1), &Size );
   hb_retclenAdopt( Text, Size );     
}
/*
 * Returns/writes wrapper Small font tags <Small>
 * 05/10/2008 - 15:43:43
 */
HB_FUNC( SMALL )
{
   ULONG Size = hb_parclen(1);
   char *Text = wxMakeWrapperResultFormatted( "small", hb_parc(1), &Size );
   hb_retclenAdopt( Text, Size );     
}
 
/*
 * Returns/writes scrolling message.
 * 05/10/2008 - 16:34:50
 */
HB_FUNC( MARQUEE )
{
   ULONG Size = hb_parclen(1);
   char *Text = wxMakeWrapperResultFormatted( "marquee", hb_parc(1), &Size );
   hb_retclenAdopt( Text, Size );     
}
 
/*
 * HREF( <cUrl>[, <text>] )
 * Cria um tag HREF baseada nos parametros passados como argumento.
 * 24/10/2008 - 19:25:49
 */
HB_FUNC( HREF )
{
   char *Text1 = hb_parc(1);
   char *Text2 = hb_parc(2);
   ULONG Size1 = hb_parclen(1);
   ULONG Size2 = hb_parclen(2);
   ULONG Length= Size1 + Size2 + ((Text1) ? 24L : 15L );
    
   char *Result = (char *) hb_xgrab( Length );
   
  *Result = '\0';    
   Length = sprintf( Result, "<a href=\"%s\">%s</a>", Text1, Text2 );
   
   hb_retclenAdopt( Result, Length );     
}