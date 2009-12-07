#define WXWEB_IGNORE_CMDS
#define WXWEB_DISABLE_AUTOLOAD
#include "wxweb.ch"
#include "..\rtl\include\wxWebFramework.ch"
#include "fileio.ch"
#include "directry.ch"

#define PATH_SEPARATOR  '\'
#define PATH_DEST       '.\html'
#define FN_PREFIX       'wx'

#define ARG_PREFIX      'arg'
#define PRG_PREFIX      'prg'

DYNAMIC topic
STATIC s_aDirsProcessed := {}
STATIC s_aMemvars

FUNCTION Main()
   LOCAL cPath := wxExePath()
   LOCAL aList := {}
   LOCAL Html  := ''
   LOCAL cFuncs := ''
   LOCAL tplDir:= cPath + 'template' + PATH_SEPARATOR
   LOCAL htmDir:= PATH_DEST + PATH_SEPARATOR
   LOCAL aFiles
   LOCAL hrb
   LOCAL i, t, f, n, p

   hrb := hb_hrbLoad( cPath + 'topic.hrb' )

 * Processa todos os fontes...
   ProcessDir( cPath + '..\rtl', aList )
   
 * Cria a pasta de destino
   MakeDir( PATH_DEST )

 * Joga os arquivos de template l† dentro
   t := Directory( tplDir + '*.*' )
   
   FOR EACH f IN t
       f := f[1]
       
     * Ignora os arquivos de template que n∆o devem ir para o destino!
       IF ( f $ ';topic.html;funclist.html;' )
          LOOP
       End
       
       COPY FILE ( tplDir + f ) TO ( htmDir + f )
   End
 * Sorteamos os nomes das funá‰es
   aList := aSort( aList ,,, {|x,y| B0E1H6DB2B(x,y) })

 * Geramos os arquivos .HTML finais com base nos templates instalados.
   FOR i := 1 TO Len( aList )
       t := aList[i]
       p := iif( i == 1, nil, aList[i-1] )
       n := iif( i == Len( aList ), nil, aList[i+1] )

       IF VALTYPE(t) != 'H'
          Loop
       End

       IF Empty( t['name'] ) .OR. ;
          HB_HPOS( t, 'url') == 00 .OR. Empty( t['url'] )
          Loop
       End

       cFuncs += GetUrlLink( t )

       WriteHtml( t, p, n, aList )
   End

   Html := hb_memoread( tplDir + 'funclist.html' )
   Html := StrTran( Html, '%funclist%', cFuncs )
   
   hb_memowrit( htmDir + 'funclist.html', Html )
   
   ? hb_cstr( aList )
   ?
   RETURN nil
   
// From hbextern sample
PROCEDURE ProcessDir( cDir, aOutput )
   LOCAL i, nLen, aFiles

   ?
   ? 'Folder', cDir

   IF PATH_SEPARATOR + 'obj' $ Lower(cDir)
      ?? ' - skipped'
      RETURN
   End

   // check for and prevent re-processing a folder
   IF AScan( s_aDirsProcessed, {|c| c == Lower( cDir ) } ) > 0
      RETURN
   ENDIF
   AAdd( s_aDirsProcessed, Lower( cDir ) )

   cDir += PATH_SEPARATOR
   aFiles := Directory( cDir + "*.*", "D" )
   
   IF ( nLen := LEN( aFiles ) ) > 0
      // Sort C files before PRG files before folders; this mimics HBExtern
      ASort( aFiles,,, {|x,y| ;
            IIf( x[ F_ATTR ] == "D", Chr(255), SubStr( x[ F_NAME ], 1 + HB_RAt( ".", x[ F_NAME ] ) ) ) + x[ F_NAME ] < IIf( y[ F_ATTR ] == "D", Chr(255), SubStr( y[ F_NAME ], 1 + HB_RAt( ".", y[ F_NAME ] ) ) ) + y[ F_NAME ] ;
         } )
      FOR i := 1 TO nLen
         IF aFiles[ i ][F_ATTR ] == "D"
            IF Lower( aFiles[ i ][ F_NAME ] ) $ '..'
               * Ignore!
            ELSE
               ProcessDir( cDir + aFiles[ i ][ F_NAME ], aOutput )
            ENDIF
         ELSEIF Upper( SubStr( aFiles[ i ][ F_NAME ], -4 ) ) == ".PRG"
            ProcessFile( cDir, aFiles[ i ][ F_NAME ], .T., aOutput )
         ELSEIF Upper( SubStr( aFiles[ i ][ F_NAME ], -2 ) ) == ".C"
            ProcessFile( cDir, aFiles[ i ][ F_NAME ], .F., aOutput )
         ENDIF
      NEXT
   ENDIF
   RETURN


