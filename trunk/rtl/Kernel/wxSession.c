/*---------------------------------------------------------------------------
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado C ..: 09/07/2008 - 17:01:19
 *
 *  Revisado C++.: 08/12/2006 - 08:09:11
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxSession.c
 *                            
 *  Funções para manipulação de seções dentro da wxWeb!
 *
 *
 * @define FUNCLIST SESSION() SESSION_CLEAR() SESSION_COUNT() SESSION_DESTROY()
 * @define FUNCLIST SESSION_EXIST() SESSION_GETNAME() SESSION_ID() SESSION_NAME()
 * @define FUNCLIST SESSION_SAVEPATH() SESSION_START()
 * @define FUNCLIST SESSION_STARTED() SESSION_WRITE()
 *---------------------------------------------------------------------------*/

#include <wxweb.h>
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapifs.h"
#include "hbmath.h"
#include "hbstack.h"

#ifdef HB_OS_WIN
   #include <io.h>
   #include <windows.h>
#endif

#include <wxTime.h>
#include "wxConnManager.h"
#include <wxTrace.h>
#include <wxMemory.h>
#include <wxSerialize.h>

#include <wxMT.h>

#define FileExists(FileName)     (hb_spFile( ( BYTE * ) FileName, NULL ))

extern int    MD5( char *InputText, ULONG Size, char *OutPutText );
extern char   wxItemType( PHB_ITEM Item );
extern WX_RES Int2Str( LONG lValue, char *OutPut, int *OutPutLength );
extern char * wxGetModuleName( int format_type );
extern PRepositoryItem wxGetConfig( PConnection pClientConn, char *Name, PHB_ITEM pValue );
/*
 * Cria uma nova ID para a sessão atual
 * 11/12/2006 11:12:16
 */
WX_RES wxSession_CreateNew( PConnection pClientConn )      
{
   char buff[128], s[33];
   TUCTTimeStruct time;
   char *remote_addr, *remote_port;
   int iRand[10];

   HB_TRACE( HB_TR_DEBUG, ("wxSession_CreateNew( %p, %p )", pClientConn, pClientConn->pSession ));
   
   /* Se ainda nao existir o buffer desejado, iremos criar um buffer vazio */
   if (!pClientConn->pSession)
   {
      pClientConn->pSession = (PSession) hb_xgrab( sizeof( TSession ));
      memset( pClientConn->pSession, 0, sizeof( TSession ));
   }
   
   /* Se a session atual, já contiver um ID, iremos ignoramos e retornamos OK */
   if (pClientConn->pSession->ID[0]) 
      return WX_SUCCESS;

   /* Puxamos a data e hora atuais da CPU onde estamos sendo executados */
   wxGetUCTTime( &time );

   /* Sorteamos 10 numeros randômicos para geração da chave composta no ID */
   iRand[0] = (int) (hb_random_num()*4450);
   iRand[1] = (int) (hb_random_num()*5525);
   iRand[2] = (int) (hb_random_num()*4681);
   iRand[3] = (int) (hb_random_num()*3357);
   iRand[4] = (int) (hb_random_num()*3591);
   iRand[5] = (int) (hb_random_num()*3133);
   iRand[6] = (int) (hb_random_num()*4043);
   iRand[7] = (int) (hb_random_num()*2227);
   iRand[8] = (int) (hb_random_num()*5367);
   iRand[9] = (int) (hb_random_num()*5367);
   
   remote_addr = RepositoryList_GetCPtr( pClientConn->pServer[ REMOTE_ADDR ], 0 );
   remote_port = RepositoryList_GetCPtr( pClientConn->pServer[ REMOTE_PORT ], 0 );
   
	sprintf(buff, "%s:%s:%ld:%ld:%i%i%i%i%i%i%i%i%i%i",
         remote_addr ? remote_addr : "0.0.0.0",
         remote_port ? remote_port : "0",
			(long)time.wSeconds, (long)time.wMilliseconds, 
         iRand[0], iRand[1], iRand[2], iRand[3], iRand[4], 
         iRand[5], iRand[6], iRand[7], iRand[8], iRand[9]
         );

   HB_TRACE( HB_TR_DEBUG, ("  buffer --> %s", buff ));
   MD5(buff,-1,s);

   HB_TRACE( HB_TR_DEBUG, ("  MD5    --> %s", s ));

   pClientConn->pSession->ID[0] = '\0'; 
   strcat( pClientConn->pSession->ID, s );
   
   HB_TRACE( HB_TR_DEBUG, ("  ID     --> %s", pClientConn->pSession->ID ));
   return WX_SUCCESS;
}

/*
 * Assegura-se de que haja uma session registrada para a conexão atual.
 * 31/07/2008 - 12:03:47
 */
static
WX_RES wxSession_Ensure( PConnection pClientConn )
{
   if (pClientConn->pSession)
      return WX_SUCCESS;
      
   return wxSession_CreateNew( pClientConn );  // 31/07/2008 - 10:22:15 - ocorreu algum erro aqui na criação da session!!!
}

/**
 * Session( [ <pConnection>, ] <cKeyName> [, <xValue> ] ) -> xOldValue
 *
 * Esta função cria, modifica ou exclui o conteudo de uma variável de sessão
 * para a conexão atual.
 *
 * @<pConnection>  É um parametro (pointer) que identifica a conexão à qual desejamos
 *                 operar. Este parametro deverá ser omitido em circunstâncias normais,
 *                 pois seu uso torna-se mais evidente em ambientes multi-thread ou que
 *                 utilizem servidores de dados personalizados.
 *
 * @<cKeyName>     É o nome da variavel de sessão que desejamos consultar/alterar/excluir.
 *
 * @<xValue>       É um parâmetro opcional que contém o valor que deverá ser preservado
 *                 para esta variável de sessão. Atribuindo o valor NIL para uma variavel
 *                 de sessão existente forçará a mesma a ser removida.
 *
 *                 A wxWeb suporta que sejam guardados vários tipos de valores dentro de
 *                 uma variável de sessão tais como texto, números, data, valores lógicos,
 *                 memos, objetos e arrays.
 * @see @request(FUNCLIST)
 * 11/07/2008 - 22:06:43
 */                                          
