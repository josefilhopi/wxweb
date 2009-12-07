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
 */
/*  
 * Retorna a string informando o tipo de navegador instalado no cliente  
 * 9/6/2007 - 15:23:33  
 */  
FUNCTION wxGetClientUserAgent()  
	RETURN wxGetEnv( 'HTTP_USER_AGENT' )
	
/*
 * Retorna .T. se o usuario estiver usando o IE na CPU dele. 
 * 9/6/2007 @ 15:25:10
 *
 * Possiveis valores para wxGetClientUserAgent() neste caso para
 * Internet Explorer (Windows):
 *  
 *  ie6 (on WinXP):
 *  Mozilla/4.0 (compatible; MSie 6.0; Windows NT 5.1)
 *  
 *  ie5.5 (on W2K):
 *  Mozilla/4.0 (compatible; MSie 5.5; Windows NT 5.0)
 *  
 *  ie5.01 (on Win98):
 *  Mozilla/4.0 (compatible; MSie 5.01; Windows 98)
 */
FUNCTION wxIsIE()
   RETURN ' MSIE ' in Upper( wxGetClientUserAgent() )
/*
 * Retorna uma string com o n£mero da vers∆o do IE usada no cliente! 
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

/*
 * Retorna .T. se o usuario estiver usando o FireFox na CPU dele.
 * 9/6/2007 @ 15:25:10
 *
 * Possiveis valores para wxGetClientUserAgent() neste caso para
 * o FireFox (windows e linux)
 *                                       
 *  Firefox 0.9.3 (on Linux):
 *  Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7) Gecko/20040803 firefox/0.9.3
 *
 *  Firefox 2.0.0.4 (on Windows):
 *  Mozilla/5.0 (Windows; U; Windows NT 5.1; pt-BR; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4
 */
FUNCTION wxIsFireFox()
   RETURN 'FIREFOX' in Upper( wxGetClientUserAgent() )
/*
 * Retorna uma string com o n£mero da vers∆o do FireFox usada no cliente! 
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
/*
 * Retorna .T. se o usuario estiver usando o FireFox na CPU dele.
 * 9/6/2007 @ 15:25:10
 *
 * Possiveis valores para wxGetClientUserAgent() neste caso para
 * o Opera (windows e linux)
 *
 *  Opera 7.54 (on WinXP):
 *  Mozilla/4.0 (compatible; MSie 6.0; Windows NT 5.1) Opera 7.54 [en]
 *  Opera/7.54 (Windows NT 5.1; U) [en]
 *  
 *  (first example is spoofed as ie6, second without spoofing)
 */
FUNCTION wxIsOpera()
   RETURN ' OPERA' in ' ' + Upper( wxGetClientUserAgent() )
/*
 * Retorna uma string com o n£mero da vers∆o do FireFox usada no cliente! 
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
/*
 * Retorna .T. se o usuario estiver usando o Netscape na CPU dele.
 * 09/06/2007 - 22:16:52
 */
FUNCTION wxIsNetscape()
   RETURN 'NETSCAPE' in Upper( wxGetClientUserAgent() )
/*
 * Retorna uma string com o n£mero da vers∆o do Netscape usada no cliente! 
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
/*
 * Retorna .T. se o cliente estiver usando um dispositivo movel com PalmOS 
 * 19/06/2007 - 21:26:57
 *
 * Mozilla/1.22 (compatible; MSIE 5.01; PalmOS 3.0) EudoraWeb 2.1
 * http://www.zytrax.com/tech/web/mobile_ids.html
 */
FUNCTION wxIsPalmOS() 
   RETURN 'PALMOS' in Upper( wxGetClientUserAgent() )
/*
 * Retorna uma string com o n£mero da vers∆o do PalmOS instalada no cliente! 
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
/*
 * Funá∆o generica que retorna o nome do browser instalado no cliente 
 * 9/6/2007 @ 18:48:09
 */
FUNCTION wxBrowserName()
   LOCAL Name := '(Unknown)'
   LOCAL Info := ' ' + Upper( wxGetClientUserAgent() ) + ' ' 
   
   IF 'FIREFOX' in Info
      Name := 'FIREFOX'
      
   ELSEIF 'OPERA'    in Info
      Name := 'OPERA'
   
   ELSEIF 'NETSCAPE' in Info
      Name := 'NETSCAPE'
      
   ELSEIF 'GALEON' in Info
      Name := 'GALEON'
      
   ELSEIF 'GECKO'  in Info
      Name := 'MOZILLA'
      
   ELSEIF 'MYIE'   in Info
      Name := 'MYIE'
      
   ELSEIF 'LYNX'   in Info
      Name := 'LYNX'
      
   ELSEIF ' MSIE ' in Info
      Name := 'MSIE'

   ELSEIF 'MOZILLA/4.75' in Info .or. ;
          'MOZILLA/4.08' in Info .or. ;
          'MOZILLA/4.5'  in Info .or. ;
          'MOZILLA/4.6'  in Info .or. ;
          'MOZILLA/4.79' in Info          
      Name := 'NETSCAPE'
      
   ELSEIF 'KONQUEROR' in Info
      Name := 'KONQUEROR'
      
   ELSEIF 'NUHK'         in Info .or. ; 
          'GOOGLEBOT'    in Info .or. ;
          'YAMMYBOT'     in Info .or. ;
          'OPENBOT'      in Info .or. ;
          'SLURP/CAT'    in Info .or. ;
          'MSNBOT'       in Info .or. ;
          'IA_ARCH IVER' in Info
      Name := 'SEARCHBOT'
      
   End     
   RETURN Name