FUNCTION ProcessFile( cPath, cFileName, lPrgFormat, aOutput )
   LOCAL cFileBody
   LOCAL aLines
   LOCAL cLine
   LOCAL nLine
   LOCAL Topic
   LOCAL Key
   LOCAL aWords
   LOCAL Token1, Token2
   LOCAL isCode
   LOCAL isPre
   LOCAL nCount
   LOCAL nTotLines
   LOCAL lIgnore
   LOCAL lSkip := .F.
   LOCAL i, t, p

   ? '*', cFileName, ''
   
   IF !Empty(FN_PREFIX) .AND. Left( Lower(cFileName), Len(FN_PREFIX) ) != FN_PREFIX
      lSkip := .T.
   End
   
   IF lSkip
      ?? ' - skipped'
      RETURN 0
   End

   cFileBody := hb_MemoRead( cPath + cFileName )
   
   /*
    * Aqui processamos qualquer requisiá∆o de inclus∆o de outros sources ou
    * arquivos externos.
    * 03/12/2009 - 17:25:01
    */
   cFileBody := StrTran( cFileBody, Chr( 13 )+Chr(10), Chr(10) )
   cFileBody := StrTran( cFileBody, Chr( 13 ), Chr(10) )
   cFileBody := StrTran( cFileBody, Chr( 9 ), "   " )

   WHILE ( ( p := hb_At( '@include(', cFileBody ) ) > 0 )

         i := hb_At( ')', cFileBody, p + 9 )
         t := Substr( cFileBody, p + 9, i - ( p + 9) )
         t := StrTran( t, '"', '' )
         t := StrTran( t, "'", '' )
         t := alltrim( t )
         t := NormalizePath( cPath + t )

         Token1 := SUBSTR( cFileBody, 1, p - 1 )
         Token1 := SUBSTR( Token1, 1, rat( Chr(10), Token1 ) ) + ' * '

         Token2 := SUBSTR( cFileBody, i )
         Token2 := SUBSTR( Token2, At( Chr(10), Token2 ) )
         
         IF !File( t )
            ? "ERROR: Can't include requested file:", t
            ?
            quit
         End
         
         cFileBody := hb_memoRead( t )
         
         cFileBody := StrTran( cFileBody, Chr( 13 )+Chr(10), Chr(10) )
         cFileBody := StrTran( cFileBody, Chr( 13 ), Chr(10) )

         WHILE Right( cFileBody, 1 ) $ CHR(10)
               cFileBody := Substr( cFileBody, 1, Len( cFileBody ) -1 )
         End

         cFileBody := StrTran( cFileBody, Chr( 10 ), Chr(10) + ' * ' )
         cFileBody := StrTran( cFileBody, Chr( 9 ), "   " )
         cFileBody := Token1 + cFileBody + Token2
         Token1 := Token2 := ''
   End
   
   aLines     := hb_aTokens( cFileBody, Chr(10) )
   cFileBody  := nil                                  // Liberamos um pouco da memoria
   s_aMemvars := hb_Hash()
   
   nLine  := 0
   nCount := 0
   nTotLines := Len( aLines )
   lIgnore:= .F.
   
   AAdd( aLines, ' ' )
   AAdd( aLines, ' ' )

   FOR nLine := 1 TO nTotLines
       cLine := Alltrim( aLines[ nLine ] )
       
       IF Chr(9) $ cLine
         cLine := StrTran( cLine, Chr(9), Space(3) )
       End
       
       IF (( p := hb_at( '@request(', cLine, 1 ) ) != 00 )
          i := hb_at( ')', cLine, p )
          t := Substr( cLine, p + 9, i - (p+9) )

          IF HB_HPOS( s_aMemvars, Lower( t ) ) == 0
             p := ''
          ELSE
             p := s_aMemvars[ Lower( t )]
          End
          cLine := StrTran( cLine, '@request(' + t + ')', p )
       End
       
       Token1 := hb_tokenGet( cLine, 1, " " )
       Token2 := hb_tokenGet( cLine, 2, " " )

       IF Token1 == '*' .AND. Token2 == '@define'
          cLine := StrTran( cLine, '  ', ' ' )
          cLine := StrTran( cLine, '  ', ' ' )
          cLine := StrTran( cLine, '  ', ' ' )

          t := hb_aTokens( cLine, ' ' )

        * Se ele passou algum valor adicional, iremos concatenar isto
          IF Len( t ) > 2
             p := Lower(t[3])
             
             IF HB_HPOS( s_aMemvars, p ) == 0
                s_aMemvars[ p ] := ''
             End

             aEval( t, {|a| s_aMemvars[ p ] += a + ' ' }, 4 )

       /*
        * Se ele nao passou nenhum valor - s¢ o nome do campo - iremos zerar o
        * conteudo da "variavel"
          ELSEIF Len( t ) == 2
             t[2] := Lower(t[2])
             IF HB_HPOS( s_aMemvars, t[2] ) != 0
                s_aMemvars[ t[2] ] := ''
             End
        /**/
          End
          Loop
       End
       
       IF Token1 == '/**' .AND. Topic == nil
          Topic := hb_hash()
          Key   := 'desc'

          Topic[ 'src'  ] := NormalizePath( cPath + cFileName )
          Topic[ 'line' ] := nLine
          Topic[ 'name' ] := ''
          Topic[ 'desc' ] := ''
          Topic[ 'proto'] := ''
          Topic[ 'argv' ] := {}
          Topic[ 'see'  ] := nil
          Topic[ 'revd' ] := ''
          Topic[ 'revt' ] := ''
          Topic['samples']:= {}
          
          lIgnore := isCode := isPre := .F.
          Loop
       End
       
       IF Token1 == '*/' .AND. Topic != nil
          IF TopicFinish( aOutPut, aLines, @nLine, Topic )
             nCount ++
          End
          
          Topic := nil
          Loop
       End

       IF ( Topic == nil ) .OR. lIgnore
          Loop
       End

     * ê um codigo de exemplo?
       IF cLine == '* </sample>'
          Topic[key] += '</code></pre>'// + CRLF
          Key := ''
          isCode := isPre := .F.
          Loop
       End

       IF isPre .OR. isCode
          cLine := Substr( cLine, 2 )
       ELSE
          cLine := Alltrim( Substr( cLine, 2 ) )
       End

       IF cLine == '@code'    THEN cLine := iif( isCode, '</code>', '<code>' )
       IF cLine == '@pre'     THEN cLine := iif( isPre, '</pre>', '<pre>' )
       IF cLine == '@see'     THEN Loop
       IF cLine == '@description' THEN Key := 'desc'
       IF cLine == '@desc'        THEN Key := 'desc'
       IF cLine == '@ignore'
          lIgnore := .T.
          Loop
       End
       
     * ê um argumento da funá∆o?
       IF Left( Token2, 2 ) == '@<' .AND. Right( Token2, 1 ) == '>'
        * Token2 := Substr( Token2, 3, Len( Token2 ) -3 )
        * cLine  := Substr( cLine, at( '>', cLine ) + 1 )

          Token2 := Substr( Token2, 2, Len( Token2 ) -1 )
          cLine  := Substr( cLine, at( '>', cLine ) + 1 )

          AAdd( Topic[ 'argv' ], Token2 )
          p   := Len( Topic[ 'argv' ] )
          Key := ARG_PREFIX + hb_ntos( p )

          Topic[Key] := cLine + ' '
          Loop
       End

     * ê um codigo de exemplo?
       IF cLine == '<sample>'
          p   := Len( Topic[ 'samples' ] ) + 1
          Key := PRG_PREFIX + hb_ntos( p )
          AAdd( Topic[ 'samples' ], Key )

          Topic[key] := '<pre><code>' // + CRLF
          isCode := isPre := .T.
          Loop
       End

       IF cLine == '<code>'
          isCode := .T.
          Topic[key] += '<pre><code>' // + CRLF
          Loop
       End
       IF cLine == '</code>' .OR. cLine == ' </code>'
          isCode := .F.
          Topic[key] += '</code></pre>'// + CRLF
          Loop
       End
       IF cLine == '<pre>' .OR. cLine == ' <pre>'
          isPre := .T.
          Topic[key] += '<pre><code>' // + CRLF
          Loop
       End
       IF cLine == '</pre>' .OR. cLine == ' </pre>'
          isPre := .F.
          Topic[key] += '</code></pre>'// + CRLF
          Loop
       End
       IF Left( cLine, 5 ) == '@see '
          isCode := isPre := .F.
          
          cLine  := Alltrim( Substr( cLine, 6 ) )
          cLine  := StrTran( cLine, '  ', ' ' )
          cLine  := StrTran( cLine, '  ', ' ' )
          cLine  := StrTran( cLine, '  ', ' ' )
          cLine  := StrTran( cLine, ' ', ',' )
          cLine  := StrTran( cLine, ',,', ',' )
          cLine  := StrTran( cLine, ',,', ',' )
          cLine  := StrTran( cLine, ',,', ',' )

          IF VALTYPE( Topic['see'] ) <> "A"
             Topic['see'] := {}
          End

          aEval( hb_atokens( cLine, ',' ), {|a| AAdd( Topic['see'], a ) })
          Loop
       End

     * Achou uma notaá∆o com data e hora?
       IF ( HB_TOKENCOUNT( cLine, '/' ) > 1 .AND. HB_TOKENCOUNT( cLine, ':' ) > 2 ) .AND. ;
          ( HB_TOKENCOUNT( cLine, '@' ) > 0 .OR. HB_TOKENCOUNT( cLine, '-' ) > 0 ) .AND. ;
          IsDigit(cLine) .AND. Len( cLine ) < 30

          aWords := hb_aTokens( Left( cLine, 40 ),, .T. )
          aEval( aWords, {|a|
                              Topic['revd'] := iif( "/" $ a, a, Topic['revd'] )
                              Topic['revt'] := iif( ":" $ a, a, Topic['revt'] )
                          } )
          Loop
       End

     * Achou um provavel prototipo desta funcao?
       IF ( '(' $ cLine .AND. '<' $ cLine .AND. '>' $ cLine .AND. ;
            isIdent( StrTran( Token2, '(', '' ) ))                ;
                                                             .OR. ;
          ( '(' $ cLine .AND. ')' $ cLine .AND. '->' $ cLine .AND. ;
            Empty( Topic['proto'] )        .AND. ;
            isIdent( StrTran( StrTran( Token2, '(', '' ), ')', '' ) ))

          Key := 'proto'
       End

       IF Empty( Key )
          *
       ELSEIF Empty( cLine )
          IF !Empty( Topic[key] )
            Topic[key] += CRLF
          End
       ELSE
          Topic[key] += cLine + ' '
          
        * Termino de frase? Insira um CRLF automaticamente
          IF Key == 'proto' .AND. '->' $ cLine
             Key := 'desc'
          ELSE
             IF isCode .OR. isPre .OR. Right( cLine, 1 ) $ ".!:"
                Topic[key] += CRLF
             End
          End
       End
   NEXT

   ?? '-', hb_ntos( nLine ), 'line(s)', hb_ntos( nCount ), 'symbol(s).'
   RETURN nCount