HB_FUNC( SESSION )
{
   PConnection pClientConn;
   PRepositoryItem Temp;
   PRepositoryItem pItem;
   PRepositoryItem pLast;
   PHB_ITEM pValue = NULL;
   char Name[ WX_SESSION_NAME_LEN+1 ]; 
   int i;
   
   HB_THREAD_STUB   

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
      i = 2;
   } else {
      pClientConn = wxGetClientConnection();
      i = 1;
   }
   
   HB_TRACE( HB_TR_DEBUG, ("Session( %p )", pClientConn ));
   HB_TRACE( HB_TR_DEBUG, ("Session->pSession ==>( %p // %d )", ((pClientConn) ? pClientConn->pSession : NULL), ((pClientConn) ? pClientConn->Handle: 0) ));                            
   hb_ret();
   
   /* Se ele não quer achar um item nem pelo nome -- ignore! */
   if ((!ISCHAR(i)))
   {
      HB_TRACE( HB_TR_DEBUG, ("  Parametro %d nao é nem STRING", i));
      return;
   }
   if (!pClientConn)
      return;

   if (!pClientConn->pSession)
      /* Nos asseguramos aqui de que a session existe! */
      if (wxSession_Ensure( pClientConn ) != WX_SUCCESS )
         return;
      
   /*
    * Se ele passou NIL para nós, indicamos que não há nenhum valor válido para
    * ser serializado!
    */
   if (!ISNIL(i+1)) 
      pValue = hb_param(i+1, HB_IT_ANY );
   
   // Localizamos o item pelo nome...
   Temp = ( pClientConn->pSession ) ? pClientConn->pSession->List : NULL;
   pItem = NULL;
   pLast = NULL;

   // Pegamos o nome e o convertemos para uppercase e sem espaços
   xStrUpperCopy( Name, hb_parcx(i), WX_SESSION_NAME_LEN );

   HB_TRACE( HB_TR_DEBUG, ("Session -> Key -> ( %s )", Name ));

   /* Tem como acelerarmos esta pesquisa? - 31/07/2008 - 17:41:43 */
   if ((pClientConn->pSession->Last) &&                            // Tem ultimo item pesquisado?
       (pClientConn->pSession->Last->Key) &&                       // Este item tinha nome em anexo?
       (strcmp( pClientConn->pSession->Last->Key, Name)==0))       // É o mesmo nome que estamos procurando?
   {
      HB_TRACE( HB_TR_DEBUG, ("  Ok! Pesquisa acelerada com item %s já em cache!", pClientConn->pSession->Last->Key ));
      
      pItem = pClientConn->pSession->Last;
   } else {
      HB_TRACE( HB_TR_DEBUG, ("  Pesquisamos a lista de itens desde o começo" ));
      
      do
      {         
         if (!Temp)                          // Nenhum item encontrado?
            break;         
         if ((Temp->Key) &&                  // Possui nome em anexo?
             (strcmp( Temp->Key, Name)==0))  // É o mesmo nome que estamos procurando?
         {
            pItem = Temp;
            break;         
         }      
         pLast= Temp;
         Temp = Temp->pNext;
      } while (Temp);     
      
      if ( pItem)
         pClientConn->pSession->Last = pItem;   // 31/07/2008 - 17:38:08
   }
      
   if ((!pItem) &&   // Se nao achou o item com o nome solicitado 
       (!pValue))    // e tb nao tem nenhum valor para gravar ...
   {                                              
      HB_TRACE( HB_TR_DEBUG, ("  ERA PRA CONSULTAR MAS NAO EXISTE A CHAVE RETORNAMOS NIL" ));
      return;        // Entao ignoramos e retornamos NIL daqui mesmo!                     
   }

   /*
    * Aqui nos proximos 2 IFs, iremos obter o valor atual da variavel e guardá-lo
    * para retornar à função/procedimento em xHB...
    */
   // Se ele armazenou um ITEM.. retornamos uma cópia para este item e pulamos fora
   if ( pItem)
   {
      pClientConn->pSession->Last = pItem;   // 31/07/2008 - 17:38:08
      
      if (pItem->Type == rtiItem)
      {
#if defined( WEB_DEBUG )            
/**/
         char b[19];
         
         HB_TRACE( HB_TR_DEBUG, ("     pItem->Value -> (%p)", (WX_PTR) pItem->Value ));   
         HB_TRACE( HB_TR_DEBUG, ("     pItem->Type  -> (%c)", wxItemType( pItem->Value )));
         
         switch ((char) wxItemType( pItem->Value ))
         {
            case 'C':   HB_TRACE( HB_TR_DEBUG, ("     pItem->Value -> (%s)", hb_itemGetCPtr( (PHB_ITEM)pItem->Value ))); break;
            case 'N':   HB_TRACE( HB_TR_DEBUG, ("     pItem->Value -> (%lu)",hb_itemGetNL  ( (PHB_ITEM)pItem->Value ))); break;
            case 'L':   HB_TRACE( HB_TR_DEBUG, ("     pItem->Value -> (%d)", hb_itemGetL   ( (PHB_ITEM)pItem->Value ))); break;
            case 'D':   HB_TRACE( HB_TR_DEBUG, ("     pItem->Value -> (%s)", hb_itemGetDS  ( (PHB_ITEM)pItem->Value, b ))); break;
         }      
/**/
#endif      
         hb_itemCopy( hb_stackReturnItem(), (PHB_ITEM)pItem->Value );
      } else {           
      /* é um texto simples? */      
         HB_TRACE( HB_TR_DEBUG, ("     pItem->Value -> '%s'", (char *) pItem->Value ));   
         hb_retclen( (char *) pItem->Value, pItem->Len );
      }
   }    
   
   /* Se a session foi gravada em disco, ela ñ pode mais ser alterada!!! - 31/07/2008 - 12:25:43 */
   if ((pValue || ((hb_pcount()>i) && 
            (ISNIL(i+1)))) && pClientConn->pSession->Written)
   {
		char Text[]  = {"ERROR: session data has been written into disc - unable to change values on "};
		char *Source = wxGetModuleName( WX_PRG_LONG );
		                                                                 
		wxConnection_SendText( pClientConn, Text, strlen( Text) );
		wxConnection_SendText( pClientConn, Source, strlen( Source) );
		
		hb_xfree(Source);
      return;
   }
            
   /*
    * Aqui testamos se ele quer buscar um item ou se ele quer ALTERAR seu valor
    * 08/07/2008 - 12:09:15
    */          
   if (!pValue)
   {
      // Se originalmente existia um valor, mas era NIL... então temos que DELETAR
      // o item atualmente selecionado!
      if ((hb_pcount()>i) && 
          (ISNIL(i+1)))
      {  
         HB_TRACE( HB_TR_DEBUG, ("  VAMOS DELETAR O VALOR" ));
            
         if (pLast)
            pLast->pNext = pItem->pNext;
         
         pClientConn->pSession->Last = NULL;
      
         if (RepositoryList_Destroy(  pItem ) == WX_SUCCESS)
         {            
            pClientConn->pSession->Count --;         
            pClientConn->pSession->Changed = TRUE;
         }  
      } else { 
         HB_TRACE( HB_TR_DEBUG, ("  VAMOS CONSULTAR APENAS O VALOR" ));
      }
      return;      
   }   
   /*
    * Ok, é para adicionarmos um novo item!
    */
