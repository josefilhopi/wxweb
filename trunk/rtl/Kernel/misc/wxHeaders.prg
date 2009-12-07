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
 *  Arquivo..: wxHeaders.prg
 *                            
 *  Funções para manipulação de cabeçalhos da pagina
 *
 *---------------------------------------------------------------------------*/

/*
 * Envia um arquivo para o buffer de saida!
 * 25/12/2006 20:57:23
 */
FUNCTION SendFile( cFileName )  
   IF File( cFileName )       
      RETURN wxWebOutPutText( MemoRead( cFileName ) )
   End
   RETURN .F.    

/*
 * Envia uma string para um Buffer de saida
 * 25/12/2006 20:58:39
 */   
FUNCTION SendBuffer( cBuffer )   
   IF VALTYPE( cBuffer ) == 'C'      
      RETURN wxWebOutPutText( cBuffer )
   End   
   RETURN .F.     

/*
 * Envia um HEADER() para um redirecionamento.
 * 22/11/2006 15:27:16
 *
 *
 * ex: 
 *       Redirect( 'www.google.com.br' )
 *
 *       Redirect( 'pagina2', 'nome=Renato' )
 *
 *       Redirect( 'pagina2', {'nome=Renato','Idade=27','Sexo=.t.'} )
 *
 *       Redirect( 'pagina2', {{'nome','Renato'},{'Idade',27},{'Sexo', .t.}} )
 */   
FUNCTION Redirect( cUrl, aArgs )
   LOCAL i,j
   
   IF Valtype( cUrl ) != 'C' 
      RETURN .F.
   End
   
   cUrl := "Location: " + cUrl
   
   /*
    * Pode-se agora passar um array com os parametros a serem enviados via 
    * QueryString na URL que será enviada. Sendo q pode ser um ARRAY ou STRING
    * já formatada. =D
    * 28/12/2006 08:35:38
    */
   IF ValType( aArgs ) == "C"
      cUrl += '?' + aArgs
   
   ELSEIF ValType( aArgs ) == "A" .and. ((j := Len( aArgs ))>0)
   
      cUrl += '?'  
   
      FOR i := 1 TO j
         
          IF ( i > 1 )
             cUrl += "&"
          End
            
          IF ValType( aArgs[i] ) == "A"
             cUrl += aArgs[i,1] + '=' + URLENCODE( wxEnsureString( aArgs[i,2], .T. ) )
          ELSE
             cUrl += aArgs[i]
          End
      End
   End      
   
   RETURN wxWebOutPutHeader( cUrl )
   
/*
 * Envia um HEADER() de baixo nivel
 * 22/11/2006 11:48:17
 */   
FUNCTION SendHeader( cHeader )      
   RETURN wxWebOutPutHeader( cHeader )   
   
/*
 * Envia um HEADER() com base na página atual
 * 27/12/2006 21:46:44
 */   
FUNCTION GotoPage( cPageName, aArgs )
   LOCAL cUrl := wxGetEnv('SCRIPT_NAME')
   
   IF Empty( cPageName )
      *
   ELSE
      cUrl += '/' + cPageName + '/'
   End
   
   RETURN Redirect( cUrl, aArgs )   
