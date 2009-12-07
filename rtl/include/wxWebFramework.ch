/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb - by Vailton Renato da Silva, (c) 2006
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 14/11/2006 10:03:30
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxWebFramework.ch
 *                            
 *  Constantes manifestas para todo o projeto!
 *
 * 06/05/2006 - Primeira versão.
 * 25/11/2006 - Apresentação no 4° Evento FW, o pessoal delirou!!
 * 01/12/2006 - LIB completamente reescrita para suportar COOKIES. (AGORA VAI!)
 * 01/07/2008 - Reescrita inteiramente em C para compatibilidade com MT do xHB
 * 22/11/2009 - LIB convertida para trabalhar com Harbour 2.0.0beta3
 *---------------------------------------------------------------------------*/
#ifndef WXWEB_INCLUDE
   #define WXWEB_INCLUDE
   #define VERSAO_COMERCIAL
   
#ifndef VERSAO_COMERCIAL
   #ifdef WEB_DEBUG
      #define XWEB_NAME        "wxWeb DBG (DEMO)"
   #else
      #define XWEB_NAME        "wxWeb DBG (DEMO)"
   #endif
#else
   #ifdef WEB_DEBUG
      #define XWEB_NAME        "wxWeb (DBG)"
   #else
      #define XWEB_NAME        "wxWeb"
   #endif