#if defined( WEB_DEBUG )            
   if (pItem)
   {
      HB_TRACE( HB_TR_DEBUG, ("  VAMOS ALTERAR O VALOR    ---> (%p) // Tipo: %c", pValue, wxItemType( pValue ) ));
   } else {
      HB_TRACE( HB_TR_DEBUG, ("  VAMOS CADASTRAR O VALOR  ---> (%p) // Tipo: %c", pValue, wxItemType( pValue ) ));
   }
#endif
   HB_TRACE( HB_TR_DEBUG, ("     pValue-> (%s)", hb_itemGetCPtr( pValue )));
   
   if (!pItem)
   {   
      /*
       * Se não houver session iniciada, criamos uma agora!
       * 28/07/2008 - 15:18:55
       */
      if (!pClientConn->pSession)
         if (wxSession_CreateNew( pClientConn ) != WX_SUCCESS )   // 31/07/2008 - 10:22:15 - ocorreu algum erro aqui na criação da session!!!
            return;
         
      pItem = RepositoryList_AddItem( pLast, pValue );
      pItem->Key = xStrDup( Name );
      
      if (!pClientConn->pSession->List)
         pClientConn->pSession->List = pItem;
         
      pClientConn->pSession->Count ++;         
   } else 
      RepositoryList_UpdateItem( pItem, pValue );
      
   pClientConn->pSession->Changed = TRUE;
   return;
}

/*
 * Apaga todas as informações registradas na session vinculada à conexão passada
 * como argumento.
 * 27/07/2008 - 14:01:07
 */
WX_RES wxSession_Clear( PConnection pConn, BOOL Parcial )
{
   PRepositoryItem pItem, pNext;

   HB_TRACE( HB_TR_DEBUG, ("wxSession_Clear( %p, %d )", pConn, Parcial ));
   
   if (!pConn)
      return WX_FAILURE; 

   if (!pConn->pSession )
      return WX_SUCCESS;   
      
   /* Destruimos aqui todas as variaveis de Sessao */
   pItem = ( pConn->pSession ) ? pConn->pSession->List : NULL;
      
   while (pItem)
   {
      pNext = pItem->pNext;
      RepositoryList_Destroy( pItem );
      pItem = pNext;
   }       
   pConn->pSession->List = NULL;
   pConn->pSession->Last = NULL;

   /*
    * Se for uma limpeza parcial, ele quer que apenas limpemos os valores anexados
    * 28/07/2008 - 15:26:36
    */
   if (Parcial)
      return WX_SUCCESS;
      
   if (pConn->pSession->CookieName) 
      hb_xfree( pConn->pSession->CookieName );

   if (pConn->pSession->FileName) 
      hb_xfree( pConn->pSession->FileName );
   hb_xfree( pConn->pSession );
   
   pConn->pSession = NULL;
   return WX_SUCCESS;        
}

/**
 * Session_Clear( [<pConn>] ) -> lSuccess
 *
 * Apaga todas as informações registradas na sessão atual vinculada à conexão
 * passada como argumento. Se nenhum argumento for passado, a conexão atualmente
 * ativa (baseada na thread atual) será usada.
 * @see @request(FUNCLIST)
 * 25/12/2006 13:10:31
 */
HB_FUNC( SESSION_CLEAR )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   
   if (ISPOINTER(1))
      pClientConn = (PConnection) hb_parptr(1);
   else
      pClientConn = wxGetClientConnection();

   HB_TRACE( HB_TR_DEBUG, ("SESSION_CLEAR( %p )", pClientConn ));
   
   if (wxSession_Clear( pClientConn, TRUE ) == WX_SUCCESS)
      hb_retl(TRUE);
   else
      hb_retl(FALSE);
   
   return;
}

/**
 * Session_Count( [<pConn>] ) -> nCount
 *
 * Retorna a quantidade de variaveis gravadas na sessão vinculada à conexão passada
 * como argumento. Se nenhum argumento for passado, a conexão atualmente ativa (baseada
 * na thread atual) será usada.
 * @see @request(FUNCLIST)
 * 19/12/2006 11:55:48
 */
HB_FUNC( SESSION_COUNT )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   int i;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
      i = 2;
   } else {
      pClientConn = wxGetClientConnection();
      i = 1;
   }
   
   HB_TRACE( HB_TR_DEBUG, ("SESSION_COUNT( %p )", pClientConn ));

   if (!pClientConn)
      hb_retni( 0 );
   else
      hb_retni( ( pClientConn->pSession ) ? pClientConn->pSession->Count : 0 );

   return;
}

/*
 * wxSession_Find( pConn, cKeyName ) -> pItem
 * 27/07/2008 - 15:12:58
 */
PRepositoryItem wxSession_Find( PConnection pConn, char *KeyName )
{
   PRepositoryItem pItem;

   HB_TRACE( HB_TR_DEBUG, ("wxSession_Find( %p, %s )", pConn, KeyName ));

   if (!pConn)
      return NULL; 

   pItem = ( pConn->pSession ) ? pConn->pSession->List : NULL;
   
   while (pItem)
   {
      if ((pItem->Key) &&                       // Possui nome em anexo?
          (strcmp( pItem->Key, KeyName)==0))    // É o mesmo nome que estamos procurando?
      {
         pConn->pSession->Last = pItem;   // 31/07/2008 - 17:38:08
         HB_TRACE( HB_TR_DEBUG, ("  --> %s found at %p", KeyName, pItem ));
         return pItem;
      }   
      pItem = pItem->pNext;
   }            
   HB_TRACE( HB_TR_DEBUG, ("  --> %s NOT found", KeyName ));
   return NULL;        
}

/**
 * Session_Exist( [<pConn> ,] <cKeyName> ) -> lFound
 * Verifica se uma determinada chave existe na sessão da conexão passada como
 * argumento. Se nenhum argumento for fornecido, a conexão atualmente ativa (baseada
 * na thread atual) será usada.
 * @see @request(FUNCLIST)
 * 19/12/2006 09:50:08
 */
HB_FUNC( SESSION_EXIST )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   char Name[ WX_SESSION_NAME_LEN+1 ]; 
   int i;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
      i = 2;
   } else {
      pClientConn = wxGetClientConnection();
      i = 1;
   }
   
   HB_TRACE( HB_TR_DEBUG, ("SESSION_EXIST( %p )", pClientConn ));
   hb_retl( FALSE );
   
   if (!pClientConn)
      return;
      
   if (!ISCHAR(i))
      return;   

   // Pegamos o nome e o convertemos para uppercase e sem espaços
   xStrUpperCopy( Name, hb_parcx(i), WX_SESSION_NAME_LEN );

   if (wxSession_Find( pClientConn, Name ) != NULL) 
      hb_retl( TRUE );
      
   return;
}

