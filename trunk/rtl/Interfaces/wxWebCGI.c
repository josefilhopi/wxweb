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
#include "hbapigt.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include "hbapifs.h"

#ifdef HB_OS_WIN
   #include <windows.h>
#endif
#include <stdlib.h>
#include <wxTrace.h>
#include <wxMT.h>

HB_FUNC_EXTERN( WXWEB );
extern WX_RES wxConnection_Init( void );

/*
 * Estrutura auxiliar para o correto funcionamento do applicativo CGI
 */
typedef struct _WebCGI_
{
   int Input;
   int OutPut;
} TWebCGI;

typedef TWebCGI *PWEBCGI;

/*
 * Esta função é para enviar os dados para o navegador (ou dispositivo) do cliente
 * 15/07/2008 - 21:52:27
 */
static
WX_RES wxWebCGI_OutPut( void *pConn, BYTE *Source, ULONG Length )
{
   PConnection pClientConn = (PConnection) pConn;
   PWEBCGI WebCGI;
   WX_RES Result;
#ifdef HB_OS_WIN
   ULONG lWritten;
   unsigned uiErrorOld = hb_fsError();    /* Save current user file error code */
   HB_TRACE( HB_TR_DEBUG, ("  wxWebCGI_OutPut(%p,%lu)  || pConn->OutPutCargo -> %p", pConn, Length, pClientConn->OutPutCargo ));

   if (!pClientConn->OutPutCargo)
      return WX_FAILURE;
      
   WebCGI   = (PWEBCGI) pClientConn->OutPutCargo;   
   lWritten = hb_fsWriteLarge( WebCGI->OutPut, Source, Length );
   
   HB_TRACE( HB_TR_DEBUG, ("                       Written --> %lu", lWritten ));
   hb_fsSetError( uiErrorOld );           /* Restore last user file error code */   
   Result = ((lWritten == Length) ? WX_SUCCESS  : WX_FAILURE );
#else
   if (phbstr)
      fwrite(Source, sizeof(char), Length, stdout);
      
   Result = WX_SUCCESS;
#endif
      
#ifdef WEB_DEBUG
   /*
    * Suporte para capturar a saida do output via modo de depuração
    * 28/10/2008 - 18:32:30
    */
   {
      FILE *log = fopen( "wxOutput.txt", "ab+" );
                  
      HB_TRACE( HB_TR_DEBUG, ("  wxWebCGI_OutPut --> Logging OutPut -> %p", log ));
      
      if (log != NULL)
      {
         fwrite(Source, sizeof(char), Length, log);
         //fwrite("\r\n", sizeof(char), 2, log);
         fclose(log);
      }
   } 
#endif
   return Result;
}