/*
 * Retorna a versao atual do navegador
 * 9/6/2007 @ 22:04:05
 */   
FUNCTION wxBrowserVersion()
   LOCAL Ver  := '(Unknown)'
   LOCAL Info := ' ' + Upper( wxGetClientUserAgent() ) + ' ' 
   
   IF ' FIREFOX' in Info
      Ver := wxFireFoxVersion()
      
   ELSEIF ' OPERA'    in Info
      Ver := wxOperaVersion()
   
   ELSEIF 'NETSCAPE' in Info
      Ver := wxNetscapeVersion()

   ELSEIF ' MSIE ' in Info
      Ver := wxIEversion()
         
   End     
   RETURN Ver   
/*
 * Retorna o sistema operacional do usuario
 * 22/06/2007 - 12:14:00
 */   
FUNCTION wxOSVersion()
   LOCAL Ver  := ''
   
   DO CASE
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
/*
 * Retorna o tipo de dispositivo m¢vel utilizado pelo cliente para navegaá∆o.
 * (se for possivel detectar)
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
   
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows
 * 09/06/2007 - 22:44:37
 */
FUNCTION wxIsWin32()
   RETURN 'WIN' in Upper( wxGetClientUserAgent() )     
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Linux
 * 09/06/2007 - 22:48:43
 */
FUNCTION wxIsLinux()
   RETURN 'LINUX' in Upper( wxGetClientUserAgent() )        
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Macintosh
 * 09/06/2007 - 22:48:54
 */
FUNCTION wxIsMAC()
   RETURN 'MAC' in Upper( wxGetClientUserAgent() )
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Linux ou Unix
 * 09/06/2007 - 22:44:37
 */
FUNCTION wxIsUnix()                                 
   LOCAL UserAgent := Upper( wxGetClientUserAgent() )
   
   RETURN 'LINUX' in UserAgent  .or. ;
          'UNIX'  in UserAgent   
/*
 * Retorna .T. se o usuario estiver rodando o IE em um Pocket PC
 * 19/06/2007 - 20:54:11
 */
FUNCTION wxIsPocketPC()                                 
   LOCAL UserAgent := Upper( wxGetClientUserAgent() )
   
   RETURN (' CE'   in UserAgent) .OR. ;
          (' PPC'  in UserAgent) .OR. ;
          ('WINCE' in UserAgent)
   
/*
 * Retorna .T. se o usuario estiver rodando um navegador via SMARTPHONE
 * 19/06/2007 - 21:05:52
 */   
FUNCTION wxIsSmartPhone() 
   RETURN 'SMARTPHONE' in Upper( wxGetClientUserAgent() )

/*
 * Tenta detectar o tamanho da tela do dispositivo m¢vel utilizado pelo cliente
 * para acessar este script. Se a informacao estiver dispon°vel retorna um
 * array informando o tamanho da LARGURA e ALTURA da tela em Pixels, caso contr†rio
 * retorna um array vazio.
 * 19/06/2007 - 21:10:26
 *
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
   LOCAL a,b,c,d,e,f
   
 * N∆o Ç um dispositivo m¢vel?  
   IF !((' CE'    in UserAgent) .OR.;
        ('WINCE'  in UserAgent) .OR.;
        ('PALMOS' in UserAgent);
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
       
     * E quebramos o laáo FOR  
       EXIT
   End      
   RETURN Result
/*
 * Retorna .T. se for possivel detectar se o usuario est† rodando o navegador em
 * uma CPU de 64bits - Intel ou AMD! 
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxHave64Proc()
   LOCAL UserInfo := Upper( wxGetClientUserAgent() )
   
   RETURN ( ' WIN64' in UserInfo ) .OR. ;
          ( ' WOW64' in UserInfo ) .OR. ;
          ( ' AMD64' in UserInfo )              
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows Vista
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinVista()
   RETURN 'NT 6.0' in Upper( wxGetClientUserAgent() )     
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows Server 2003
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinSE()
   RETURN 'NT 5.2' in Upper( wxGetClientUserAgent() )     
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows XP
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinXP()
   RETURN 'NT 5.1' in Upper( wxGetClientUserAgent() )
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows XP 
 * com SP2 e/ou Windows Server 2003.
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinXPSP2()
   RETURN ' SV1;' in Upper( wxGetClientUserAgent() )        
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows 98
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWin98()
   RETURN 'WINDOWS 98' in Upper( wxGetClientUserAgent() )     
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows 95
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWin95()
   RETURN 'WINDOWS 95' in Upper( wxGetClientUserAgent() )     
/*
 * Retorna .T. se o usuario estiver rodando o navegador em Windows Millennium Edition (Windows Me)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWinME()
   RETURN 'WIN 9X 4.90' in Upper( wxGetClientUserAgent() )     
/*
 * Retorna .T. se o usuario estiver rodando o navegador em ambiente Windows 3.1
 * (Eu particularmente acho que nem existe CPUs deste porte acessando NET, + td bem)
 * 19/06/2007 - 22:15:54
 */
FUNCTION wxIsWin31()
   RETURN 'WINDOWS 3.1' in Upper( wxGetClientUserAgent() )     