********************************************************************************
FUNCTION wxVersion()
   RETURN WXWEB_VERSION
   
FUNCTION wxExeName()
   RETURN hb_argv(0)

FUNCTION wxExePath()
   LOCAL Path := hb_argv(0)
   RETURN SubStr( Path, 1, Rat( HB_OSPATHSEPARATOR(), Path ))
********************************************************************************

// Retorna .T. se a string passada como 1¶ argumento for um comando aceito como
// o segundo argumento.
// 30/11/2009 - 05:53:29
FUNCTION isCmd( cStr, cCmd )
   LOCAL nLen
   
   cStr := Upper( Alltrim( cStr ) ) + ' '
   cCmd := Upper( Alltrim( cCmd ) ) + ' '
   nLen := Len( cStr )
   
   FOR i := nLen TO 4 STEP -1
       IF Left( cStr, i ) == Left( cCmd, i )
          RETURN .T.
       End
   End
   RETURN .F.
   
// Testa se o nome passado como argumento Ç um identificador v†lido
// 30/11/2009 - 07:50:34
FUNCTION isIdent( cName )
   LOCAL str := '_ABCDEFGHIJKLMNOPQRSTUVXYWZabcdefghijklmnopqrstuvxywz'
   LOCAL i,c := Substr( cName, 1, 1 )
   
   IF !( c $ str )
      RETURN .F.
   End
   
   FOR i := 2 TO Len( cName )
       c := Substr( cName, i, 1 )
       
       IF !( IsDigit(c) .OR. c $ str )
          RETURN .F.
       End
   End
   RETURN .T.
   