/**
 * Session_GetName( [<pConn> ,] <cKeyName> ) -> lFound
 *
 * Retorna o nome da variavel de sessão armazenada na posição específica da pilha
 * de dados da sessão. Se nenhum argumento for fornecido para <pConn>, a conexão
 * atualmente ativa (baseada na thread atual) será usada.
 * @see @request(FUNCLIST)
 * 19/12/2006 11:56:53
 */
HB_FUNC( SESSION_GETNAME )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   PRepositoryItem pItem;
   int i,p;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
      i = 2;
   } else {
      pClientConn = wxGetClientConnection();
      i = 1;
   }
   
   HB_TRACE( HB_TR_DEBUG, ("SESSION_GETNAME( %p )", pClientConn ));
   hb_retc( "" );
   
   if (!pClientConn)
      return;
      
   if (!ISNUM(i))
      return;   

   pItem = ( pClientConn->pSession ) ? pClientConn->pSession->List : NULL;
   p = hb_parni(i); i = 0;
   
   while (pItem)
   {
      if ((++i)==p)
      {
         if (pItem->Key)                      
            hb_retc( pItem->Key );

         return;
      }        
      pItem = pItem->pNext;
   }            
   return;        
}

/**
 * Session_ID( [<pConn> ,] <cFileName> ) -> cOldFileName
 *
 * Retorna e opcionalmente altera o ID da conexão atual que representa o nome do
 * arquivo que será gravado ou carregado à partir da pasta session. Se nenhum
 * argumento for fornecido para pConn, a conexão atualmente ativa (baseada na
 * thread atual) será usada.
 * @see @request(FUNCLIST)
 * 19/12/2006 10:46:13
 */
HB_FUNC( SESSION_ID )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   int len;
   char *fn;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
      len = 2;
   } else {
      pClientConn = wxGetClientConnection();
      len = 1;
   }
   
   HB_TRACE( HB_TR_DEBUG, ("SESSION_ID( %p )", pClientConn ));
   hb_retc( "" );
   
   if (!pClientConn)
      return;

   /* Nos asseguramos aqui de que a session existe! */
   if (wxSession_Ensure( pClientConn ) != WX_SUCCESS )
      return;

   /*
    * Pega o nome do arquivo na pasta sessions que contem os dados previamente
    * serializados e que devem ser restaurados.
    * 11/12/2006 17:11:45
    */ 
   if (pClientConn->pSession->ID[0])
      hb_retc( pClientConn->pSession->ID );
                                                                                     
   /* Se ele já iniciou a session lendo de um arquivo, ñ pode alterar o ID mais! */ 
   if (pClientConn->pSession->Started)
      return;

   if (!ISCHAR(len))
      return;
      
   /*
    * Se ele quer alterar o nome do COOKIE, fazemos isto agora!
    */
   fn  = hb_parcx(len);
   len = hb_parclen(len);
   len = (len>MAX_SESSION_LEN) ? MAX_SESSION_LEN : len;

   hb_retc( pClientConn->pSession->ID );

   /*
    * É o mesmo nome que já havia anteriormente?
    * 07/06/2007 - 15:13:25
    */
   if (strcmp( fn, pClientConn->pSession->ID ) == 0)
      return;

   pClientConn->pSession->Changed = FALSE;
   pClientConn->pSession->ID[0]   = '\0';
   
   strcat( pClientConn->pSession->ID, fn );   
      
   /*
    * Aqui deletamos o nome do arquivo para forçar ele a gerar novo nome
    */
   if ( pClientConn->pSession->FileName )
   {
      hb_xfree( pClientConn->pSession->FileName );
      pClientConn->pSession->FileName = NULL;
   }                        
}

/**
 * Session_Name( [<pConn> ,] <cSessionName> ) -> cOldName
 *
 * Retorna e opcionalmente altera o nome do COOKIE que controlará a sessão
 * atual. Se nenhum argumento for fornecido para pConn, a conexão atualmente ativa
 * (baseada na thread atual) será usada.
 * @see @request(FUNCLIST)
 * 19/12/2006 10:28:58
 */
HB_FUNC( SESSION_NAME )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   int i;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
      i = 2;
   } else {
      pClientConn = wxGetClientConnection();
      i = 1;
   }
   
   HB_TRACE( HB_TR_DEBUG, ("SESSION_NAME( %p )", pClientConn ));
   
   /* No caso de nao termos conexao ativa, retornamos uma string nula */   
   if (!pClientConn)
   {
      hb_retc( "" );
      return;
   }
      
   hb_retc( DEF_SESSION_NAME );
   
   /* Nos asseguramos aqui de que a session existe! */
   if (wxSession_Ensure( pClientConn ) != WX_SUCCESS )
      return;

   /*
    * Pega o nome padrão pro Cookie (arquivo)
    * 11/12/2006 17:11:45
    */ 
   if (pClientConn->pSession->CookieName)
      hb_retc( pClientConn->pSession->CookieName );
      
   if (!ISCHAR(i))
      return;
      
   /*
    * Se ele quer alterar o nome do COOKIE, fazemos isto agora!
    * 19/12/2006 10:39:12
    */
   if (pClientConn->pSession->CookieName)
      hb_xfree( pClientConn->pSession->CookieName );
      
   pClientConn->pSession->CookieName = xStrNewBuff( hb_parclen(i), hb_parcx(i) );
   return;        
}

/**
 * Session_SavePath( [<pConn> ,] <cSessionName> ) -> cOldName
 *
 * Permite alterar o PATH onde os arquivos de sessões ativos deverão ser
 * salvos. Se nenhum argumento for fornecido para pConn, a conexão atualmente ativa
 * (baseada na thread atual) será usada.
 * @see @request(FUNCLIST)
 * 19/12/2006 11:37:25
 */ 
