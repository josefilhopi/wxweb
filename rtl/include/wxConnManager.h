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
 *  Arquivo..: wxConnManager.h
 *                            
 *  Funções para manipulação da conexão com o cliente
 *
 *---------------------------------------------------------------------------*/
#ifndef WXCONNMANAGER_HEADER  
   #define WXCONNMANAGER_HEADER   

   #define WXWEB_MAX_CONN_NUM                65535
   #define WXWEB_MAX_MODULE_LEN              128

   #include "wxRepositoryItem.h"
   
   typedef enum { ctCGI = 0, ctISAPI, ctDSO } TConnectionType;
   typedef enum { mtNone = 0, mtGet, mtPost, mtAny } TMethodType;
   
   /*
    * cfInit      => Assim que iniciar a estrutura
    * cfFinalize  => Assim que a conexão for finalizada
    */
   typedef enum { cfInit = 0, ctBeforeFinalize, ctAfterFinalize } TConnectionFlag;
   
   /*
    * A classe base que representa a conexão com o cliente
    * 8/12/2006 08:22:19
    */
   typedef WX_RES (*TOutPutFunc)(void *pConn, BYTE *Source, ULONG Length );
   typedef WX_RES (*TStateFunc)(void *pConn, TConnectionFlag Flag, WX_PTR Cargo );
   
   typedef struct _Session
   {
      char ID[MAX_SESSION_LEN+1];   // ID desta session... como string gerada em MD5 por default
      char *CookieName;             // Nome do cookie a ser enviado para o browser
      char *FileName;               // Nome completo do arquivo a ser gerado no HD
      int   Count;                  // Quantidade de informações armazenadas

      // TODO: char *OutPutFunc;             // Nome da função em xHB que poderia pegar isto e gravar em BACNO!! ao inves do HD      
      PRepositoryItem  List;        // Os valores anexados à nós!
      PRepositoryItem  Last;        // Ultimo item pesquisado via SESSION()
      
      BOOL  Started;                // Indica de o conteudo do arquivo de sessao já foi lido do HD
      BOOL  Changed;                // Se a sessão não tiver tido alterada, nao gravamos nada!    
      BOOL  Written;                // Indica se o conteudo da sessão foi descarergado no HD, impendindo qqer alteração na session atual e futuras gravações       

      LONG  CookieLife;             // Tempo de vida em segundos da session atual. -1 o cookie será valido apenas enquanto o browser nao for fechado.
      char *CookiePath;
      char *CookieDomain;
      BOOL  CookieSecure;
      BOOL  CookieHttpOnly;
   } TSession;
   
   typedef TSession *PSession;
     
   typedef struct _Connection
   {
      TConnectionType ConnType;
      TMethodType PostMethod;      

      long ThreadID;                                                 // ID da Thread anexada à esta connection
      int  Handle;                                                   // Handle da conexão - setado livremente pela aplicação 
      int  CacheType;                                                // Indica o tipo de CACHE utilizado para esta Connection
      BYTE LastType;
      
      /* Controle geral para Output dos dados e Bufferização da saida de video */
      char *ContentType;  
      PRepositoryItem HeaderFirst;                                   // Ponteiro para o primeiro item do header(agilizar impressao)
      PRepositoryItem HeaderLast;                                    // Ponteiro para o ultimo item do header  (agilizar adição)
      
      PRepositoryItem BodyFirst;                                     // Ponteiro para o primeiro item do buffer (agilizar impressao)
      PRepositoryItem BodyLast;                                      // Ponteiro para o ultimo item do buffer   (agilizar adição)
      
      TStateFunc      pState;                                        // Suporte para funções de CALLBACK, STATUS, TRIGGERS dentre outros... 15/07/2008 - 22:08:26
      TOutPutFunc     pOutPut;                                       // Ponteiro pra função que controla a saida do buffer
      char *OutPutFunc;                                              // Nome da rotina em xHB pra cuidar disto
      void *OutPutSymbol;                                            // Pointeiro para o SYMBOL do mesmo.
      void *OutPutCargo;                                             // Reservado para uso da função OutputFunc      
            
      /* Controle de erros */
      int   ErrorCode;
      char *ErrorMsg;
      char *OutPutStartedAt;                                         // Contem o nome da rotina, linha e modulo onde se gerou a saida dos dados - 21/07/2008 - 14:43:18
      
      /* Controle de variaveis anexadas à esta conexão */
      PSession pSession;                                             // Informações gerais sobre a session atual
      PRepositoryItem *pServer;                                      // Variaveis ateladas a esta conexao
      PRepositoryItem  pCookies;                                     // Guarda os cookies recebidos                                 09/12/2006 08:17:06
      PRepositoryItem  pFields;                                      // Campos recebidos via GET/POST/PUT
      PRepositoryItem  pConfig;                                      // Informações de configurações específicas desta conexão

      int   ServerCount;                                             // Quantidade de informações armazenadas
      int   FieldCount;                                              // Quantidade de campos recebidos
      int   CookieCount;                                             // Quantidade de cookies disponíveis
      
      /* Ponteiros para o proximo item e o anterior respectivamente  */
      struct _Connection *pNext;
      //struct _Connection *pPrevious;
   } TConnection;  

   typedef TConnection *PConnection;
   
   #define HB_FETCH_THREAD       PConnection pClientConn = wxGetClientConnection();
         
   PConnection wxGetClientConnection( void );

   WX_RES wxConnection_Initialize( PConnection pConn );
   WX_RES wxConnection_Finalize( PConnection pConn );
   WX_RES wxConnection_Prepare( PConnection pConn );
   
   WX_RES wxConnection_Print( PConnection pConn );
   WX_RES wxConnection_SendHeader( PConnection pConn, BYTE *Text, ULONG Size );
   WX_RES wxConnection_SendText( PConnection pConn, BYTE *Text, ULONG Size );
   
   PConnection wxConnection_Create( int Handle, char *OutPutFunc );
   WX_RES wxConnection_Destroy( PConnection pConn );
   
   WX_RES wxWebRegisterOutputFunc( PConnection pClientConn, char *FuncName );
   WX_RES wxServerCount( PConnection pClientConn, int Count );
   WX_RES wxServerAdd( PConnection pClientConn, int Pos, BYTE *Value, ULONG Length, char *KeyName );
   WX_RES wxFieldAdd( PConnection pConn, char *FieldName, BYTE *Value, ULONG Length, BOOL Encoded );

   char *wxConnection_GetVariable( PConnection pConn, char *Name, BOOL *bToDelete);
   PRepositoryItem wxGetConfig( PConnection pClientConn, char *Name, PHB_ITEM pValue );
   
   /*
   char *wxConnection_GetFormData(ULONG &length);
   
   char *wxConnection_GetConfig( PConnection pConn, char *Key, char *Default );
   bool  wxConnection_SetConfig( PConnection pConn, char *Key, char *Value );
   
   void wxConnection_ParseCookies( PConnection pConn );
   void wxConnection_ParseFormData( PConnection pConn );
   void wxConnection_ParseConfigFile( PConnection pConn );
   
   void wxConnection_SessionValidate( PConnection pConn );
   bool wxConnection_SessionCreateNewID( PConnection pConn );
   /**/   
#endif