/**
 * Caso o nome da funcao esteja em branco, iremos tentar obte-la diretamente da
 * proxima linha no codigo fonte.
 * 02/12/2009 - 11:19:52
 */
FUNCTION ExtractFuncName( aLines, nLine, Topic )
   LOCAL cLine  := alltrim( aLines[ nLine ] )
   LOCAL Token1 := hb_tokenGet( cLine, 1, " " )
   LOCAL Token2 := hb_tokenGet( cLine, 2, " " )
   LOCAL aWords

   Token2 := StrTran( Token2, '(', '' )
   Token2 := StrTran( Token2, ')', '' )

   IF ( isCmd( Token1, 'FUNCTION' ) .OR. isCmd( Token1, 'PROCEDURE'  )   .OR.  ;
               Token1 == 'HB_FUNC'  .OR.        Token1 == 'HB_FUNC(' )

      IF 'HB_FUNC' $ Token1
         Topic[ 'name'] := alltrim(Token2) + '()'
      ELSE
         Topic[ 'name'] := alltrim(Token2) + iif( isCmd( Token1, 'FUNCTION' ), '()', '' )

         IF Empty( Topic[ 'proto'] )
            cLine  := StrTran( cLine, '(', '' )
            cLine  := StrTran( cLine, ')', '' )
            cLine  := StrTran( cLine, ',', '' )
            aWords := hb_aTokens( cLine,, .T. )

            cLine := aWords[2] + '('

            aEval( aWords, {|a,b|
            cLine += iif( b <> 3, ',', '' ) + ' <' + a + '>'
            }, 3 )

            Topic[ 'proto'] := cLine + ' )'
         End
      End
   End
   RETURN !Empty( Topic[ 'name'] )

