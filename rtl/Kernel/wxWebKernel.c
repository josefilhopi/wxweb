/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 8/12/2006 08:09:11
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxConnManager.cpp
 *                            
 *  Funções para manipulação da conexão com o cliente
 *
 *---------------------------------------------------------------------------*/

#include <wxweb.h>
#include "hbapi.h"
#include <wxmemory.h>
#include "wxBuildInfo.ch"

#ifdef HB_OS_WIN
   #include <windows.h>
#endif

HB_FUNC_EXTERN( WXWEBERRORSYS );

static int nAppMode = WEB_CGI_MODE;

/*
 * wxWebVersion()
 * Retorna o numero da versao da wxWeb atualmente em uso como uma string
 * 30/06/2008 - 14:51:29
 */
HB_FUNC( WXWEBVERSION )
{
   hb_retc( WXWEB_VERSION );
}

/*
 * wxWebVersionStr()
 * Retorna uma string com o nome da ferramenta, seguido do numero da versao da 
 * wxWeb atualmente em uso.
 * 28/10/2008 - 12:56:54
 */
HB_FUNC( WXWEBVERSIONSTR )
{
   char s[50];
   
   sprintf( s, "%s Framework: v%s", XWEB_NAME, WXWEB_VERSION );
   hb_retc( s );
}

/*
 * Retorna o tipo de aplicativo atualmente compilado. Podendo ser:
 *
 *    WEB_CGI_MODE    - O aplicativo atual foi compilado para ser
 *                      executado via CGI pelo WebServer.
 *
 *    WEB_ISAPI_MODE  - O aplicativo atual foi compilado para ser
 *                      executado via ISAPI ou NSAPI no IIS ou APACHE
 *
 *    WEB_STAND_ALONE - O aplicativo atual roda como servi‡o ou um .EXE
 *                      auto-sustentavel (ou algo assim)
 *
 * 28/04/2008 - 10:12:02
 */
HB_FUNC( WXGETAPPMODE )
{
   hb_retni( nAppMode );
}

/*
 * Altera o tipo de aplicativo em uso.
 * 30/06/2008 - 16:36:08
 */
HB_FUNC( WXSETAPPMODE )
{   
   int nNewValue = hb_parni(1);
   hb_retni( nAppMode );
   
   if ( !ISNUM(1) )
      return;
   
   nAppMode = nNewValue;
}

/*
 * Retorna o tipo de aplicativo em uso com a wxWeb. Na realidade, esta função 
 * existe apenas para segurar o REQUEST inicial de cada aplicativo.
 * 30/06/2008 - 15:20:49
 */ 
HB_FUNC( WXWEB )
{
   static bStarted = FALSE;
   
   if (bStarted)
      return;
   
   bStarted = TRUE;   
   HB_FUNCNAME( WXGETAPPMODE )();
   HB_FUNCNAME( WXWEBERRORSYS )();  // ErrorSys() padrão - 05/10/2008 - 08:38:14
}

/*
 * Retorna o nome do executavel atual. Se um argumento .T. for passado para esta
 * função, ela retornará o nome do executável atual sem PATH.
 * 30/06/2008 - 15:22:58
 */
HB_FUNC( WXEXENAME )
{
   char **argv;
   char *name;    
   char *text;
   
   int argc;
   int len;
   
   argv = hb_cmdargARGV();
   argc = hb_cmdargARGC();

   name = argv[0];
   len  = strlen( name );
   
   if (!((len>=4) && (name[0] == '\\')
                  && (name[1] == '\\')
                  && (name[2] == '?')
                  && (name[3] == '\\') ))
   {
//    text = xStrNDup( name, len );
      text = name;
   } else {
//    text = xStrNew( len );
//    memmove( text, name+4, len-4 );
//    text[len-4] = '\0';
      text += 4;
      len  -= 4;
   }
   
   /*
    * Se ele deseja apenas o nome do aplicativo, sem path processamos isto agora!
    * 29/11/2009 - 16:01:26
    */
   if ( hb_parl(1) )
   {
      char * shortname = strrchr( text, HB_OS_PATH_DELIM_CHR );
      
      if (shortname)
      {
         name = shortname +1;
         len  = strlen( shortname );
      } else {
         name = NULL;
      }
   }
   
   if (name)
   {
      text = xStrNDup( name, len );
      hb_retcAdopt( text );
   } else {
      hb_retc( "" );
   }
}

/*
 * Retorna o PATH onde o aplicativo atual está sendo executado.
 * 30/06/2008 - 16:13:08
 */
HB_FUNC( WXEXEPATH )
{
   char *text;
   char *delim;
   char *result;
   
   int len;
   int del = FALSE;
   
#if (defined(_WIN32) || defined(__WIN32__) || !defined(WIN32))
   char name[MAX_PATH+1];
     
   GetModuleFileName( NULL, name, MAX_PATH );
#else
   char **argv = hb_cmdargARGV();
   char *name  = argv[0];       
#endif   
   
   len  = strlen( name );
   
   /*
    * Testa UTF-8 ...
    */
   if (!((len>=4) && (name[0] == '\\')
                  && (name[1] == '\\')
                  && (name[2] == '?')
                  && (name[3] == '\\') ))
   {
      text = name;
   } else {
      del  = TRUE; 
      text = xStrNew( len );   
      memmove( text, name+4, len-4 );   
   
      text[len-4] = '\0';
      len  = strlen( name );
   }
   
   result = NULL;
   delim  = strrchr( text, HB_OS_PATH_DELIM_CHR );
   
   // Só processa se encontrar a string, caso contrário retornará algo nulo
   if (delim)
   {
      len    = delim - text;
      result = xStrNDup( text, len+1 );
   }

   if (del)
      hb_xfree( text );
      
   if (result)                                            
      hb_retcAdopt( result );
   else
      hb_retc("");
}

#include "wxBuildInfo.ch"
/*
 * Retorna a data em que a wxWeb foi compilada (o retorno é uma data mesmo, nao
 * um valor string).
 * 25/11/2009 - 08:29:11
 */
HB_FUNC( WXBUILDDATE )
{
   PHB_ITEM pItem = hb_itemNew( NULL );
   hb_itemPutDS( pItem, _HBMK_BUILD_DATE_ );
   hb_itemReturnRelease( pItem );
}

/*
 * Retorna o horario em que a wxWeb foi compilada, no formato HH:MM:SS
 * 25/11/2009 - 08:30:41
 */
HB_FUNC( WXBUILDTIME )
{
   const char m[] = _HBMK_BUILD_TIME_;
   char t[9];
   
   t[0] = m[0];
   t[1] = m[1];
   t[2] = ':';
   t[3] = m[2];
   t[4] = m[3];
   t[5] = ':';
   t[6] = m[4];
   t[7] = m[5];
   t[8] = '\0';
   
   hb_retc( t );
}
