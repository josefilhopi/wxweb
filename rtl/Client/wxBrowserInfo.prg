/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 09/06/2007 - 15:37:52
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxBrowserInfo.prg
 *                            
 *  Funcoes diversas para informaá‰es do lado do cliente
 *
 *---------------------------------------------------------------------------*/
#include "simpleio.ch"
#include "common.ch"
#include "wxWebFramework.ch"

/*
 * Alguns links:
 *
 * http://en.wikipedia.org/wiki/User_agent
 * http://www.zytrax.com/tech/web/browser_ids.htm
 * http://msdn2.microsoft.com/en-us/library/ms537503.aspx (lindo isto aqui!)
 *
 *
 * Algumas macros para uso na documentaá∆o abaixo...
 *
 * @define OS_FUNC_LIST wxOSVersion() wxIsPalmOS() wxIsPocketPC() wxIsSmartPhone() wxIsUnix()
 * @define OS_FUNC_LIST wxIsWin31() wxIsWin32() wxIsWin7() wxIsWin95()
 * @define OS_FUNC_LIST wxIsWin98() wxIsWinME() wxIsWinSE() wxIsWinVista()
 * @define OS_FUNC_LIST wxIsWinXP() wxIsWinXPSP2()
 *
 */
/**
 * Retorna uma string informando o tipo de navegador instalado no cliente com base
 * no conte£do do header User-Agent da requisiá∆o atual, se houver. Esta funá∆o
 * tenta idenfificiar o navegador do usu†rio ou melhor, o "agente de usu†rio" pelo
 * qual a p†gina est† sendo acessada.
 *
 * Um exemplo t°pico do retorno desta funá∆o seria algo como:
 * <code>
 * Mozilla/4.5 [en] (X11; U; Linux 2.2.9 i586)
 * Mozilla/4.0 (compatible; MSie 5.01; Windows 98)
 * Opera/7.54 (Windows NT 5.1; U) [en]
 * </code>
 *
 * AlÇm de outras coisas, vocà pode utilizar o retorno desta funá∆o para
 * personalizar a geraá∆o de suas p†ginas para as capacidades do agente do usu†rio
 * que efetuou a requisiá∆o.
 *
 * @see wxIsIE() wxIsFireFox() wxIsChrome() wxIsOpera() wxIsNetscape()
 * 9/6/2007 - 15:23:33
 */  
FUNCTION wxGetClientUserAgent()
	RETURN wxGetEnv( 'HTTP_USER_AGENT' )
	
/**
 * Retorna .T. se o usu†rio que solicitou a requesiá∆o atual estiver usando o
 * Microsoft Internet Explorer ou similar. Esta funá∆o faz uso do cabeáalho USER
 * AGENT para tentar detectar o navegador em uso.
 * 9/6/2007 @ 15:25:10
 *
 * Possiveis valores para wxGetClientUserAgent() neste caso para
 * Internet Explorer (Windows):
 * <pre>
 *  ie6 (on WinXP):
 *  Mozilla/4.0 (compatible; MSie 6.0; Windows NT 5.1)
 *  
 *  ie5.5 (on W2K):
 *  Mozilla/4.0 (compatible; MSie 5.5; Windows NT 5.0)
 *  
 *  ie5.01 (on Win98):
 *  Mozilla/4.0 (compatible; MSie 5.01; Windows 98)
 * </pre>
 *
 * @see wxIsFireFox() wxGetClientUserAgent()
 */
FUNCTION wxIsIE()
   RETURN ' MSIE ' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna uma string com o n£mero da vers∆o do Microsoft Internet Explorer
 * utilizada pelo cliente que requisitou a solicitaá∆o atual.
 *
 * @see wxIsIE() wxGetClientUserAgent()
 * 9/6/2007 @ 15:25:10
 */
FUNCTION wxIEversion()
   LOCAL Version := Upper( wxGetClientUserAgent() )
   LOCAL Pos     := At( ' MSIE ', Version ) 
   
   IF Pos <> 00
      Version := Subst( Version, Pos + 6)
      Version := Alltrim( Version )
      Pos     := At( ';', Version )
      
      IF Pos <> 00 THEN; 
         Version := Subst( Version, 1, Pos -1 )
   ELSE
      Version := ''
              
   End   
   RETURN Version

