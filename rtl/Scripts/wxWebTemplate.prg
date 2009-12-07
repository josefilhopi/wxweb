/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 23/07/2008 - 14:40:00
 *
 *  Original.: 08/04/2008 - 22:42:39
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxWebScript.prg
 *                            
 *  Funções para leitura e execução de Scripts no lado servidor gerados com o
 *  wxCompiler.exe
 *
 *---------------------------------------------------------------------------*/
// 
#include "wxWeb.ch"
#include "hbclass.ch"

#define TEMPLATE_NONE      0
#define TEMPLATE_HTML      1
#define TEMPLATE_SCRIPT    2
#define TEMPLATE_PARAMS    3

#define CR  CHR(13)
#define LF  CHR(10)

REQUEST __MVPUT

CLASS TWebTemplate

 * Carrega o template armazenado em um arquivo
   METHOD LoadFromFile( cFileName )

 * Carrega o template armazenado em um arquivo um campo ou variavel de memoria
   METHOD LoadFrom( cBuffer )

 * Descarrega o template da memoria e libera recursos atualmente em uso.
   METHOD Unload()                  INLINE ::aContent := {}

 * Acesso aos parametros desta p gina
   METHOD Params( field, value )

 * Gera um HTML com base nos parametros ativos
   METHOD Renderize()
   
 * Pega a ultima msg de erro do processo
   METHOD Error()                   INLINE ::cError
   
   HIDDEN:
    * Conteudo a ser processado para o site!
      DATA aContent                 INIT {}
      DATA aParams                  INIT {}
      
    * Indica se h  necessidade de descarregarmos o template de memoria
      DATA lLoaded                  INIT False
    * Indica erro em algum processo
      DATA cError                   INIT ''
END CLASS

/*
 * Carrega um template armazenado em um arquivo para a memoria. Retorna um valor
 * num‚rico indicando se o processo foi bem sucedido ou nÆo.
 * 10/04/2008 - 15:10:50
 *
 * Possiveis valores de retorno sÆo:
 *   -1 - Erro: arquivo nao encontrado.
 *    0 - Ok, template carregado com sucesso!
 *   >0 - LoadFrom() erro! Consulte a fun‡Æo para averiguar a causa
 */
METHOD LoadFromFile( cFileName ) ;
   CLASS TWebTemplate

   IF !File( cFileName ) THEN;
      RETURN 1

   RETURN ::LoadFrom( MemoRead(cFileName) )

/*
 * Adiciona ou consulta o valor de um parametro encontrado nesta p gina.
 * 11/04/2008 - 15:52:57
 */
METHOD Params( field, value ) ;
   CLASS TWebTemplate
   
   LOCAL nPos, xVal, cKey
   LOCAL nPCount := PCount()

    * Nao passou o nome pelo menos pra consultar? Sai fora...
      IF ( VALTYPE( Field ) != 'C' ) THEN;
         RETURN nil
         
    * Puxamos a posi‡ao dele no array
      cKey := ALLTRIM(UPPER( field ))
      nPos := aScan( ::aParams, {|a| a[1] == cKey })
      xVal := iif( nPos == 00, NIL, ::aParams[ nPos, 2 ] )

    * Ele quer apenas consultar?
      IF (nPCount < 2) THEN;
         RETURN xVal

    *  para setar o valor? Se for NIL excluimos ele da listagem!!!
      IF (( nPos == 00 ))
         AADD( ::aParams, { cKey, Value } )
      ELSE
         ::aParams[ nPos, 2 ] := Value
      End
      
 * Retornamos o valor origalmente intocado deste parametro
   RETURN xVal
   
/*
 * Carrega o template armazenado em um arquivo um campo ou variavel de memoria.
 * Esta fun‡Æo retorna um valor num‚rico indicando se o processo foi bem sucedido
 * ou nÆo.
 * 10/04/2008 - 15:16:32
 *
 * Possiveis valores de retorno sÆo:
 *    0 - Ok, template carregado com sucesso!
 */
METHOD LoadFrom( cBuffer ) ;
   CLASS TWebTemplate

   LOCAL i,L
   LOCAL c,n,t
   
   LOCAL bAdd
   LOCAL inParams := False
   LOCAL nLine    := 1

   L := Len( cBuffer )
   i := 0
   t := ''

   bAdd := {|| B1C3E6BB0H( @T, inParams, Self, ::aContent ) }
   ::aContent := {}
   
   DO WHILE (.T.)
      i++
      
      IF ( i > L ) THEN;
         EXIT
      
      c := Substr(cBuffer,i,1)
      n := iif(i == L, '', Substr(cBuffer,i+1,1))

      IF (c == LF)
         nLine ++
         IF inParams
            ::cError := 'Quebra de linha inesperada na linha '+alltrim( str(nLine) )
            EXIT
         End
      End
         
      IF ((c == '{') .AND. (n == '%'))
         IF inParams
            ::cError := 'Caracter inesperado na linha '+alltrim( str(nLine) )+': {'
            EXIT
         End
         
         bAdd:Eval()
         inParams := True
         
         i++
         LOOP
      End
      
      IF ((c == '%') .AND. (n == '}') .AND. inParams)
         T := ALLTRIM( UPPER( T ))
         bAdd:Eval()
         inParams := False
         I++
         LOOP
      End
      t += c
   End

   bAdd:Eval()
   
   IF inParams THEN;
      ::cError := 'Fim do arquivo inesperado na linha '+alltrim( str(nLine) )+': Parametros em aberto'
   
   IF Empty( ::cError ) THEN;
      RETURN 00
      
   RETURN 00

METHOD Renderize() ;
   CLASS TWebTemplate
   
   LOCAL i,j,a,v,p

   a := ::aContent
   j := LEN( a )

   FOR i := 1 TO j

       IF a[i,1] == TEMPLATE_PARAMS
          p := aScan( ::aParams, {|_1| _1[1] == a[i,2] })

          IF p == 00 THEN;
             LOOP
             
          v := ::aParams[p,2]
          
          IF ( VALTYPE(v) != 'U' )
             wxQQout( v )
          End
             
       ELSE
          wxQQout( a[i,2] )
       End
   End
   RETURN Self

STATIC;
FUNCTION B1C3E6BB0H( T, inParams, Self, aContent )
   IF Empty(T)
   ELSE
      IF inParams
         AADD( aContent, { TEMPLATE_PARAMS, T })
         ::Params( T, NIL )
      ELSE
         AADD( aContent, { TEMPLATE_HTML  , T })
      End
      T := ''
   End
   RETURN nil
   