HB_FUNC( SESSION_SAVEPATH )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   char *SavePath;
   int i;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
      i = 2;
   } else {
      pClientConn = wxGetClientConnection();
      i = 1;
   }
   
   HB_TRACE( HB_TR_DEBUG, ("SESSION_SAVEPATH( %p )", pClientConn ));
   hb_retc( "" );
   
   if (!pClientConn)
      return;
   /* Nos asseguramos aqui de que a session existe! */
   if (wxSession_Ensure( pClientConn ) != WX_SUCCESS )
      return;

   /*
    * O path para salvar as sessoes, deve ser passado via wxServer(SESSION_PATH)
    * 31/07/2008 - 09:38:08 
    */ 
   SavePath = RepositoryList_GetCPtr( pClientConn->pServer[ SESSION_PATH ], 0 );
   
   HB_TRACE( HB_TR_DEBUG, ("     SavePath => %s ", SavePath ));   
   hb_retc( SavePath );
      
   if (!ISCHAR(i))
      return;
      
   /*
    * Se ele quer alterar o local, faremos isto agora!
    * 19/12/2006 10:39:12
    */
   wxServerAdd( pClientConn, SESSION_PATH, hb_parcx(i), hb_parclen(i), "SESSION_PATH" );
   return; 
}

/*
 * Valida o nome do arquivo de sessão a ser gravado no HD do servidor!
 * 11/12/2006 19:35:00
 */
static
WX_RES wxSession_PrepareName( PConnection pClientConn )
{
   HB_TRACE( HB_TR_DEBUG, ("wxSession_PrepareName( %p ) || pClientConn->pSession-> %p", pClientConn, pClientConn->pSession ));

   if (!pClientConn->pSession->FileName)
   {
      char *SavePath = RepositoryList_GetCPtr( pClientConn->pServer[ SESSION_PATH ], 0 );
      BOOL bFree = FALSE;      
      /*
       * Pegamos o PATH padrão onde deve salvar as seções, ex: ./sessions
       */      
      if (!SavePath)
      {
         /*
          * Puxamos o valor default da configuração atual para salvarmos a sessão
          * 26/12/2006 12:05:55 - (reajustado em 24/10/2008 - 22:31:03)
          */
         PRepositoryItem pItem = wxGetConfig( pClientConn, "SESSION_PATH", NULL );
         char *temp = ((pItem) ? (char *)pItem->Value : NULL );
                  
         SavePath = xStrNew( 254 );
         bFree    = TRUE;
         
         if (!temp)
            xStrMove( SavePath, ".", HB_OS_PATH_DELIM_CHR_STRING, "sessions", HB_OS_PATH_DELIM_CHR_STRING, NULL );
         else
            xStrMove( SavePath, temp, NULL );
      }
      /*
       * Adiciona o nome do arquivo (ID da sessão) ex:
       * ./sessions /ID
       */         
      pClientConn->pSession->FileName = xStrNew(254);
      
      /* O ultimo character é uma barra separadora? Se nao for, adicione! -  31/07/2008 - 13:07:55 */
      if (SavePath[ strlen( SavePath )-1 ] == HB_OS_PATH_DELIM_CHR )
         xStrMove( pClientConn->pSession->FileName, SavePath, pClientConn->pSession->ID, NULL );
      else
         xStrMove( pClientConn->pSession->FileName, SavePath, HB_OS_PATH_DELIM_CHR_STRING, pClientConn->pSession->ID, NULL );
         
      if (bFree)
         wxRelease( SavePath );
   }
   return WX_SUCCESS;
}

/* 
 * Grava o Cookie da sessão no cabeçalho HTTP enviado ao cliente!
 * 11/12/2006 17:10:15
 */ 
static
WX_RES wxSession_WriteCookie( PConnection pClientConn )      
{
   TUCTTimeStruct time;
   WX_RES Result = WX_FAILURE;
   char  *Cookie;
   char  *Temp;

   HB_TRACE( HB_TR_DEBUG, ("wxSession_WriteCookie( %p ) --> %s", pClientConn, pClientConn->pSession->CookieName ));
   
   /* Aqui gravamos o cookie da sessão para retorno */
   /* Ops... ele está mandando um HEADER, porem já iniciamos o BODY da página? */
   if (pClientConn->LastType == WX_BODY) 
   {                          
      /*
       * Aqui avisamos para o usuario, que o buffer de saida já fora inicializado!
       */   
		if (pClientConn->OutPutStartedAt)
      {
         char Text[255] = {0};
			sprintf( Text, "WARNING: Cannot send session cookie - headers already sent (output started at %s)", pClientConn->OutPutStartedAt );
			wxConnection_SendText( pClientConn, Text, strlen( Text ) );
		} else {
			char Text[] = {"WARNING: Cannot send session cookie - headers already sent"};
			
			wxConnection_SendText( pClientConn, Text, strlen( Text ) );
		}
      return Result;
   }

   /*
    * Computa o tempo de vida do Cookie! O default é 20 minutos = 60 segs * 20mins
    * conforme o valor em wxWebFramework.ch
    */
   HB_TRACE( HB_TR_DEBUG, ("  pSession->CookieLife --> %ld", pClientConn->pSession->CookieLife ));

   if (pClientConn->pSession->CookieLife == 0L)
      pClientConn->pSession->CookieLife = DEF_SESSION_LIFETIME;

   /* Puxamos a data e hora atuais da CPU onde estamos sendo executados */
   wxGetUCTTime( &time );
   
   // Cookie com -1 segds de vida é válido apenas para esta sessão no browser!*/
   if (pClientConn->pSession->CookieLife != -1L)
      wxAddSeconds( &time, pClientConn->pSession->CookieLife );      /// secs * min * hors * dias

   Temp = wxGetUCTTimeAsGMT( &time );
   
   /* Montamos a string do Cookie e mandamos ele para o browser! */
   Cookie = xStrNew(256);
   xStrMove( Cookie, "Set-Cookie: ", pClientConn->pSession->CookieName, "=", pClientConn->pSession->ID, "; expires=", Temp, NULL );
   Result = wxConnection_SendHeader( pClientConn, Cookie, strlen( Cookie ) );
   
   /* Liberamos a região da memória temporaria */
   wxDispose( Cookie );
   wxDispose( Temp );                        
   return Result;
}

/*
 * Grava os dados da sessão no arquivo em disco
 * 11/12/2006 17:09:53
 */