/**
 * Retorna .T. se o usu†rio que solicitou a requesiá∆o atual estiver usando o
 * Mozilla FireFox ou similar. Esta funá∆o analisa o USER AGENT para determinar
 * o navegador em uso. Os possiveis valores para wxGetClientUserAgent() no caso
 * para o FireFox (windows e linux):
 * <pre>
 *  Firefox 0.9.3 (on Linux):
 *  Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7) Gecko/20040803 firefox/0.9.3
 *
 *  Firefox 2.0.0.4 (on Windows):
 *  Mozilla/5.0 (Windows; U; Windows NT 5.1; pt-BR; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4
 * </pre>
 * @see wxFireFoxVersion() wxGetClientUserAgent()
 * 9/6/2007 @ 15:25:10
 */
FUNCTION wxIsFireFox()
   RETURN 'FIREFOX' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna uma string com o n£mero da vers∆o do Mozilla FireFox em uso pelo cliente
 * que efetuou a requisiá∆o atual. Caso o cliente n∆o esteja utilizando o FireFox
 * ser† retornado uma string vazia.
 *
 * @see wxIsFireFox() wxGetClientUserAgent()
 * 9/6/2007 @ 15:25:10
 */
FUNCTION wxFireFoxVersion()
   LOCAL Version := Upper( wxGetClientUserAgent() ) + ' '
   LOCAL Pos     := At( ' FIREFOX', Version ) 
   
   IF Pos <> 00
      Version := Subst( Version, Pos + 9)
      Version := LTrim( StrTran( Version, ';', ' ') )
      Pos     := At( ' ', Version )
      
      IF Pos <> 00 THEN; 
         Version := Subst( Version, 1, Pos -1 )
   ELSE
      Version := ''
              
   End   
   RETURN Version
/**
 * Retorna .T. se o usuario estiver usando o navegador Opera para efetuar a
 * requisiá∆o atual. Alguns possiveis valores para wxGetClientUserAgent() neste
 * caso seriam (tanto em windows e linux):
 * <code>
 *  Opera 7.54 (on WinXP):
 *  Mozilla/4.0 (compatible; MSie 6.0; Windows NT 5.1) Opera 7.54 [en]
 *  Opera/7.54 (Windows NT 5.1; U) [en]
 *  
 *  (first example is spoofed as ie6, second without spoofing)
 * </code>
 * @see wxOperaVersion() wxGetClientUserAgent()
 * 9/6/2007 @ 15:25:10
 */
FUNCTION wxIsOpera()
   RETURN ' OPERA' $ ' ' + Upper( wxGetClientUserAgent() )
/**
 * Retorna uma string com o n£mero da vers∆o do navegador Opera em uso pelo cliente
 * que efetuou a requisiá∆o atual. Caso o cliente n∆o esteja utilizando o Opera
 * ser† retornado uma string vazia.
 *
 * @see wxIsOpera() wxGetClientUserAgent()
 * 9/6/2007 @ 15:25:10
 */
FUNCTION wxOperaVersion()
   LOCAL Version := ' ' + Upper( wxGetClientUserAgent() ) + ' '
   LOCAL Pos     := At( ' OPERA', Version ) 
   
   IF Pos <> 00
      Version := Subst( Version, Pos + 7)
      Version := LTrim( Version )
      Pos     := At( ' ', Version )
      
      IF Pos <> 00 THEN; 
         Version := Subst( Version, 1, Pos -1 )
   ELSE
      Version := ''
              
   End   
   RETURN Version
   
/**
 * Retorna .T. se o usuario estiver usando o Google Chrome para efetuar a
 * requisiá∆o atual. Um exemplo do retorno de wxGetClientUserAgent() que demonstra
 * o Google Chrome rodando em Windows seria:
 * <code>
 * Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.2.149.30 Safari/525.13
 * </code>
 *
 * @see wxChromeVersion() wxGetClientUserAgent()
 * 05/10/2008 - 16:39:42
 */
FUNCTION wxIsChrome()
   RETURN ' CHROME' $ ' ' + Upper( wxGetClientUserAgent() )
/**
 * Retorna uma string com o n£mero da vers∆o do Google Chrome em uso pelo cliente
 * que efetuou a requisiá∆o atual. Caso o cliente n∆o esteja utilizando o Chrome
 * ser† retornado uma string vazia.
 *
 * @see wxIsChrome() wxGetClientUserAgent()
 * 05/10/2008 - 16:40:40
 */