STATIC;
FUNCTION TopicFinish( aOutPut, aLines, nLine, Topic )
   LOCAL cLine  := alltrim( aLines[ nLine ] )
   LOCAL Token1 := hb_tokenGet( cLine, 1, " " )
   LOCAL T
   
   IF Empty( Topic[ 'desc' ] )
      RETURN .F.
   End

   IF Empty( Topic[ 'name' ] )
      nLine++
      IF !ExtractFuncName( aLines, @nLine, Topic )
         RETURN .F.
      End
   End

   IF ( (T := FindTopic( Topic[ 'name' ], aOutPut )) != nil )
      ? 'Error duplicate IDENTIFIER "' + t['name'] + '" declared in:'
      ? '', t['src'] + '('+hb_ntos( t['line'] ) +') and '
      ? '', Topic['src'] + '('+hb_ntos( Topic['line'] ) +')'
      ?
      QUIT
   End
 
 * Aqui vemos se o nome do topico atual consta na minha lista de SEE ALSO... Se
 * constar algo eu excluo o topico atual de l† para evitar referencia cruzada.
 * 02/12/2009 - 16:11:22
   IF VALTYPE( Topic['see'] ) == 'A'
      FOR t := 1 TO Len( Topic['see'] )

         IF ( Alltrim( Upper( Topic[ 'name' ] )) == Alltrim( Upper( Topic['see',t] )) )
            hb_aDel( Topic['see'], t, .T. )
            t := 1
         End
      End
   End

   BuildUniqueID( Topic )
   AAdd( aOutput, Topic )
   RETURN .T.

FUNCTION BuildUniqueID( aTopicItem )
   LOCAL u := Lower( Alltrim( aTopicItem[ 'name' ] ))
   
   u := strtran( u, '(', '' )
   u := strtran( u, ')', '' )
   u := strtran( u, '_', '-' )

   IF '(' $ aTopicItem[ 'name' ]
      u := 'function.' + u + '.html'
   ELSE
      u := 'procedure.' + u + '.html'
   End
   
   aTopicItem[ 'url' ] := u
   RETURN .T.