static
WX_RES wxSession_WriteRawData( PConnection pClientConn )
{
   PSession pSession;
   PRepositoryItem pItem;

   HB_FHANDLE hHandle;
   BOOL Result = FALSE;
   ULONG L;
   char *T; 
   char S[15];
   int i;
    
   HB_TRACE( HB_TR_DEBUG, ("wxSession_WriteData( %p )", pClientConn ));
   
   if (!pClientConn)
      return WX_FAILURE;
   if (!pClientConn->pSession)
      return WX_FAILURE;
      
   pSession= pClientConn->pSession;
   hHandle = hb_fsCreate( pSession->FileName, 0 );
   
   /*
    * Avisamos nos console que houve um erro na gravação do arquivo da sessão!
    * 26/12/2006 13:04:43
    */
   if (hHandle == FS_ERROR)
   {
      S[0] = '\0';
      sprintf( S, "%d", hb_fsError() );
      
      wxConnection_SendText( pClientConn, "[SESSION] Error creating session file: '", strlen("[SESSION] Error creating session file: '") );
      wxConnection_SendText( pClientConn, pSession->FileName, strlen(pSession->FileName) );
      wxConnection_SendText( pClientConn, "' OS error:", strlen("' OS error:") );
      wxConnection_SendText( pClientConn, S, strlen(S) );
      wxConnection_SendText( pClientConn, "\r\n", 2 );
      return WX_FAILURE;
   }

   // Localizamos o item pelo nome...
   pItem = pSession->List;

   /*
    * Enviamos todos os textos da Session
    */
   while (pItem)
   {      
      /* Possui item anexo? */
      if (!pItem->Value)
         continue;

      /* É um tipo de dados suportado para resialização? */
      if (pItem->Type == rtiItem)
         if (!strrchr( "CNDLAOU", wxItemType( (PHB_ITEM) pItem->Value ) ))
            continue;      
      
      /*
       * 1° Passo: salvamos o tamanho da CHAVE
       */
      L = strlen( pItem->Key );
      
      S[0] = '\0';
      sprintf( S, "%c%c", 3, (char) L );
              
      Result = (hb_fsWriteLarge( hHandle, S, 2 ) == 2);      // tamanho da string      
      if (!Result) break;
       
      /* 
       * 2° Passo: salvamos o valor desta CHAVE
       */ 
      Result = ( hb_fsWriteLarge( hHandle, (BYTE *)pItem->Key, L ) == L);      
      if (!Result) break;

      /*
       * 3° Passo: Gravamos o valor do item na sessão!
       */ 
      if (pItem->Type != rtiItem)
      {
         char *Buffer = S;
         T = (char *) pItem->Value;
         L = pItem->Len;
         
        *Buffer = _MASK_('C',L);
         Buffer++;
         Int2Str( L, Buffer, &i );
         
         Result = (hb_fsWriteLarge( hHandle, S, i+1 ) == i+1);      // tamanho da string      
         if (!Result) break;
         
         Result = (hb_fsWriteLarge( hHandle, T, L ) == L );      // tamanho da string      
         if (!Result) break;
         
      } else
         wxItemSerialize( (PHB_ITEM) pItem->Value, &L, hHandle );      
      
      pItem = pItem->pNext;
   }   
   
   /*
    * Avisamos nos console que houve um erro na gravação do arquivo da sessão!
    * 29/10/2008 - 11:17:53
    */  
   if (!Result)
   {
      S[0] = '\0';
      sprintf( S, "%d", hb_fsError() );
      
      wxConnection_SendText( pClientConn, "[SESSION] Error creating session file: '", strlen("[SESSION] Error creating session file: '") );
      wxConnection_SendText( pClientConn, pSession->FileName, strlen(pSession->FileName) );
      wxConnection_SendText( pClientConn, "' OS error:", strlen("' OS error:") );
      wxConnection_SendText( pClientConn, S, strlen(S) );
      wxConnection_SendText( pClientConn, "\r\n", 2 );
   }
   /*
    * Ok! Tudo gravado com sucesso!
    */
   hb_fsClose( hHandle );   
   return (( Result ) ? WX_SUCCESS : WX_FAILURE );
}

/*
 * Gravamos os valores em um arquivo e mandamos o COOKIE correto no cabeçalho
 * para garantir que tudo seja restaurado adequadamente!
 * 11/12/2006 15:43:49
 */
WX_RES wxSession_Write( PConnection pClientConn )
{
   PSession pSession;
   
   HB_TRACE( HB_TR_DEBUG, ("wxSession_Write( %p ) || pClientConn->pSession-> %p", pClientConn, pSession ));
   
   if (!pClientConn)
      return WX_SUCCESS;
   if (!pClientConn->pSession)
      return WX_SUCCESS;
   
   /*
    * Ajustamos o nome do arquivo, pq se a session estiver vazia o arquivo no HD
    * será deletado, impedindo assim que quaisquer dados inválidos sejam carregados
    * futuramente para a memória.
    */
   if (wxSession_PrepareName( pClientConn ) != WX_SUCCESS )
      return WX_FAILURE;

   pSession = pClientConn->pSession;
   HB_TRACE( HB_TR_DEBUG, ("     pSession->FileName -> %s", pSession->FileName  ));
      /*
    * Validamos os parametros pra gravaçao
    * 11/12/2006 17:22:12
    */
   if (pSession->Count<1)
   {
      /*
       * Testamos se o arquivo existe... se existir e nada houver na secao, 
       * DESTRUIMOS o arquivo!!
       */
      if (FileExists( pSession->FileName )) 
         hb_fsDelete( pSession->FileName );
         
      return WX_SUCCESS;
   }

   /*
    * Se já foi salvo e nada foi alterado, caimos fora!
    * 25/12/2006 11:16:26
    */
   if ((pSession->Written) && (!pSession->Changed) )
      return WX_SUCCESS;

   /*
    * No caso do array que possui endereçamento compartilhado, ele pode ter sim
    * alterado algo, porém o IF abaixo ñ irá detectar!! 
    * 21/12/2006 08:37:09
    */
//   if (!Changed)
//      return TRUE;
                        
   if (wxSession_WriteRawData(pClientConn) != WX_SUCCESS)
      return WX_FAILURE;

   /* É para enviar o COOKIE ?*
   if (wxSession_WriteCookie(pClientConn) != WX_SUCCESS)
      return WX_FAILURE;
   
   /* Setamos alguns flags internos para evitar duplicidade */   
   pSession->Changed = FALSE;
   pSession->Written = TRUE;            
   return WX_SUCCESS;
}

/**
 * Session_Write( [<pConn>] ) -> lSaved
 *
 * Força a gravacao em disco e o envio do COOKIE da seçao atual para o
 * usuário. Se nenhum argumento for fornecido para pConn, a conexão atualmente
 * ativa (baseada na thread atual) será usada.
 * @see @request(FUNCLIST)
 * 25/12/2006 12:50:52
 */
HB_FUNC( SESSION_WRITE )
{
   HB_THREAD_STUB   
   PConnection pClientConn;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
   } else {
      pClientConn = wxGetClientConnection();
   }

   HB_TRACE( HB_TR_DEBUG, ("SESSION_WRITE( %p )", pClientConn ));
   hb_retl( FALSE );
   
   /* No caso de nao termos conexao ativa, retornamos uma string nula */   
   if (!pClientConn)
      return;
   if (!pClientConn->pSession)
      return;

   if (wxSession_Write( pClientConn ) == WX_SUCCESS )
      hb_retl( TRUE );
   else
      hb_retl( FALSE );
   
  return;
}