FUNCTION wxChromeVersion()
   LOCAL Version := ' ' + Upper( wxGetClientUserAgent() ) + ' '
   LOCAL Pos     := At( ' CHROME', Version ) 
   
   IF Pos <> 00
      Version := Subst( Version, Pos + 8)
      Version := LTrim( Version )
      
      Pos     := At( ' ', Version )
      
      IF Pos <> 00 THEN; 
         Version := Subst( Version, 1, Pos -1 )
   ELSE
      Version := ''
              
   End   
   RETURN Version
   
/**
 * Retorna .T. se o usuario estiver usando o Apple Safari para efetuar a
 * requisiá∆o atual. Um exemplo do retorno de wxGetClientUserAgent() que demonstra
 * o Safari rodando em Windows seria algo como:
 * <code>
 *  Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Safari/525.13
 * </code>
 *
 * @see wxSafariVersion() wxGetClientUserAgent()
 * 05/10/2008 - 17:00:46
 */
FUNCTION wxIsSafari()
   RETURN ' SAFARI' $ ' ' + Upper( wxGetClientUserAgent() )
/**
 * Retorna uma string com o n£mero da vers∆o do Apple Safari em uso pelo cliente
 * que efetuou a requisiá∆o atual. Caso o cliente n∆o esteja utilizando o Safari
 * ser† retornado uma string vazia.
 *
 * @see wxIsSafari() wxGetClientUserAgent()
 * 05/10/2008 - 16:40:40
 */
FUNCTION wxSafariVersion()
   LOCAL Version := ' ' + Upper( wxGetClientUserAgent() ) + ' '
   LOCAL Pos     := At( ' SAFARI', Version ) 
   
   IF Pos <> 00
      Version := Subst( Version, Pos + 8)
      Version := LTrim( Version )
      
      Pos     := At( ' ', Version )
      
      IF Pos <> 00 THEN; 
         Version := Subst( Version, 1, Pos -1 )
   ELSE
      Version := ''
              
   End   
   RETURN Version
  
/*
 * Retorna .T. se o usuario estiver usando o Netscape para efetuar a
 * requisiá∆o atual.
 *
 * @see wxNetscapeVersion() wxGetClientUserAgent()
 * 09/06/2007 - 22:16:52
 */
FUNCTION wxIsNetscape()
   RETURN 'NETSCAPE' $ Upper( wxGetClientUserAgent() )
/*
 * Retorna uma string com o n£mero da vers∆o do Netscape em uso pelo cliente
 * que efetuou a requisiá∆o atual. Caso o cliente n∆o esteja utilizando o Netscape
 * ser† retornado uma string vazia.
 *
 * @see wxIsNetscape() wxGetClientUserAgent()
 * 9/6/2007 @ 15:25:10
 */
FUNCTION wxNetscapeVersion()
   LOCAL Version := ' ' + Upper( wxGetClientUserAgent() ) + ' '
   LOCAL Pos     := At( 'NETSCAPE', Version ) 
   
   IF Pos <> 00
      Version := Subst( Version, Pos + 9)
      Version := StrTran( Version,'/','' )
      Version := LTrim( Version )
      Pos     := At( ' ', Version )
      
      IF Pos <> 00 THEN; 
         Version := Subst( Version, 1, Pos -1 )
   ELSE
      Version := ''
              
   End   
   RETURN Version
/**
 * Retorna .T. se o cliente estiver usando um dispositivo movel com PalmOS para
 * efetuar a requisiá∆o atual.
 *
 * @see wxDeviceType() wxIsSmartPhone() wxIsPocketPC() wxIsPalmOS() wxPalmOSVersion()
 * 19/06/2007 - 21:26:57
 *
 * @ignore
 * Mozilla/1.22 (compatible; MSIE 5.01; PalmOS 3.0) EudoraWeb 2.1
 * http://www.zytrax.com/tech/web/mobile_ids.html
 */
FUNCTION wxIsPalmOS() 
   RETURN 'PALMOS' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna uma string com o n£mero da vers∆o do PalmOS instalada no cliente
 * que efetuou a requisiá∆o atual. Caso o cliente n∆o esteja utilizando o PalmOS
 * ser† retornado uma string vazia.
 *
 * @see wxDeviceType() wxIsSmartPhone() wxIsPocketPC() wxIsPalmOS() wxPalmOSVersion()
 * 19/06/2007 - 21:29:10
 */