#endif

   #define WXWEB_VERSION    "1.9.7"
   #define WXWEB_VERSION2   197

   #define WEB_CGI_MODE     1
   #define WEB_ISAPI_MODE   2
   #define WEB_STAND_ALONE  3

   #define WX_NONE          0
   #define WX_HEADER        1
   #define WX_BODY          2
   #define WX_SESSION_NAME_LEN     255

   #define WXWEB_OBJ_SIGNATURE_STR "|~|03J:C14ssN4M3:|~|"        
   #define WXWEB_OBJ_SIGNATURE_LEN 20
   
   #define WXWEB_DEFEXT    ".xweb"
   
   /* API results */             
   #define WX_FAILURE            0
   #define WX_SUCCESS            1
   
   /* Tipo de formatação disponivel para a funão wxGetModuleName() */
   #define WX_PRG_SHORT          0
   #define WX_PRG_LONG           1

   /* Common error codes */
   #define WX_NOERROR            0
   #define WX_ERROR_SUBSYSTEM_INVALID 1
   
   /* Tipo de cache aplicado à conexão, determinado por wxConnection_CacheType() */
   #define WX_CACHE_NONE         0
   #define WX_CACHE_DEFAULT      1
   #define WX_CACHE_FULL         2
      
   /* Tipo de template atualmente carregado na memoria */
   #define WX_SCRIPT_NONE           0     // Nenhum script carregado na memoria
   #define WX_SCRIPT_WXS            1     // O script atualmente carregado é um WXS  
   #define WX_SCRIPT_HTML           2     // O script atual esta no formato HTML ou em texto puro
   #define WXS_SIGNATURE            (CHR(192)+'HRB')

   /*
    * Tamanho máximo (seguro) para uma URL (Uniform Resource Locator) na wxWeb:
    * 
    * http://www.boutell.com/newfaq/misc/urllength.html  :O !!!!
    * http://support.microsoft.com/kb/208427
    */ 
   #define URL_MAX_LEN           2048
   /*
    * Tamanho maximo para o nome de um campo recebido via GET/POST 
    */    
   #define MAX_FIELD_LEN         65
   /*
    * Tamanho máximo para o ID de uma sessão
    */
   #define MAX_SESSION_LEN       40
   /* Nome padrão para o Cookie das sessões */
   #define DEF_SESSION_NAME      "sid"
   /*
    * Tempo de vida padrão para uma session em segundos. 
    * O default é 20 minutos --> (60 segs * 20mins) = 1200 segs
    */
   #define DEF_SESSION_LIFETIME  1200
      
   #define VIEWSTS_KEY     1
   #define VIEWSTS_VALUE   2

   #define SCRIPT_KEY      1
   #define SCRIPT_VALUE    2
   #define SCRIPT_POS      3
   
   #define HFIELD_KEY      1
   #define HFIELD_VALUE    2

   #define CSS_KEY         1
   #define CSS_VALUE       2

   #define ATTR_KEY        1
   #define ATTR_VALUE      2

   #ifndef WXWEB
      #include "common.ch"
   
      * Comandos Personalizados
      #Command If <Cond> then <*Cmd1*> ;
               => If <Cond> ; <Cmd1> ; End
               
      /*
      #command VIEWSTATE PROPERTY <x>  [DEFAULT <d>] => ;
                 ; 
                 ACCESS <x>      INLINE ::ViewState:getViewState( <"x">, <d> )     ;;
                 ASSIGN <x>(v)   INLINE ::ViewState:setViewState( <"x">, v, <d> )   
      
      /**/
      #command VIEWSTATE PROPERTY <x>  [DEFAULT <d>] => ;
                 ; 
                 ACCESS <x>      INLINE ::ViewState:getViewState( <"x">, <d> )     ;;
                 ASSIGN <x>(v)   INLINE ::ViewState:setViewState( <"x">, v, <d> )   
      
      * Another Contants
      #translate TRUE         => .T.
      #translate FALSE        => .F.
      #translate INHERITED    => Super:
      #translate lUpper(<x>)  => alltrim( upper( <x> ) )
      #translate NTrim(<x>)   => alltrim( str( <x> ) )
      #translate Full(<x>)    => !Empty( <x> )
   
      #define CRLF (HB_OSNewLine())
      #define ENUM_CONFIG_OPTIONS 'register_public,private_path,temp_path,session_path,javascript_path,document_path,default_page'
   #endif

   /*
    * Error constants
    */
   #define ERR_GENERIC        1000 // "%1" } ,;                                                                
   #define ERR_ARGERROR       1001 // "Erro de argumento: %1" } ,;                                             
   #define ERR_FILENOTFOUND   1002 // "Arquivo não encontrado: %1" } ,;                                        
   #define ERR_NODEFAULTPAGE  1003 // "Nenhuma página especificada para 'default_page' em main.xweb" } ,;
   #define ERR_HEADERSHASSEND 1004 // Erro enviando os cabeçalhos iniciais da pagina
   #define ERR_SSIDWRITEERROR 1005 // Erro na tentativa de persistir os dados da seção." } ,;                          
   
   // TWebScript constants
   #define JS_BEGIN_FORM      0   // Default abaixo da TAG <form>
   #define JS_END_FORM        1   // acima da TAG </form>
   #define JS_BEGIN_HEAD      2   // acima da tag </HEAD>
   #define JS_BEGIN_CSS       3   // códigos CSS implantados na página! =D
   #define JS_AT_SUBMIT       4   // Dentro do script de validação do SUBMIT do FORM
   #define JS_ALL_FORM       99   // Em qqer posição
   
   // TWebPage constants
   #define PAGE_JSCRIPT       "TWebPageDOPostBack"
   #define PAGE_FOCUSSCRIPT   "TWebPageDoSetFocus"
   
   // TWebListBox constants
   #define LISTBOX_JSCRIPT    "TWebListBoxDoPostBack"
   #define LISTITEM_CAPTION   1
   #define LISTITEM_VALUE     2
   #define LISTITEM_CHECKED   3
   
   // TWebRequitedValidator
   #define REQUITEDVALIDATOR_JSCRIPT  "TWebRequitedValidatorJScript"
   
   // TWebDataGrid constants
   #define DATA_JSCRIPT       "TWebDataGridRequireJS"
   #define DATA_NEXTPREV_PAGES      0
   #define DATA_NUMERIC_PAGES       1
   
   // TWebDataGrid Event Types
   #define DATA_EVENT_NONE          0
   #define DATA_EVENT_CUSTOM      999
   
   #define DATA_EVENT_GOTOPAGE      1
   #define DATA_EVENT_PREVIOUSPAGE  2
   #define DATA_EVENT_NEXTPAGE      3
   #define DATA_EVENT_SELCHANGE     4
   
   // TWebDataGridColumn Types
   #define DATA_BOUNDCOLUMN         0
   #define DATA_BUTTONCOLUMN        1
   #define DATA_HYPERLINKCOLUMN     2
   #define DATA_DEFAULTTYPECOLUMN   DATA_BOUNDCOLUMN
   
   // Server variables values
   #define REQUEST_METHOD           0           
   #define SERVER_PROTOCOL          1
   #define SERVER_URL               2
   #define QUERY_STRING             3
   #define PATH_INFO                4
   #define PATH_TRANSLATED          5
   #define HTTP_CACHE_CONTROL       6
   #define HTTP_DATE                7
   #define HTTP_ACCEPT              8
   #define HTTP_FROM                9
   #define HTTP_HOST               10
   #define HTTP_IF_MODIFIED_SINCE  11 
   #define HTTP_REFERER            12
   #define HTTP_USER_AGENT         13
   #define HTTP_CONTENT_ENCODING   14
   #define HTTP_CONTENT_TYPE       15
   #define HTTP_CONTENT_LENGTH     16
   #define HTTP_CONTENT_BUFFER     17
   #define HTTP_CONTENT_VERSION    18
   #define HTTP_DERIVED_FROM       19
   #define HTTP_EXPIRES            20
   #define HTTP_TITLE              21
   #define REMOTE_ADDR             22
   #define REMOTE_PORT             23
   #define REMOTE_HOST             24
   #define SCRIPT_NAME             25     
   #define SERVER_SOFTWARE         26 
   #define SERVER_NAME             27
   #define SERVER_PORT             28
   #define RESPONSE_CONTENT        29
   #define REQUEST_URI             30     // 05/10/2008 - 21:41:04 
   #define HTTP_CONNECTION         31
   #define HTTP_COOKIE             32
   #define HTTP_AUTHORIZATION      33
   #define AUTH_PASSWORD           34
   #define AUTH_TYPE               35     // http://www.faqs.org/rfcs/rfc2617.html
   #define AUTH_USER               36
   #define SESSION_PATH            37     
   #define MAX_SERVER_VARS         38     /**** MAX COUNT ****/   
#endif                                