FUNCTION FindTopic( cTopicName, aOutPut )
   LOCAL nPos := aScan( aOutput, {|aItem| Alltrim( Upper( aItem[ 'name' ] )) == Alltrim( Upper( cTopicName )) } )
   
   IF nPos != 0
      RETURN aOutPut[ nPos ]
   ENDIF
   RETURN nil
   
STATIC;
FUNCTION B0E1H6DB2B(x,y)
   LOCAL a, b
   a := b := ''
   
   IF HB_HPOS( x, 'name' ) > 0
      a := x['name']
   End

   IF HB_HPOS( y, 'name' ) > 0
      b := y['name']
   End
   RETURN a < b
   
FUNCTION GetUrlLink( t )
   LOCAL u := '<li><a href="' + t['url'] + '" target="direita">'
   LOCAL n

   IF Empty( t['proto'] )
      n := t['name']
   ELSE
      n := hb_tokenGet( StrTran( t['proto'], '(', ' ' ), 1, " " )
   End
   
   IF 'function' $ u
       n += '()'
   End
   
   u += n + '</a></li>' + CRLF
   RETURN u

FUNCTION H( c, lTrim )
   STATIC aChars := {{ '&amp;',    '&' }, ;
                     { '&lt;',     '<' }, ;
                     { '&gt;',     '>' }, ;
                     { '<pre>'  ,'&lt;pre&gt;'   }, ;
                     { '<code>' ,'&lt;code&gt;'  }, ;
                     { '</pre>' ,'&lt;/pre&gt;'  }, ;
                     { '</code>','&lt;/code&gt;' }, ;
                     { '&aacute;', '·' }, ;
                     { '&acirc;',  '‚' }, ;
                     { '&agrave;', '‡' }, ;
                     { '&atilde;', '„' }, ;
                     { '&ccedil;', 'Á' }, ;
                     { '&eacute;', 'È' }, ;
                     { '&ecirc;',  'Í' }, ;
                     { '&iacute;', 'Ì' }, ;
                     { '&oacute;', 'Û' }, ;
                     { '&ocirc;',  'Ù' }, ;
                     { '&otilde;', 'ı' }, ;
                     { '&uacute;', '˙' }, ;
                     { '&uuml;',   '¸' }, ;
                     { '&Aacute;', '¡' }, ;
                     { '&Acirc;',  '¬' }, ;
                     { '&Agrave;', '¿' }, ;
                     { '&Atilde;', '√' }, ;
                     { '&Ccedil;', '«' }, ;
                     { '&Eacute;', '…' }, ;
                     { '&Ecirc;',  ' ' }, ;
                     { '&Iacute;', 'Õ' }, ;
                     { '&Oacute;', '”' }, ;
                     { '&Ocirc;',  '‘' }, ;
                     { '&Otilde;', '’' }, ;
                     { '&Uacute;', '⁄' }, ;
                     { '&Uuml;',   '‹' } }

   DEFAULT lTrim TO .F.
   
   /*
    * Se ele digitou algum acento em formato OEM, aqui convertemos o mesmo para
    * ANSI antes de operarmos sobre a string removendo seus acentos.
    * 02/12/2009 - 14:11:40
    */
   IF isOEM(c)
      c := HB_OEMTOANSI( c )
   End

   IF lTrim
      WHILE Right( c, 1 ) $ CHR(13)+CHR(10)
            c := Substr( c, 1, Len( c ) -1 )
      End
   End

   aEval( aChars, {|a| c := StrTran( c, a[2], a[1] ) } )
   c := StrTran( c, CRLF, '<br>' )
   RETURN c
   
FUNCTION WriteHtml( hTopic, hPrevious, hNext, aOutPut )
   LOCAL u := PATH_DEST + PATH_SEPARATOR + hTopic['url']
   PRIVATE html := ''
   
   Topic( hTopic, hPrevious, hNext, aOutPut )
   hb_memowrit( u, html )
   RETURN nil

FUNCTION wxQout(...)
   LOCAL aParams := hb_AParams()
   LOCAL nCount  := Len( aParams )

   AEval( aParams, {| x, p | html += hb_cstr(x) + iif( p <> nCount, ' ', '' ) })
   html += CRLF
   RETURN nil
   