/**
 * Session_Started( [<pConn>] ) -> lStarted
 *
 * Retorna .T. se já fora iniciada uma sessão ou .F. caso nenhuma sessão tenha sido
 * carregada ou iniciada. Uma sessão é considerada como iniciada se ela já foi carregada
 * de um arquivo para a memória ou se algum item foi atrelado à ela para posterior
 * recuperação.
 * @see @request(FUNCLIST)
 * 07/06/2007 - 11:16:04
 */
HB_FUNC( SESSION_STARTED )
{
   HB_THREAD_STUB   
   PConnection pClientConn;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
   } else {
      pClientConn = wxGetClientConnection();
   }
   
   HB_TRACE( HB_TR_DEBUG, ("SESSION_STARTED( %p )", pClientConn ));

   if (!pClientConn || !pClientConn->pSession )
      hb_retl( FALSE );
   else
      hb_retl( pClientConn->pSession->Started || pClientConn->pSession->Count>0 );

   return;
}

/*
 * Processamos o buffer passado como argumento e restauramos os dados da sessao
 * previamente salvos.
 * 31/07/2008 - 16:36:54
 */
WX_RES wxSession_ParseRawData( PConnection pClientConn, char *Buffer, ULONG Length ) 
{                                                                                      
   PHB_ITEM pKey, pValue;
   PRepositoryItem pItem, pLast;
   
   WX_RES Result = WX_SUCCESS;
   char *RawData = Buffer;

   HB_TRACE( HB_TR_DEBUG, ("wxSession_ParseRawData( %p, %lu, '%s' )", pClientConn, Length, Buffer ));
   
   /*
    * Zeramos quaisquer valores já introduzidos na sessao atual, para evitar
    * duplicidade de valores.
    */
   wxSession_Clear( pClientConn, TRUE );
   
   pKey   = hb_itemNew( NULL );
   pValue = hb_itemNew( NULL );
   pLast  = NULL;
      
   while (RawData)
   {      
         /* 1º Pegamos o nome da chave */
         HB_TRACE( HB_TR_DEBUG, ("  PEGAR KEY ..: %s", RawData ));
         RawData = wxItemDeserialize( RawData, pKey );
         
         /* Deu algum tipo de erro? */
         if (!RawData)
         {
            Result = WX_FAILURE;
            break;
         }
         
         /* 2º Pegamos o valor do item */
         HB_TRACE( HB_TR_DEBUG, ("  PEGAR VALOR : %s", RawData ));
         RawData = wxItemDeserialize( RawData, pValue );
         
         /* Deu algum tipo de erro? */
         if (!RawData)
         {
            Result = WX_FAILURE;
            break;
         }
         
         /* 3º Passo, agora adicionamos este par ao Session da conexao atual */
         pItem = RepositoryList_AddItem( pLast, pValue );
         pItem->Key = xStrDup( hb_itemGetCPtr( pKey ) );
         
         if (!pClientConn->pSession->List)
            pClientConn->pSession->List = pItem;
            
         pClientConn->pSession->Count ++;
         pLast = pItem;         
   }
   
   if (pKey)   hb_itemRelease(pKey);
   if (pValue) hb_itemRelease(pValue);
   if (Buffer) hb_xfree( Buffer );   
        
   pClientConn->pSession->Started = TRUE;
   return Result;
}
 
/*
 * Restaura a sessão, de um arquivo ou de um buffer passado como argumento
 * que pode provir de QUERYSTRING ou de um COOKIE.
 * 11/12/2006 19:36:36
 */
WX_RES wxSession_Load( PConnection pClientConn )
{
   PSession pSession;
   ULONG L;
   char *T;

   HB_TRACE( HB_TR_DEBUG, ("wxSession_Load( %p )", pClientConn ));
   
   pSession = pClientConn->pSession;
   
   /* Não informou o nome correto? */
   if ( wxSession_PrepareName(pClientConn) != WX_SUCCESS )
      return WX_FAILURE;
   
   HB_TRACE( HB_TR_DEBUG, ("  sessão valida em: %s", pSession->FileName ));
   HB_TRACE( HB_TR_DEBUG, ("    -- FileExists: %d", FileExists( pSession->FileName ) ));
   
   /* O arquivo da sessão solicitada existe no HD local ???*/
   if (!FileExists( pSession->FileName ))
      return WX_FAILURE;
   
   /* Lemos o arquivo inteiro para a memoria */
   T = xStrReadFile( pSession->FileName, &L);

   HB_TRACE( HB_TR_DEBUG, ("    - Bytes lidos: %lu", L ));

   if (!T)
      return WX_FAILURE;

   /* Jogamos os dados lidos para o Parser processar... */
   return wxSession_ParseRawData( pClientConn, T, L );
}

/*
 * Se ele mudou o nome do cookie ou algo assim ele irá chamar esta funcao
 * para lermos os dados serializados! Então mandamos bala!
 * 19/12/2006 11:03:22
 */