FUNCTION wxPalmOSVersion()
   LOCAL Version := ' ' + Upper( wxGetClientUserAgent() ) + ' '
   LOCAL Pos     := At( 'PALMOS', Version ) 
   
   IF Pos <> 00
      Version := Subst( Version, Pos + 6)
      Version := StrTran( Version,'/','' )
      Version := LTrim( Version )
      Pos     := At( ' ', Version )
      
      IF Pos <> 00 THEN; 
         Version := Subst( Version, 1, Pos -1 )
   ELSE
      Version := ''
              
   End   
   RETURN Version
/**
 * Funá∆o generica que retorna o nome do browser instalado no cliente. Se o parametro
 * opcional <lLongName> for especificado o nome do browser conter† uma informaá∆o
 * adicional sobre a empresa desenvolvedora do mesmo, caso seja possivel determinar
 * esta informaá∆o.
 *
 * @see wxBrowserVersion()
 * 9/6/2007 @ 18:48:09
 */
FUNCTION wxBrowserName( lLongName )
   LOCAL Name := '(Unknown)'
   LOCAL Info := ' ' + Upper( wxGetClientUserAgent() ) + ' ' 
   
   DEFAULT lLongName TO .F.
   
   IF 'FIREFOX' $ Info
      Name := IIF( lLongName, 'Mozilla FireFox', 'FIREFOX' )
      
   ELSEIF 'CHROME' $ Info
      Name := IIF( lLongName, 'Google Chrome', 'CHROME' )
         
   ELSEIF ' SAFARI' $ Info
      Name := IIF( lLongName, 'Apple Safari', 'SAFARI' )
         
   ELSEIF 'OPERA'    $ Info
      Name := 'OPERA'
   
   ELSEIF 'NETSCAPE' $ Info
      Name := 'NETSCAPE'
      
   ELSEIF 'GALEON' $ Info
      Name := 'GALEON'
      
   ELSEIF 'GECKO'  $ Info
      Name := 'MOZILLA'
      
   ELSEIF 'MYIE'   $ Info
      Name := 'MYIE'
      
   ELSEIF 'LYNX'   $ Info
      Name := 'LYNX'
      
   ELSEIF ' MSIE ' $ Info
      Name := IIF( lLongName, 'Microsoft Internet Explorer', 'MSIE' )

   ELSEIF 'MOZILLA/4.75' $ Info .or. ;
          'MOZILLA/4.08' $ Info .or. ;
          'MOZILLA/4.5'  $ Info .or. ;
          'MOZILLA/4.6'  $ Info .or. ;
          'MOZILLA/4.79' $ Info
      Name := 'NETSCAPE'
      
   ELSEIF 'KONQUEROR' $ Info
      Name := 'KONQUEROR'
      
   ELSEIF 'NUHK'         $ Info .or. ;
          'GOOGLEBOT'    $ Info .or. ;
          'YAMMYBOT'     $ Info .or. ;
          'OPENBOT'      $ Info .or. ;
          'SLURP/CAT'    $ Info .or. ;
          'MSNBOT'       $ Info .or. ;
          'IA_ARCH IVER' $ Info
      Name := 'SEARCHBOT'
      
   End     
   RETURN Name
/**
 * Retorna a versao atual do navegador em uso pelo cliente que efetuou a requisiá∆o
 * atual. Caso n∆o seja poss°vel determinar a vers∆o do user agent em uso esta
 * funá∆o retorna uma string contendo o termo "(Unknown)".
 * @see wxBrowserName()
 * 9/6/2007 @ 22:04:05
 */   
FUNCTION wxBrowserVersion()
   LOCAL Ver  := '(Unknown)'
   LOCAL Info := ' ' + Upper( wxGetClientUserAgent() ) + ' ' 
   
   IF ' CHROME' $ Info
      Ver := wxChromeVersion()
         
   ELSEIF ' SAFARI' $ Info         // tem que vir ANTES di Google Chrome
      Ver := wxSafariVersion()
          
   ELSEIF ' FIREFOX' $ Info
      Ver := wxFireFoxVersion()
      
   ELSEIF ' OPERA'    $ Info
      Ver := wxOperaVersion()
   
   ELSEIF 'NETSCAPE' $ Info
      Ver := wxNetscapeVersion()

   ELSEIF ' MSIE ' $ Info
      Ver := wxIEversion()
         
   End     
   RETURN Ver   
/**
 * Esta funá∆o tenta determinar o nome do sistema operacional que o usu†rio e/ou
 * o user agent que solicitou a requisiá∆o atual est† utilizando.
 * @see @request(OS_FUNC_LIST)
 * 22/06/2007 - 12:14:00
 */   
