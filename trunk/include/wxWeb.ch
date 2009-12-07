/*
 * WxWeb CGI & ISAPI Internet Library
 * By Vailton Renato, renato@sqllib.com.br!
 * 10/07/2006
 */

*#define WXWEB_IGNORE_CMD_ADDONS    // Desabilita os comandos personalizados embutidos na wxWeb
*#define WXWEB_DISABLE_AUTOLOAD     // Desabilita o carregamento automatico das funcoes principais da wxWeb
*#define WXWEB_ENABLED_PHP_EXT      // Ativa o suporte para comandos semelhantes ao do PHP pela wxWeb

#ifndef WXWEB_DISABLE_AUTOLOAD
   REQUEST wxAutoLoad

   /*
    * Caso ele esteja utilizando a op‡Æo de AutoLoad, nao deixaremos ele utilizar
    * INITs e EXITs PROCEDURES para tentar evitar problemas de memoria.
    * 25/11/2009 - 09:07:59
    */
   #command INIT PROCEDURE <x>      => "Unsupported command"
   #command EXIT PROCEDURE <x>      => "Unsupported command"
#endif

#ifndef WXWEB_IGNORE_CMD_ADDONS
   #translate TRUE         => .T.
   #translate FALSE        => .F.
   
   #Command IF <Cond> THEN <*Cmd1*> ;
         => IF <Cond> ; <Cmd1> ; End
#endif

#ifndef WXWEB_IGNORE_CMDS
   #command ?  [ <list,...> ]      =>  wxQout( <list> )
   #command ?? [ <list,...> ]      => wxQQout( <list> )
   #command ECHO  [ <list,...> ]   => wxQQout( <list> )
   #command PRINT [ <list,...> ]   => wxQQout( <list> )
   #command TEXT                   => text wxQOut,wxQQOut

   #xtranslate Qout(               =>  wxQout(      // to avoid conflicts with [x]Harbour functions
   #xtranslate QQout(              => wxQQout(      // to avoid conflicts with [x]Harbour functions
   #xtranslate DispOut(            => wxQQout(      // to avoid conflicts with [x]Harbour functions
   #xtranslate DevOut (            => wxQQout(      // to avoid conflicts with [x]Harbour functions
#endif

/*
 * Se vocˆ ativar no seu c¢digo o #DEFINE WXWEB_ENABLED_PHP_EXT poder  utilizar
 * as constantes abaixo para trabalhar em seus projetos como se estivesse rodando
 * um script com as fun‡äes do PHP
 */
#ifdef WXWEB_ENABLED_PHP_EXT
   #xtranslate Server(             => wxServer(     // to avoid conflicts with [x]Harbour functions
#endif

   #define WEB_CGI_MODE     1
   #define WEB_ISAPI_MODE   2
   #define WEB_STAND_ALONE  3

   /* API results */             
   #define WX_FAILURE      0
   #define WX_SUCCESS      1
   
   #define CRLF                          (HB_OsNewLine())
   
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
   #define REQUEST_URI             30    
   #define HTTP_CONNECTION         31
   #define HTTP_COOKIE             32
   #define HTTP_AUTHORIZATION      33
   #define AUTH_PASSWORD           34
   #define AUTH_TYPE               35     // http://www.faqs.org/rfcs/rfc2617.html
   #define AUTH_USER               36
   #define SESSION_PATH            37     
   #define MAX_SERVER_VARS         38     /**** MAX COUNT ****/   
   
   /* Tipo de cache aplicado à conexão, determinado por wxConnection_CacheType() */
   #define WX_CACHE_NONE            0
   #define WX_CACHE_DEFAULT         1
   #define WX_CACHE_FULL            2
   
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