WX_RES wxSession_Start( PConnection pClientConn )
{ 
   PSession pSession;
   PRepositoryItem pTemp, pItem;
   char *Name;
   int i;
   
   HB_TRACE( HB_TR_DEBUG, ("wxSession_Start( %p )", pClientConn ));
   
   if (!pClientConn)
      return WX_FAILURE;
   if ( wxSession_Ensure(pClientConn) != WX_SUCCESS )
      return WX_FAILURE;

   pSession = pClientConn->pSession;
   
   /* Espere aê: a session JÁ ESTAVA iniciada e ele quer iniciar de novo? */
   if (pSession->Started)
   {
		char Text[]  = {"ERROR: A session had already been started - ignoring session_start() on "};
		char *Source = wxGetModuleName( WX_PRG_LONG );
		                                                                 
		wxConnection_SendText( pClientConn, Text, strlen( Text) );
		wxConnection_SendText( pClientConn, Source, strlen( Source) );
   		
		hb_xfree(Source);
      return WX_FAILURE;
   }
   /*
    * Pega o nome do Cookie que identifica o ID desta session. 
    * 11/12/2006 17:11:45
    */ 
   if (!pSession->CookieName)
      pSession->CookieName = xStrNewBuff( strlen(DEF_SESSION_NAME), DEF_SESSION_NAME );  

   HB_TRACE( HB_TR_DEBUG, ("  Procurando Cookie -> %s", pSession->CookieName ));
   HB_TRACE( HB_TR_DEBUG, ("  pSession->ID is   -> %s", pSession->ID ));
   
   /*
    * Aqui tentamos detectar se existe um cookie com o mesmo nome da session a 
    * ser restaurada. Se nao houver um cookie com este nome, tentamos achar um
    * campo recebido via GET ou POST com o ID da sessão.
    * 01/08/2008 - 21:32:49
    */   
   pTemp = pClientConn->pCookies; // 1ª tentativa..
   pItem = NULL;  
   Name  = xStrUpperNew( pSession->CookieName, -1 );  // procura em letras maisuc

   /* Um loop básico só pra evitar repetição de código... */
   for ( i=1; i<=2; i++, pTemp = pClientConn->pFields /* 2ª tentativa */ )
   {
      while (pTemp)
      {
            HB_TRACE( HB_TR_DEBUG, ("  %d - %s", i, pTemp->Key ));
            
            /* Achamos o item desejado? */
            if (!pTemp->Key )
               continue;
            
            if (!strcmp( pTemp->Key, Name ))
            {
               pItem = pTemp;
               break;
            }
            pTemp = pTemp->pNext;
      }      
      if (pItem) break;
   }      
   hb_xfree( Name );
   
   /* Achou um item com o nome que desejamos? */
   HB_TRACE( HB_TR_DEBUG, ("  Resultado do Seek -> %p || %s || %d", pItem, RepositoryList_GetCPtr( pItem, 0 ), i ));
   
   if (pItem)
   {
      HB_TRACE( HB_TR_DEBUG, ("  Ok, achamos um COOKIE/GET/POST na posiçao --> %d", i ));
      
      pSession->ID[0] = '\0';
      strcat( pSession->ID, RepositoryList_GetCPtr( pItem, 0 ) );
            
      // TODO: Teste se o arquivo existe, se nao existir GERE OUTRO ID DE SESSAO
      //       para evitar invasões!!!
   } else {
   
      // Aqui forçamos uma nova session
      i = 1; //(pSession->ID[0]) ? 3: 1;
   }
   /*
    * Aqui no session_start() devemos enviar o cookie da sessão pro navegador do
    * cliente. Este Cookie contem o ID da session que nada mais é do que o nome 
    * de arquivo gerado no HD.
    *              
    * No entanto o Cookie só deve ser propagado se ele puxou o valor atual DE UM 
    * COOKIE mesmo ou caso ele esteja iniciando uma session novaa.. mas nunca deve
    * ser enviado se ele puxou o ID via URL!!!
    * 01/08/2008 - 19:57:28 
    */
   if ( i == 1 && wxSession_WriteCookie(pClientConn) != WX_SUCCESS )
      return WX_FAILURE; 
       
   /*
    * Se ele achou o item com o nome igual ao solicitado, ajustamos o ID da session
    * para ser carregado cdireto do HD... entao pSession->Started deve ser ajustado
    * diretamente  pelo valor  de retorno de wxSession_Load().. caso contrário esta 
    * será a primeira  vez  que  ele  está  CRIANDO  a  session e com isto, podemos 
    * seguramente retornar WX_SUCCESS indicando sucesso na criação da session atual
    * 02/08/2008 - 11:30:13
    */
   if (!pSession->ID[0])
   {
      HB_TRACE( HB_TR_DEBUG, ("  Iniciamos nova session.." ));
      pSession->Started = TRUE;
      return WX_SUCCESS;
   }
   /* Neste ponto, se houver algo para ser lido do HD e deserealizado - será! */
   HB_TRACE( HB_TR_DEBUG, ("  Restaurando session anteior!" ));
   return wxSession_Load( pClientConn );
}

/**
 * Session_Start( [<pConn>] ) -> lStarted
 *
 * Inicia uma nova sessão para a conexão atual ou carrega para a memória uma sessão
 * que tenha sido previamente gravada em disco.
 * @see @request(FUNCLIST)
 * 01/08/2008 - 21:51:24
 */
HB_FUNC( SESSION_START )
{
   HB_THREAD_STUB   
   PConnection pClientConn;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
   } else {
      pClientConn = wxGetClientConnection();
   }
   
   if ( wxSession_Start( pClientConn ) == WX_SUCCESS )
      hb_retl( TRUE );
   else
      hb_retl( FALSE );
   return;  
}

/*
 * session_set_cookie_params( <nLifetime>, [<cPath>], [<cDomain>], [<lSecure>], 
 *                           [<lHttponly>] ) --> NIL
 * Define os parâmetros do cookie de sessão.
 * 02/08/2008 - 13:52:43
 */
HB_FUNC( SESSION_SET_COOKIE_PARAMS )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   
   long lifetime;
   char *path;
   char *domain;
   BOOL secure;
   BOOL httponly;

   if (ISPOINTER(1))
   {
      pClientConn = (PConnection) hb_parptr(1);
   } else {
      pClientConn = wxGetClientConnection();
   }

   if (!pClientConn)
      return; 
}

/*
 * Apaga todas as informações registradas na session vinculada à conexão passada
 * como argumento e deleta o arquivo da pasta!
 * 14/08/2008 - 23:17:07
 */
WX_RES wxSession_Destroy( PConnection pConn )
{
   HB_TRACE( HB_TR_DEBUG, ("wxSession_Destroy( %p )", pConn ));
   
   if (!pConn)
      return WX_FAILURE; 

   if (!pConn->pSession )
      return WX_SUCCESS;   
   
   if (wxSession_PrepareName( pConn ) != WX_SUCCESS )
      return WX_FAILURE;
      
   if (FileExists( pConn->pSession->FileName )) 
      hb_fsDelete( pConn->pSession->FileName );
      
   /* Destruimos os dados desnecessários */
   wxSession_Clear( pConn, FALSE );
   return WX_SUCCESS ;
}

/**
 * Session_Destroy( [<pConn>] ) --> lSuccess
 *
 * Apaga todas as informações registradas na sessão atual e apaga o arquivo gravado
 * em disco com quaisquer dados vinculados à conexao passada como
 * argumento. Se nenhum argumento for passado, a conexão atualmente ativa (baseada
 * na thread atual) será usada.
 * @see @request(FUNCLIST)
 * 14/08/2008 - 23:23:27
 */
HB_FUNC( SESSION_DESTROY )
{
   HB_THREAD_STUB   
   PConnection pClientConn;
   
   if (ISPOINTER(1))
      pClientConn = (PConnection) hb_parptr(1);
   else
      pClientConn = wxGetClientConnection();

   HB_TRACE( HB_TR_DEBUG, ("SESSION_DESTROY( %p )", pClientConn ));
   
   if (wxSession_Destroy( pClientConn ) == WX_SUCCESS)
      hb_retl(TRUE);
   else
      hb_retl(FALSE);
   
   return;
}