FUNCTION wxOSVersion()
   LOCAL Ver
   
   DO CASE
   CASE wxIsWin7();     ; Ver := 'Windows 7'
   CASE wxIsWinVista()  ; Ver := 'Windows VISTA'
   CASE wxIsWinXPSP2()  ; Ver := 'Windows XP (SP2)'
   CASE wxIsWinXP()     ; Ver := 'Windows XP'
   CASE wxIsWinSE()     ; Ver := 'Windows Server 2003'
   CASE wxIsWinME()     ; Ver := 'Windows Millennium Edition'
   CASE wxIsWin98()     ; Ver := 'Windows 98'
   CASE wxIsWin95()     ; Ver := 'Windows 95'
   CASE wxIsWin31()     ; Ver := 'Windows 3.1'
   CASE wxIsUnix()      ; Ver := 'Linux/Unix'
   CASE wxIsPalmOS()    ; Ver := 'Palm OS'
   CASE wxIsMAC()       ; Ver := 'Macintosh'
   OTHERWISE
      Ver  := '(Unknown)'
   End     
   RETURN Ver   
/**
 * Retorna o tipo de dispositivo m¢vel utilizado pelo cliente para navegaá∆o. Caso
 * n∆o seja possivel detectar esta informaá∆o uma string vazia ser† retornada.
 *
  * @see wxDeviceType() wxIsSmartPhone() wxIsPocketPC() wxIsPalmOS() wxPalmOSVersion()
* 22/06/2007 - 12:19:50
 */   
FUNCTION wxDeviceType()
   LOCAL Ver  := ''
   
   DO CASE
   CASE wxIsSmartPhone()   ; Ver := 'SmartPhone'
   CASE wxIsPocketPC()     ; Ver := 'Pocket PC'
   CASE wxIsPalmOS()       ; Ver := 'Palm'
   End     
   RETURN Ver   
   
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows.
 * @see @request(OS_FUNC_LIST)
 * 09/06/2007 - 22:44:37
 */
FUNCTION wxIsWin32()
   RETURN 'WIN' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Linux.
 * @see @request(OS_FUNC_LIST)
 * 09/06/2007 - 22:48:43
 */
FUNCTION wxIsLinux()
   RETURN 'LINUX' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Macintosh.
 * @see @request(OS_FUNC_LIST)
 * 09/06/2007 - 22:48:54
 */
FUNCTION wxIsMAC()
   RETURN 'MAC' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Linux ou Unix.
 * @see @request(OS_FUNC_LIST)
 * 09/06/2007 - 22:44:37
 */
FUNCTION wxIsUnix()                                 
   LOCAL UserAgent := Upper( wxGetClientUserAgent() )
   
   RETURN 'LINUX' $ UserAgent  .or. ;
          'UNIX'  $ UserAgent
/**
 * Retorna .T. se o usuario estiver rodando o Microsoft Internet Explorer em um
 * Pocket PC.
 * @see wxDeviceType() wxIsSmartPhone() wxIsPocketPC() wxIsPalmOS() wxPalmOSVersion()
 * 19/06/2007 - 20:54:11
 */
FUNCTION wxIsPocketPC()                                 
   LOCAL UserAgent := Upper( wxGetClientUserAgent() ) + ' '
   
   RETURN (' CE '  $ UserAgent) .OR. ;
          (' PPC'  $ UserAgent) .OR. ;
          ('WINCE' $ UserAgent)
   
/**
 * Retorna .T. se o usuario estiver rodando um navegador via SmartPhone.
 * @see wxDeviceType() wxIsSmartPhone() wxIsPocketPC() wxIsPalmOS() wxPalmOSVersion()
 * 19/06/2007 - 21:05:52
 */   
FUNCTION wxIsSmartPhone() 
   RETURN 'SMARTPHONE' $ Upper( wxGetClientUserAgent() )

/**
 * Tenta detectar o tamanho da tela do dispositivo m¢vel utilizado pelo cliente
 * para acessar este script. Se a informacao estiver dispon°vel retorna um
 * array informando o tamanho da LARGURA e ALTURA da tela em Pixels, caso contr†rio
 * retorna um array vazio.
 * 19/06/2007 - 21:10:26
 *
 * @ignore
 * Mozilla/2.0 (compatible; MSIE 3.02; Windows CE; PPC; 240x320)
 * Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320)
 * Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; Smartphone; 176x220)
 * Mozilla/4.76 (compatible; MSIE 6.0; U; Windows 95; PalmSource; PalmOS; WebPro; Tungsten Proxyless 1.1 320x320x16)
 * 
 * http://blogs.msdn.com/iemobile/archive/2006/08/03/Detecting_IE_Mobile.aspx
 */   