FUNCTION wxQQout(...)
   LOCAL aParams := hb_AParams()
   LOCAL nCount  := Len( aParams )

   AEval( aParams, {| x, p | html += hb_cstr(x) + iif( p <> nCount, ' ', '' ) })
   RETURN nil
   
// Normaliza o PATH de um aplicativo retirando os '..' que houverem
// 02/12/2009 - 12:03:49
FUNCTION NormalizePath( cPath )
   LOCAL aList
   LOCAL aToken
   LOCAL i, p
   
   IF !( ".\" $ cPath .OR. "./" $ cPath ) THEN;
      RETURN cPath

   cPath := StrTran( cPath, '\', PATH_SEPARATOR )
   cPath := StrTran( cPath, '/', PATH_SEPARATOR )
   
   aToken := hb_aTokens( cPath, PATH_SEPARATOR )
   cPath  := ''

   FOR i := 1 TO Len( aToken ) -1
       IF aToken[i] == '..'
          hb_aDel( aToken, i, .T. )
          hb_aDel( aToken, i-1, .T. )
          i := 1
       End
   End
   
   aEval( aToken, {|p,n| cPath += p + iif( n <> Len(aToken), PATH_SEPARATOR, '' ) } )
   RETURN cPath

// Extrai de uma frase s¢ a 1¶ sentenáa para poder agrega-la Ö descricao desta
// funá∆o.
// 02/12/2009 - 12:03:27
FUNCTION ShortDesc( x )
   LOCAL p := 0
   LOCAL n := 1
   
   WHILE .T.
      p := hb_At( '.', x, n )

      IF Lower( Substr( x, p, 3 ) ) $ '.t.;.f.'
         n += p + 3
         Loop
      End
      
      Exit
   End
   
   IF p == 0 THEN ;
      p := At( '!', x )
      
   IF p == 0 THEN ;
      RETURN x
      
   RETURN Substr( x, 1, p )
   
/*
 * Retorna .T. se ele conseguir identificar na string passada como argumento
 * alguma letras acentuada no formato OEM.
 * 02/12/2009 - 14:07:16
 */
FUNCTION isOEM( str )
   STATIC A
   LOCAL i

   IF a == NIL
      a := {}
      AAdd( a,'†')
      AAdd( a,'Ç')
      AAdd( a,'°')
      AAdd( a,'¢')
      AAdd( a,'£')
      AAdd( a,'Ö')
      AAdd( a,'ä')
      AAdd( a,'ç')
      AAdd( a,'ï')
      AAdd( a,'ó')
      AAdd( a,'É')
      AAdd( a,'à')
      AAdd( a,'å')
      AAdd( a,'ì')
      AAdd( a,'ñ')
      AAdd( a,'Ñ')
      AAdd( a,'â')
      AAdd( a,'ã')
      AAdd( a,'î')
      AAdd( a,'Å')
      AAdd( a,'∆')
      AAdd( a,'‰')
      AAdd( a,'§')
      AAdd( a,'á')
      AAdd( a,'µ')
      AAdd( a,'ê')
      AAdd( a,'÷')
*     AAdd( a,'‡')
*     AAdd( a,'È')
      AAdd( a,'∑')
*     AAdd( a,'‘')
      AAdd( a,'ﬁ')
*     AAdd( a,'„')
*     AAdd( a,'Î')
      AAdd( a,'∂')
*     AAdd( a,'“')
      AAdd( a,'◊')
*     AAdd( a,'‚')
*     AAdd( a,'Í')
      AAdd( a,'é')
*     AAdd( a,'”')
      AAdd( a,'ÿ')
      AAdd( a,'ô')
      AAdd( a,'ö')
*     AAdd( a,'«')
*     AAdd( a,'Â')
      AAdd( a,'•')
      AAdd( a,'Ä')
   End

   FOR i := 1 TO Len(a)
       IF a[i] $ str
          RETURN .T.
       End
   End
   RETURN .F.

STATIC;
FUNCTION LoadFile( cFile, hHash, cColor )
   LOCAL cText
   LOCAL aLines
   LOCAL cLine

   cText := hb_memoread( wxExePath() + cFile )
   cText := StrTran( cText, Chr( 13 )+Chr(10), Chr(10) )
   cText := StrTran( cText, Chr( 13 ), Chr(10) )
   cText := StrTran( cText, Chr( 9 ), "   " )
   aLines:= hb_aTokens( cText, Chr(10) )
   cText := ''
   
   FOR EACH cLine IN aLines
       IF !Empty(alltrim( cLine )) THEN;
          hHash[ lower( cLine ) ] := cColor
   End
   
   RETURN nil
   
// Converte um codigo fonte em PRG para o formato HTML
// 02/12/2009 - 22:53:27
FUNCTION Prg2Html( cSource )
   LOCAL cHtml := ''
   LOCAL hKeys := hb_Hash()
   LOCAL aLines
   LOCAL aLine
   LOCAL cLine
   LOCAL s, n
   LOCAL r, p
   LOCAL c, k
   LOCAL Token1
   LOCAL lToEnd := .f.
   
   LoadFile( 'prgCmds.txt',   hKeys, 'wx-reservedword' )
   LoadFile( 'prgFuncs.txt',  hKeys, 'wx-function' )
   LoadFile( 'prgConsts.txt', hKeys, 'wx-constant' )

   cSource := StrTran( cSource, Chr( 13 )+Chr(10), Chr(10) )
   cSource := StrTran( cSource, Chr( 13 ), Chr(10) )
   cSource := StrTran( cSource, Chr( 9 ), "   " )
   aLines  := hb_aTokens( cSource, Chr(10) )
   cSource := ""

 * This is a really bad code...  O_o
   FOR r := 1 TO Len( aLines )
     * aLine := hb_aTokens( H(aLines[r]) , ' ;,.<>!#$%&{}[]' )
       cLine := H(aLines[r])
       aLine := hb_aTokens( cLine , ' ', .T. )
       cLine := ''

       FOR n := 1 TO Len( aLine )
           s := aLine[n]
           c := ''

           Token1 := hb_tokenGet( alltrim(s), 1, " " )

           IF ;// Left( Token1,2 ) == '//' .OR. ;
              ;// Left( Token1,2 ) == '&&' .OR. ;
              Left( Token1,1 ) == '*'  .OR. ;
              Lower(Left( Token1,5 )) == 'note'

              s := '<span class="wx-comment">' + s + '</span>'

           ELSE
              c := ''

              FOR p := 1 TO Len( s )
                  IF lToEnd THEN exit
                  
                  IF !Empty(c) .AND. Substr( s, p, 1 ) == c
                     c := ""
                     k := '</span>'
                     s := Stuff( s, p+1, 0, k )
                     p ++
                     Loop
                  End

                  IF Empty(c) .AND. Substr( s, p, 1 ) $ [/]
                     IF Substr( s, p+1, 1 ) $ [*/]
                        c := '*/'
                        k := '<span class="wx-comment">'
                        s := Stuff( s, p-1, 0, k )
                        p += Len(k)
                        lToEnd := .T.
                        Exit
                     End
                  End

                  IF Empty(c) .AND. Substr( s, p, 1 ) $ [*]
                     IF Substr( s, p+1, 1 ) $ [/]
                        c := '*/'
                        k := '<span class="wx-comment">'
                        s := Stuff( s, p-1, 0, k )
                        p += Len(k)
                        lToEnd := .T.
                        Exit
                     End
                  End

                  IF Empty(c) .AND. Substr( s, p, 1 ) $ ["']
                     c := Substr( s, p, 1 )
                     k := '<span class="wx-string">'
                     s := Stuff( s, p-1, 0, k )
                     p += Len(k)
                     Loop
                  End
              End
           End
           
           c := ''
           p := 0

           IF !Empty(s)
              p := HB_HPos( hKeys, Lower(s) )

              IF p > 0 THEN;
                 c := HB_HValueAt( hKeys, p )

              IF Empty(c)
                 IF isDigit( s ) THEN c := 'wx-number'
              End
           End

           IF !Empty(c)
              s := '<span class="' + c + '">' + s + '</span>'
           End
           cHtml += s + ' '
       End

       IF lToEnd THEN cHtml += '</span>'
       cHtml  += CRLF
       lToEnd := .F.
   End
   
   RETURN cHtml
   