static
WX_RES wxWebCGI_Status( void *pConn, TConnectionFlag Flag, WX_PTR Cargo )
{
   PConnection pClientConn;
   PWEBCGI     pWebCGI;
   WX_RES      Result = WX_SUCCESS;

   HB_SYMBOL_UNUSED( Cargo );
   
   HB_TRACE( HB_TR_DEBUG, ("wxWebCGI_Status(%p,%d,%p)", pConn, Flag, Cargo));

   /* Convertemos os dados para a estrutura correta */
   pClientConn = (PConnection) pConn;
   
   switch (Flag)
   {
      // Evento disparado no momento em que a estrutura for iniciada 
      case cfInit:
         {
            HB_TRACE( HB_TR_DEBUG, ("  wxWebCGI_Status --> %p   ((cfInit))", pClientConn->OutPutCargo));

            pWebCGI = (PWEBCGI) hb_xgrab( sizeof(TWebCGI) );
            memset( pWebCGI, 0, sizeof(TWebCGI) );

            pClientConn->OutPutCargo = (WX_PTR) pWebCGI;
            //pClientConn->Cached      = TRUE;

#ifdef WEB_DEBUG
            {
               FILE *log = fopen( "wxOutput.txt", "w" );
               
               if (log) fclose(log);
            }
#endif

            /* Pegamos os Handles necessários para I/O */
            #if defined( HB_OS_WIN )
               pWebCGI->Input  = (int) GetStdHandle( STD_INPUT_HANDLE );
               pWebCGI->OutPut = (int) GetStdHandle( STD_OUTPUT_HANDLE );
            #else
               pWebCGI->Input  = fileno( stdin );
               pWebCGI->OutPut = fileno( stdout );
            #endif

            /* Ajustamos as variaveis do servidor */
            Result = wxServerCount( pClientConn, MAX_SERVER_VARS );
                         
            wxServerAdd( pClientConn, REQUEST_METHOD        , getenv("REQUEST_METHOD"),         CALC_LEN, "REQUEST_METHOD");                   
            wxServerAdd( pClientConn, SERVER_PROTOCOL       , getenv("SERVER_PROTOCOL"),        CALC_LEN, "SERVER_PROTOCOL");                 
            wxServerAdd( pClientConn, SERVER_URL            , getenv("SERVER_URL"),             CALC_LEN, "SERVER_URL");                           
            wxServerAdd( pClientConn, QUERY_STRING          , getenv("QUERY_STRING"),           CALC_LEN, "QUERY_STRING");                       
            wxServerAdd( pClientConn, PATH_INFO             , getenv("PATH_INFO"),              CALC_LEN, "PATH_INFO");                             
            wxServerAdd( pClientConn, PATH_TRANSLATED       , getenv("PATH_TRANSLATED"),        CALC_LEN, "PATH_TRANSLATED");                 
            wxServerAdd( pClientConn, HTTP_CACHE_CONTROL    , getenv("HTTP_CACHE_CONTROL"),     CALC_LEN, "HTTP_CACHE_CONTROL");           
            wxServerAdd( pClientConn, HTTP_DATE             , getenv("HTTP_DATE"),              CALC_LEN, "HTTP_DATE");                             
            wxServerAdd( pClientConn, HTTP_ACCEPT           , getenv("HTTP_ACCEPT"),            CALC_LEN, "HTTP_ACCEPT");                         
            wxServerAdd( pClientConn, HTTP_FROM             , getenv("HTTP_FROM"),              CALC_LEN, "HTTP_FROM");                             
            wxServerAdd( pClientConn, HTTP_HOST             , getenv("HTTP_HOST"),              CALC_LEN, "HTTP_HOST");                             
            wxServerAdd( pClientConn, HTTP_IF_MODIFIED_SINCE, getenv("HTTP_IF_MODIFIED_SINCE"), CALC_LEN, "HTTP_IF_MODIFIED_SINCE");   
            wxServerAdd( pClientConn, HTTP_REFERER          , getenv("HTTP_REFERER"),           CALC_LEN, "HTTP_REFERER");                       
            wxServerAdd( pClientConn, HTTP_USER_AGENT       , getenv("HTTP_USER_AGENT"),        CALC_LEN, "HTTP_USER_AGENT");                 
            wxServerAdd( pClientConn, HTTP_CONTENT_ENCODING , getenv("HTTP_CONTENT_ENCODING"),  CALC_LEN, "HTTP_CONTENT_ENCODING");     
            wxServerAdd( pClientConn, HTTP_CONTENT_TYPE     , getenv("CONTENT_TYPE"),           CALC_LEN, "HTTP_CONTENT_TYPE");
            wxServerAdd( pClientConn, HTTP_CONTENT_LENGTH   , getenv("CONTENT_LENGTH"),         CALC_LEN, "HTTP_CONTENT_LENGTH");         
            wxServerAdd( pClientConn, HTTP_CONTENT_VERSION  , getenv("HTTP_CONTENT_VERSION"),   CALC_LEN, "HTTP_CONTENT_VERSION");
            wxServerAdd( pClientConn, HTTP_CONTENT_BUFFER   , NULL,                             CALC_LEN, "HTTP_CONTENT_BUFFER");              
            wxServerAdd( pClientConn, HTTP_DERIVED_FROM     , getenv("HTTP_DERIVED_FROM"),      CALC_LEN, "HTTP_DERIVED_FROM");             
            wxServerAdd( pClientConn, HTTP_EXPIRES          , getenv("HTTP_EXPIRES"),           CALC_LEN, "HTTP_EXPIRES");                       
            wxServerAdd( pClientConn, HTTP_TITLE            , getenv("HTTP_TITLE"),             CALC_LEN, "HTTP_TITLE");                           
            wxServerAdd( pClientConn, REMOTE_ADDR           , getenv("REMOTE_ADDR"),            CALC_LEN, "REMOTE_ADDR");                         
            wxServerAdd( pClientConn, REMOTE_HOST           , getenv("REMOTE_HOST"),            CALC_LEN, "REMOTE_HOST");                            
            wxServerAdd( pClientConn, SCRIPT_NAME           , getenv("SCRIPT_NAME"),            CALC_LEN, "SCRIPT_NAME");                         
            wxServerAdd( pClientConn, SERVER_SOFTWARE       , getenv("SERVER_SOFTWARE"),        CALC_LEN, "SERVER_SOFTWARE");
            wxServerAdd( pClientConn, SERVER_NAME           , getenv("SERVER_NAME"),            CALC_LEN, "SERVER_NAME");
            wxServerAdd( pClientConn, SERVER_PORT           , getenv("SERVER_PORT"),            CALC_LEN, "SERVER_PORT");                                                                                                    
            wxServerAdd( pClientConn, RESPONSE_CONTENT      , getenv("RESPONSE_CONTENT"),       CALC_LEN, "RESPONSE_CONTENT");
            wxServerAdd( pClientConn, REQUEST_URI           , getenv("REQUEST_URI"),            CALC_LEN, "REQUEST_URI");
            wxServerAdd( pClientConn, HTTP_CONNECTION       , getenv("HTTP_CONNECTION"),        CALC_LEN, "HTTP_CONNECTION");                 
            wxServerAdd( pClientConn, HTTP_COOKIE           , getenv("HTTP_COOKIE"),            CALC_LEN, "HTTP_COOKIE");                         
            wxServerAdd( pClientConn, HTTP_AUTHORIZATION    , getenv("HTTP_AUTHORIZATION"),     CALC_LEN, "HTTP_AUTHORIZATION");
            wxServerAdd( pClientConn, AUTH_PASSWORD         , NULL,                             CALC_LEN, "AUTH_PASSWORD");
            wxServerAdd( pClientConn, AUTH_TYPE             , getenv("AUTH_TYPE"),              CALC_LEN, "AUTH_TYPE");
            wxServerAdd( pClientConn, AUTH_USER             , NULL,                             CALC_LEN, "AUTH_USER");
            
            /*
             * Aqui validamos se existe o conteudo de um POST e em caso afirmativo,
             * iremos puxar os dados dele ajustando o valor de HTTP_CONTENT_BUFFER!
             * 17/07/2008 - 07:43:41
             */   
            if ( strcmp( (char*) pClientConn->pServer[REQUEST_METHOD]->Value, "POST" ) == 0 )
            {
               ULONG Length = atol( (char *) pClientConn->pServer[HTTP_CONTENT_LENGTH]->Value );
               char *Buffer = (char *) hb_xgrab(Length+1);
               ULONG Size   = 0L;

               HB_TRACE( HB_TR_DEBUG, ("     Setamos o CONTENT_LENGTH para %d", Length ));
               
               #if defined( HB_OS_WIN )
                   ReadFile( (HANDLE) pWebCGI->Input, Buffer, Length, &Size, NULL);
               #else
                  Size = fread( Buffer, sizeof(char), Length, pWebCGI->Input );
               #endif
               
               // Ajustamos o valor da string!
               Buffer[Size] = '\0';

               HB_TRACE( HB_TR_DEBUG, ("     Lemos %d bytes do POST: \n%s", Size, Buffer));
               RepositoryList_UpdateStr( pClientConn->pServer[HTTP_CONTENT_BUFFER],
                                          (BYTE *) Buffer, Size );
                                          
#ifdef WEB_DEBUG
               {
                  FILE *hFile = hFile = fopen( "wxInput.txt", "wb+" );
                                           
                  fwrite( Buffer, sizeof(char), Size, hFile );
                  fclose( hFile );
               }
#endif               
            }                                                            
            break;
         }

      // Evento disparado no momento em que a estrutura estiver sendo destruida! 
      case ctAfterFinalize:
         {
            HB_TRACE( HB_TR_DEBUG, ("  pClientConn->OutPutCargo --> %p   ((ctAfterFinalize))", pClientConn->OutPutCargo));
            
            if (pClientConn->OutPutCargo)
            {
               pWebCGI = (PWEBCGI) pClientConn->OutPutCargo;
               /* Liberamos a memoria ocupada pela estrutura auxiliar */
               pClientConn->OutPutCargo = NULL;
               hb_xfree( pWebCGI );
            }   
            break;
         }
   }
   return Result;
}
/*
 * Retorna uma nova conexão, configurada para trabalhar como CGI
 * 15/07/2008 - 09:29:48
 */
