/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 07/06/2007 - 11:29:35
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxClientInfo.prg
 *                            
 *  Funcoes diversas para informaá‰es do lado do cliente
 *
 *---------------------------------------------------------------------------*/
#include "simpleio.ch"
#include "common.ch"
#include "wxWebFramework.ch"

/**
 * wxClientIP( <lLoopBack> ) -> cIP
 * Retorna o numero IP da estaá∆o atualmente conectada neste servidor ou
 * uma string vazia caso nenhum IP tenha sido detectado.
 * 07/06/2007 - 11:03:51
 *
 * @<lLoopBack>   Caso n∆o seja possivel determinar o IP atual da conex∆o atual,
 *                e este argumento seja setado como .F. esta funá∆o retornar† uma
 *                string vazia. Se <lLoopBack> for omitido ser† assumido o valor
 *                .T. que far† com que o endereáo IP padr∆o da interface LoopBack
 *                sej† retornado.
 *
 * <sample>
 * #include "wxweb.ch"
 *
 * FUNCTION Main()
 *
 *    ? "Your IP address is:", wxClientIP()
 *
 *    RETURN nil
 * </sample>
 *
 * <sample>
 * #include "wxweb.ch"
 *
 * FUNCTION Main()
 *
 *    IF Left( wxClientIP(), 8 ) <> '192.168.'
 *       ? 'Access denied!'
 *       QUIT
 *    End
 *
 *    ? 'Hi! Your are welcome...'
 *    RETURN nil
 * </sample>
 */
FUNCTION wxClientIP( lLoopBack )
   local variables := { ;
                          'HTTP_X_FORWARDED_FOR',;
                          'HTTP_X_FORWARDED',;
                          'HTTP_FORWARDED_FOR',;
                          'HTTP_FORWARDED',;
                          'HTTP_X_COMING_FROM',;
                          'HTTP_COMING_FROM',;
                          'HTTP_CLIENT_IP',;
                          'REMOTE_ADDR',;
                       }
   LOCAL Value
   LOCAL i

   DEFAULT lLoopBack TO True
   
   FOR i := 1 TO Len( variables )
       Value := wxGetEnv( variables[i] )
       
       IF !Empty( Value ) THEN;
          RETURN Value
   End
      
   IF !lLoopBack Then;
      RETURN ''
      
   RETURN "127.0.0.1"
      