FUNCTION wxGetDeviceRes()                                 
   STATIC Result
   
   LOCAL UserAgent := Upper( wxGetClientUserAgent() )
   LOCAL a,b,c,d,e
   
 * N∆o Ç um dispositivo m¢vel?  
   IF !((' CE'    $ UserAgent) .OR.;
        ('WINCE'  $ UserAgent) .OR.;
        ('PALMOS' $ UserAgent);
       )  
      * ê um PocketPC ou um SmartPhone!
      RETURN {}
      
 * N¢s j† processamos isto antes? Entao mandamos o resultado direto pra ele!
   ELSEIF (Result <> NIL )
      RETURN Result
   
   End
 
 * Trocamos os ";" por espaáos na string  
   b := StrTran( UserAgent, ';', ' ' )

 * Quebramos a string em um ARRAY separando por espaáos  
   a := wxListAsArray( b, " " )
   d := Len( a )
   
   Result := {}     
   
 * Procuramos um item iniciado com um valor numerico e que tenha a o byte 'X'
 * em seu conteudo!
   FOR c := 1 TO d
       b := a[c]
       
     * ê uma string vazia? (Como pode!?)  
       IF Empty(b) THEN;
          Loop
                              
     * Este item que estamos chegando... comeáa com um numero?
       IF !IsDigit( b[1] ) THEN;
          Loop
     * Ok, comeáa com um numero. Ele tem um "X" dentro desta string?
       IF ( (e := At( "X", b )) == 00 ) THEN;
          Loop
     
     * Este "X" dentro da string... Ç o ultimo byte da string?
       IF (e == Len(b)) THEN;
          LOOP
          
     * Depois do "X" h† um outro valor numerico?
       IF !IsDigit( b[e+1] ) THEN;
          Loop
          
     * Ok! Este Ç definitivamente o nosso garoto!
       a := wxListAsArray( b + 'XX', 'X', 2 )
       
     * Convertemos os valores para numeros  
       AAdd( Result, VAL( a[1] ))
       AAdd( Result, VAL( a[2] ))
       
     * E quebramos o laáo FOR (usei assim pq o -w3 -es2 reclamou do EXIT que havia
     * na linha debaixo
       c := d + 1
   End      
   RETURN Result
/**
 * Retorna .T. se for possivel detectar se o usuario est† rodando o navegador em
 * uma CPU de 64bits - Intel ou AMD! 
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxHave64Proc()
   LOCAL UserInfo := Upper( wxGetClientUserAgent() )
   
   RETURN ( ' WIN64' $ UserInfo ) .OR. ;
          ( ' WOW64' $ UserInfo ) .OR. ;
          ( ' AMD64' $ UserInfo )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows 7.
 * @see @request(OS_FUNC_LIST)
 * 24/11/2009 - 12:18:53
 */
FUNCTION wxIsWin7()
   RETURN 'NT 6.1' $ Upper( wxGetClientUserAgent() )

/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows Vista.
 * @see @request(OS_FUNC_LIST)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinVista()
   RETURN 'NT 6.0' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows Server 2003.
 * @see @request(OS_FUNC_LIST)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinSE()
   RETURN 'NT 5.2' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows XP.
 * @see @request(OS_FUNC_LIST)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinXP()
   RETURN 'NT 5.1' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows XP 
 * com SP2 e/ou Windows Server 2003.
 * @see @request(OS_FUNC_LIST)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinXPSP2()
   RETURN ' SV1;' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows 98.
 * @see @request(OS_FUNC_LIST)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWin98()
   RETURN 'WINDOWS 98' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows 95.
 * @see @request(OS_FUNC_LIST)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWin95()
   RETURN 'WINDOWS 95' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em Windows Millennium
 * Edition (Windows Me).
 * @see @request(OS_FUNC_LIST)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinME()
   RETURN 'WIN 9X 4.90' $ Upper( wxGetClientUserAgent() )
/**
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows 3.1.
 * @see @request(OS_FUNC_LIST)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWin31()
   RETURN 'WINDOWS 3.1' $ Upper( wxGetClientUserAgent() )