HB_FUNC( WXWEBCGI )
{
   HB_THREAD_STUB           
   PConnection pConn;
   int   Handle = hb_parni(1);
   
   HB_TRACE( HB_TR_DEBUG, ("WEBCGI(%d)", Handle ));
   
   /* Forçamos a chamada de wxWeb para setar algumas coisas "default" - 05/10/2008 - 08:38:49 */
   HB_FUNCNAME( WXWEB )();
   
   /* Se nao houver conexao aberta, abriremos uma DEFAULT agora! - 26/09/2008 - 12:24:01 */
   wxConnection_Init();
   
   /* Tentamos criar aqui o Handle da conexão! */
   pConn = wxConnection_Create( Handle, NULL );
   
   if (!pConn)
      goto ERRO;
      
   /*
    * Agora iremos configurar as propriedades específicas utilizadas para o CGI
    */
   pConn->OutPutFunc = NULL;
   pConn->pOutPut    = (TOutPutFunc) wxWebCGI_OutPut;           
   pConn->pState     = (TStateFunc)  wxWebCGI_Status;

   /* Preparamos a conexão para trabalho... */        
   if ( wxConnection_Prepare( pConn ) == WX_FAILURE )
   {
      wxConnection_Destroy( pConn );
      goto ERRO;      
   }
   goto FIM;
   
   ERRO:
      pConn = NULL;
      
   FIM:
      hb_retptr( pConn );
      return;
}
