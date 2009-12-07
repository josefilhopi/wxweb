/*---------------------------------------------------------------------------
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 7/12/2006 10:11:31
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxCookies.prg
 *                            
 *  Funções para manipulação de Cookies
 *
 *---------------------------------------------------------------------------*/
#define XBASE_CC

#include "simpleio.ch"
#include "common.ch"
#include "wxWebFramework.ch"

/*
 * Devemos computar esta data com a data to servidor para podermos
 * computar o valor correto do GTM pois isto influencia tb a vida do COOKIE!
 */
#define GTM_INTERVAL ( UCT2DSTDIFF() )

/** 
 * SetCookie( <cName>, [<cValue>], [<nSecsToExpires>],[<cServerPath>], [<cDomainName>],
 *            [<bSecure>], [<bHttpOnly>] ) -> lOk
 *  
 * Cria, atualiza ou apaga um cookie do navegador do usuário. Esta função envia 
 * os dados sobre o cookie selecinoado juntamente com o resto dos cabeçalhos    
 * HTTP. Assim como os outros cabeçalhos (headers), os cookies devem ser enviados   
 * antes de qualquer saída que seu programa produza (isto se deve à uma restrição   
 * do protocolo HTTP).
 *
 * O que quer dizer que você deve colocar chamadas a essa função antes de qualquer 
 * comando ou função que gere saída, incluindo os espaços e linhas em branco.
 *
 * Uma vez que o cookie foi criado, a wxWeb disponibiliza funções para que você 
 * possa acessar, consultar e até enumerar os cookies disponíveis no navegador do
 * usuário.
 *
 * 22/11/2006 11:48:17
 *
 * @<cName>             O nome do cookie que será manipulado.
 *
 * @<cValue>            O valor do cookie. Esse valor é guardado no computador do
 *                      cliente e não é recomendado guardar nenhum informação confidencial
 *                      através deste tipo de recurso. Utilize a função wxGetCookie() para
 *                      obter o valor previamente armazenado em um Cookie. Se este argumento
 *                      for omitido o Cookie será excluido da CPU do usuário.
 *
 * @<nSecsToExpires>    O tempo em segundos para o cookie expirar.
 *
 * @<cServerPath>       O PATH no servidor aonde o cookie estará disponível. Se configurado
 *                      para '/', o cookie estará dosponível para todo o domínio. Se
 *                      configurado para o diretório '/test/', o cookie estará disponível
 *                      apenas dentro do diretório /test/ e todos os subdiretórios como
 *                      /test/dbf do domínio.
 *
 * @<cDomainName>       O domínio para qual o domínio estará disponível. Para fazer com que
 *                      ele esteja disponível para todos os subdomínios de examplo.com então
 *                      você deve configurar ele para '.exemplo.com'.
 *
 * @<bSecure>           Indica que o cookie só podera ser transimitido sob uma conexão segura
 *                      HTTPS do cliente. Quando configurado para .T. o cookie será enviado
 *                      somente se uma conexão segura existir. O padrão é .F.
 *
 * @<bHttpOnly>         Quando for especificado como .T. o cookie será acessível somente sob
 *                      o protocolo HTTP. Isso é importante pois significa que o cookie não
 *                      será acessível por linguagens de script, como JavaScript entre outros.
 *
 * @see WXGETCOOKIE() WXGETCOOKIENAME() WXGETCOOKIECOUNT() WXCOOKIEEXISTS() SetCookie() DeleteCookie()
 *
 * <sample>
 * @include( '..\..\samples\cookies_basic\demo.prg' )
 * </sample>
 * 
 * @ignore
 * Maiores info em:
 *    http://wp.netscape.com/newsref/std/cookie_spec.html
 *    http://www.faqs.org/rfcs/rfc2965
 *    http://www.ietf.org/rfc/rfc2965.txt
 *
 * To Obtain cookies:
 *    http://www.ics.uci.edu/pub/ietf/http/rfc2109.txt
 */   
FUNCTION SetCookie( cName, cValue, nSecsToExpires, cServerPath, cDomainName, bSecure, bHttpOnly )
   LOCAL Str, cExpires
   LOCAL cTime, dDate  

      DEFAULT nSecsToExpires     TO 0
      DEFAULT cServerPath        TO ''
      DEFAULT cDomainName        TO ''
      DEFAULT bSecure            TO False
      DEFAULT bHttpOnly          TO False
      
      IF nSecsToExpires <> 0         
/*         IF ( GTM_INTERVAL < 0 )
            x := 3600 * ( GTM_INTERVAL * -1 )
         End
         
         cTime := AddSecondsToTime( Time(), x, @d )
         dDate := Date() + d*/
         
         cTime := UTCTime()
         dDate := UTCDate()
         cExpires := DateToGMT( dDate, cTime, 00, nSecsToExpires )
      ELSE
         cExpires := ''
      End

      /*
       * Convertemos isto para string se já ñ o for
       */
      IF ValType( cValue ) == 'C'
         cValue :=  wxUrlEncode( cValue )
       * Del    := False
         
      ELSEIF ( cValue == NIL )         
       * É para deletar o cookie!!
         cValue := ""
       * Del    := True
         nSecsToExpires := -02101914

      ELSE
         cValue :=  wxUrlEncode( /* wxEnsureString */( cValue ) )
       * Del    := False
         
      End
      
      /*
       * Checa se o nome do cookie passado é valido
       */
      IF !__ISVALIDCOOKIENAME( cName ) THEN;
         RETURN .F.
      
      /*
       * Checa se o valor a ser enviado para o cookie é valido
       */
      IF !__ISVALIDCOOKIEVALUE( cValue ) THEN;
         RETURN .F.
         
      Str := 'Set-Cookie: ' + cName + '=' + cValue
    
      IF !Empty(cDomainName ) THEN;
         Str += "; domain=" + cDomainName

      IF !Empty(cServerPath ) THEN;
         Str += "; path=" + cServerPath

      IF !Empty(cExpires ) THEN;
         Str += "; expires=" + cExpires

//      IF !Empty(cServerPath ) THEN;
//         Str += "; path=" + cServerPath

      IF bSecure THEN;
          Str += "; secure"

      IF bHttpOnly THEN;
          Str += "; httponly"
    
      /*
       * Enviamos o Header para a aplicação
       */
      WXSENDHEADER( Str )
   RETURN .T.
   
/**
 * DeleteCookie( <cName> ) -> lOk
 *
 * Deleta um cookie armazenado no navegador do usuário e retorna .T. indicando o
 * sucesso no envio do comando.
 * 7/12/2006 15:17:22
 */
FUNCTION DeleteCookie( cName )
      RETURN SetCookie( cName, NIL )
