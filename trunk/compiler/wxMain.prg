/******************************************************************************
 * Sistema .....: wxc ( a wxWeb Compiler )
 * Programa ....: wxMain.prg
 * Autor .......: Vailton Renato
 * Data ........: 08/04/2008 - 11:02:15
 * Revisado em .: 29/11/2009 - 16:22:26
 ******************************************************************************/
*#define COMPILER_ENABLED_TRACE

#define WXWEB_DISABLE_AUTOLOAD
#define WXWEB_IGNORE_CMDS
#define CRLF      chr(13)+chr(10)
#define CRLFCOMA  chr(13)+chr(10)+';'

#include "wxWeb.ch"
#include 'common.ch'
#include "simpleio.ch"

#define HEADER_VERSION        WXS_SIGNATURE
#define DEFAULT_EXT  '.prg'

#define HTML_MODE     0
#define PRG_MODE      1
#define BREAK_MODE    2
#define PHP_PARSER    8
#define ASP_PARSER    9

#define IS_HTML_MODE  (Mode == HTML_MODE)
#define IS_BREAK_MODE (Mode == BREAK_MODE)

STATIC scDest       := ''
STATIC scSource     := ''
STATIC scHarbPath   := ''
STATIC scHarbCmdLine:= ''
STATIC saHarbArgs   := ''
STATIC snErrorLevel := 0
STATIC saFileTemp   := {}
STATIC slSkipDefCH  := False
STATIC slSkipBuild  := False

FUNCTION wxMain( ... )
   LOCAL Args   := HB_AParams()
   LOCAL PCount := Len( Args )
   LOCAL Text, Type, Arg, Val

   ShowHeader()

   IF PCount <1 THEN;
      ShowHelp()
      
   FOR i := 1 TO PCount
       Arg := Args[i]
       Val := Substr( Arg, 3 )
       
       IF Substr( Arg, 1, 1 ) == '-' THEN;
          Arg := '/' + Substr( Arg, 2 )
          
       IF Substr( Arg, 1, 1 ) != '/'
          IF Empty( scSource )
             scSource := Arg
             Loop
          End
          Error( 34, Arg )
       End
       
       IF Len( Arg ) < 2 THEN;
          Error( 34, Arg )

       SWITCH Lower( Subst( Arg, 2, 1) )
       CASE 'a'   && /a    automatic memvar declaration
       CASE 'b'   && /b    debug info
       CASE 'l'   && /l    suppress line number information
       CASE 'v'   && /v    variables are assumed M->
       CASE 'z'   && /z    suppress shortcutting (.and. & .or.)
       CASE 'p'   && /p    gerar arquivo .PPO (nao documentado!!!)
            saHarbArgs += ' ' + Arg
            EXIT

       CASE 'd'   && /d<id>[=<val>]   #define <id>
       CASE 'i'   && /i<path>         #include file search path
       CASE 'u'   && /u[[+]<file>]    use command def set in <file> (or none)
                  && /undef:<id>      #undef <id>
            saHarbArgs += ' ' + Arg
            EXIT
            
       CASE 'h'   && /h<path>         current harbour install path
            scHarbPath := Val
            EXIT
            
       CASE 'e'   && /es[<level>]     set exit severity
            Arg := Lower(Arg)
            
            IF Arg == '/es' .OR. ;
               Arg == '/es0'.OR. ;
               Arg == '/es1'.OR. ;
               Arg == '/es2'
               saHarbArgs += ' ' + Arg
            ELSE
               Error( 34, Arg )
            End
            EXIT
            
       CASE 'n'
            IF !Empty(val) THEN;
               Error( 34, Arg )
               
            saHarbArgs += ' ' + Arg
            EXIT
            
       CASE 'o'
            IF Empty(val) THEN;
               Error( 33, Arg )

            scDest := Val
            EXIT

       CASE 's'
            slSkipDefCH := True
            EXIT

       CASE 't'
            slSkipBuild := True
            EXIT

       CASE 'w'
            IF !( str( val(val), 1, 0 ) $ '0,1,2,3') THEN;
               Error( 34, Arg )
               
            saHarbArgs += ' ' + Arg
            EXIT

       OTHERWISE
         Error( 34, Arg )
         
       End
   End

 * Nome do arquivo .PRG de entrada ‚ v lido???
   IF Empty( scSource ) THEN;
      Error( 3, scSource )
   IF At( '.', scSource ) == 00 THEN;
      scSource += DEFAULT_EXT
   IF !File( scSource ) THEN;
      Error(1, scSource )
   IF ("*" $ scSource ) .OR. ( "?" $ scSource ) THEN;
      Error(1, scSource )
 * O arquivo de destino ‚ v lido?
   IF Empty( scDest )
      scDest := Substr( scSource, 1, Rat( '.', scSource )) + iif( slSkipBuild, 'src', 'wxs' )
      i := Rat( hb_osDriveSeparator(), scDest)
      IF i<>00 THEN scDest := Substr( scDest,i+1)
      i := Rat( HB_OSPATHSEPARATOR(), scDest)
      IF i<>00 THEN scDest := Substr( scDest,i+1)
   End
   IF !( HB_OSPATHSEPARATOR() $ scDest ) .AND. ;
      !( hb_osDriveSeparator() $ scDest )
       scDest := CurrentPath() + scDest
   End
   saHarbArgs += ' /O"' + scDest + '"'

 * Achou o HARBOUR.EXE no HD???
   IF !slSkipBuild
      scHarbCmdLine := GetHBPath(scHarbPath)

      IF !File(scHarbCmdLine)
         Error(32, 'harbour.exe')
      End
   End

   IF File(scDest)
      IF FErase(scDest) == -1 THEN;
         Error(0201,{scDest,NTRIM(FError())})
   End
   
   IF !hb_MemoWrit(scDest, '') THEN;
      Error(2, scDest )

   ?? 'Parsing "' + scSource + '" ...'
   Text := ParseFile(scSource)
   Text := BuildPRGcode( Text )

 * Quer apenas que eu gere o arquivo .PRG intermediario? Ok então...
 * 29/11/2009 - 15:24:04
   IF slSkipBuild
      ? 'Writing "' + scDest + '" ...'
      hb_MemoWrit( scDest, Text )
   ELSE

      saFileTemp := Array(2)
      saFileTemp[1] := RandomFileName( nil, scDest )
      saFileTemp[2] := RandomFileName( nil, scDest )

#ifdef COMPILER_ENABLED_TRACE
      saFileTemp[1] := CurrentPath() + 'wxc.txt'
#endif

      ? 'Building "' + scDest + '" ...'
      IF !hb_MemoWrit( saFileTemp[1], Text ) THEN;
         Error(2, saFileTemp[1] )

      IF (' ' $ scHarbCmdLine) THEN;
         scHarbCmdLine := '"' + scHarbCmdLine + '" '

      ?

      IF (' ' $ saFileTemp[1])
         scHarbCmdLine := scHarbCmdLine + ' "'+ saFileTemp[1] + '" /q /gh' +;
                          saHarbArgs // + ' > ' + saFileTemp[2]
      ELSE
         scHarbCmdLine := scHarbCmdLine + ' '+ saFileTemp[1] + ' /q /gh' +;
                          saHarbArgs // + ' > ' + saFileTemp[2]
      End

      hb_processRun( scHarbCmdLine, , @Text )

      Text := StrTran( Text, saFileTemp[1], scSource )
      Text := StrTran( Text, chr(13)+chr(10)+chr(13), CRLF )

      IF Left( Text, 1 ) == CHR(13) THEN;
         Text := Substr( Text, 2 )

      IF Right( Text, 3 ) == chr(13)+chr(10)+chr(32) THEN;
         Text := Substr( Text, 1, Len( text ) -3 )
      IF Right( Text, 2 ) == chr(13)+chr(10) THEN;
         Text := Substr( Text, 1, Len( text ) -2 )

      IF !Empty(alltrim(text)) THEN;
         ? Text

    * Tudo OK se achamos o arquivo final!
    * IF File(scDest) THEN;
    *    AdjustFileHeader()

      p := saFileTemp[1]
      p := Substr(p,1,rat('.',p)) + 'ppo'

      o := scSource
      o := Substr(o,1,rat('.',o)) + 'ppo'

      FErase(o)
      FRename(p,o)
   End
   
   IF File(scDest)
      ? 'Done.'
   ELSE
      ? 'Error!'
      snErrorLevel := 255
   End

   RETURN nil



FUNCTION ShowHeader()
  ?? 'wxWeb Compiler v1.5 build 20091127' // ('+HB_COMPILER()+'/Win32)'
   ? 'Copyright 2006-2010 by Vailton Renato, vailtom@gmail.com'
   ?
   RETURN
   
FUNCTION ShowHelp()
   ? 'Syntax:  ', wxExeName(),'<file['+DEFAULT_EXT+']> [options]'
   ?
   ? "Options:  /a               automatic memvar declaration"
   ? "          /b               debug info"
   ? "          /d<id>[=<val>]   #define <id>"
   ? "          /es[<level>]     set exit severity"
   ? "          /h<path>         current harbour install path"
   ? "          /i<path>         #include file search path"
   ? "          /l               suppress line number information"
   ? "          /n               no implicit starting procedure"
   ? "          /o<path>         output file drive and/or path"
   ? "          /s               disable wxWeb custom commands"
   ? "          /t               only build .prg source. Don't compile it"
   ? "          /u[[+]<file>]    use command def set in <file> (or none)"
   ? "          /undef:<id>      #undef <id>"
   ? "          /v               variables are assumed M->"
   ? "          /w[<level>]      set warning level number (0..3, default 1)"
   ? "          /z               suppress shortcutting (.and. & .or.)"
   ?
   RETURN Bye(1)
   
FUNCTION Bye( nError )
   snErrorLevel := nError
   ErrorLevel( snErrorLevel )
   QUIT
   RETURN

FUNCTION Error( nCode, Args )
   LOCAL Msg := wxErrorDesc( nCode )
   LOCAL i,v,t
   
   DEFAULT Args TO {}
   IF ValType( Args ) == 'C' THEN;
      Args := { Args }
   
   IF Empty( Msg ) THEN;
      Msg := 'Error C'+ StrZero(nCode,4) + ' unsupported error! '
      
   FOR i := 1 TO Len( Args )
       v := Args[i]
       t := Valtype(v)
       
     * IF t == 'C' THEN v := v
       IF t == 'N' THEN v := Str(v)
       IF t == 'D' THEN v := DTOC(v)
       IF t == 'L' THEN v := IIF(v,'.T.','.F')
       IF t == 'B' THEN v := "{|| ... }"
       IF t == 'A' THEN v := "{ ... }"
       IF t == 'O' THEN v := "{ Obj:" + v:ClassName + " }"
       IF t == 'U' THEN v := "NIL"
       IF t == 'H' THEN v := "{ => }"
       
       Msg := StrTran( Msg, '%'+alltrim(str(i)), v )
   End
   
   ?? Msg
   ?
   Bye( nCode )
   RETURN
   
EXIT;
PROCEDURE EuPorUltimo()
     ErrorLevel( snErrorLevel )
#ifdef COMPILER_ENABLED_TRACE
     aEval( saFileTemp, {|a| FErase(a) },2)
#else
     aEval( saFileTemp, {|a| FErase(a) },1)
#endif
   RETURN
   
FUNCTION wxExeName()
   RETURN hb_argv(0)

FUNCTION wxExePath()
   LOCAL Path := hb_argv(0)
   RETURN SubStr( Path, 1, Rat( HB_OSPATHSEPARATOR(), Path ))

// 08/04/2008 - 08:27:57
FUNCTION ParseFile( filename )
   LOCAL Buffer := hb_Memoread( filename )
   LOCAL nLen   := Len( Buffer )
   LOCAL HTML   := {}
   LOCAL Mode   := HTML_MODE
   LOCAL Parser := PHP_PARSER       // 23/07/2008 - 14:02:58
   LOCAL i,c,n,p,b,t1,t2
   LOCAL CR     := CHR(13)
   LOCAL LF     := CHR(10)
   LOCAL bAdd  := {||
                      IF !Empty(b)
                         AADD( HTML,{ Mode, b })
                      End
                      b := ''
                    }

   c := b := ''
   FOR i := 1 TO nLen

       p := c
       c := Substr( Buffer, i, 1 )
       n := iif( i == nLen, '', Substr( Buffer, i+1, 1 ) )

       DO CASE
       CASE IS_HTML_MODE .AND. ((( c == '<' ) .AND. ( n == '?' )) .OR. ;
                                (( c == '<' ) .AND. ( n == '%' )) )
            bAdd:Eval()
            
            // Validamos aqui qual o parser deve ser usado.
            IF (n == '?')
               t1 := hb_at( '?>', Buffer, i+2 )
               Parser := PHP_PARSER
            ELSE
               t1 := hb_at( '%>', Buffer, i+2 )
               Parser := ASP_PARSER
            End
            
            IF t1 == 0
               // Parser error here!
               EXIT
            End
            
            t2 := (t1 - (i+2))
            b  := Substr( Buffer, i +2, t2 )
            i  := t1+1

            WHILE .T.
                  t1 := At( CRLF, b )
                  
                  IF t1 == 0
                     AADD( HTML, {PRG_MODE, b} )
                     Exit
                  End
                  
                  AADD( HTML, {PRG_MODE, Subst( b, 1, t1 -1 ) } )
                  AADD( HTML, {BREAK_MODE, ''} )

                  b := Subst( b, t1 +2 )
            End
            
            AADD( HTML, {HTML_MODE, ''} )
            b := ''
            Loop

       CASE !IS_HTML_MODE .AND. ( (( Parser == PHP_PARSER ) .AND. ( c == '?' ) .AND. ( n == '>' )) .OR. ;
                                  (( Parser == ASP_PARSER ) .AND. ( c == '%' ) .AND. ( n == '>' )) )

            IF !Empty(b) THEN;
               bAdd:Eval()

            Mode := HTML_MODE
            i++
            Loop

       CASE c == CR .AND. n == LF
            bAdd:Eval()
            AADD( HTML, {BREAK_MODE, ''} )
            
            i++
            Loop

       CASE c == LF
            bAdd:Eval()
            AADD( HTML, {BREAK_MODE, ''} )
            Loop

       CASE c == CR
            bAdd:Eval()
            AADD( HTML, {BREAK_MODE, ''} )
            Loop
       End

       b += c
   End
   bAdd:Eval()

   IF !IS_HTML_MODE
      // Erro tag <? aberta e nao fechada!!!
   End
   RETURN Html

FUNCTION BuildPRGcode( aHtml )
   LOCAL i, c, n, k, sep1, sep2
   LOCAL Item, Mode, OldMode, NextMode
   LOCAL Html   := ''
   LOCAL CR     := CHR(13)
   LOCAL LF     := CHR(10)

   c := Len( aHtml )
   n := 0

   IF (slSkipDefCH) .OR. c <= 1
      *            1
   ELSE
       IF ( aHtml[1,1] == BREAK_MODE )
          Html += '#include "'+wxExePath()+'wxCustCmd.ch"'

       ELSEIF ( c > 1 .AND. aHtml[2,1] == BREAK_MODE .AND. Empty( aHtml[1,2] ) )
          Html += '#include "'+wxExePath()+'wxCustCmd.ch"'
          
       ELSE
          Html += '#include "'+wxExePath()+'wxCustCmd.ch";'
       End
   End

 * Trocamos o 2 pelo 1, para evitar dar um erro no .CH !!! 23/07/2008 - 08:01:55
   OldMode := NextMode := -1
   
   FOR i := 1 TO c
       OldMode := Mode
       
       Mode := aHtml[i,1]
       Item := aHtml[i,2]
       
       IF i == c
          NextMode := -1
       ELSE
          NextMode := aHtml[i+1,1]
       End

       IF IS_BREAK_MODE
          n++
          
          IF OldMode == HTML_MODE
             IF Right( Html, 1 ) $ CRLFCOMA
               Html += "wxQQout( chr(13)+chr(10) )" + CRLF
             ELSE
               Html += "; wxQQout( chr(13)+chr(10) )" + CRLF
             End
          ELSE
             Html += CRLF
          End
          Loop
       End
       
       IF IS_HTML_MODE
          IF Item == ''
             *
          ELSEIF Empty(Item)
             IF ( i != c ) THEN;
                Html += "wxQQout( chr(13)+chr(10) )" + CRLF
          ELSE
             Html += "wxQQout("

             IF At( "'", Item ) == 00
                sep1 := sep2 := "'"
             ELSEIF At( '"', Item ) == 00
                sep1 := sep2 := '"'
             ELSEIF At( '[', Item ) == 00 .AND. ;
                    At( ']', Item ) == 00
                sep1 := '['; sep2 := ']'
             ELSE
                sep1 := '"'
                sep2 := '"+chr(34)+"'
                Item := StrTran( Item, sep1, sep2 )
                sep1 := sep2 := '"'
             End

             Html += sep1
             Html += Item

             IF Right( Item, 1 ) $ CRLF
                Html := Left( Html, Len( Html ) - 1 ) + sep2 + ", chr(13)+chr(10) "
             ELSE
                Html += sep2
             End

             IF (i == c)
                Html += ")" //+ CRLF
             ELSEIF ( aHtml[i+1,1] != HTML_MODE )
                IF Len( aHtml[i+1,2]) < 1
                   Html += ")"
                ELSE
                   Html += ");"
                End
             ELSE
                Html += ")" + CRLF
             End
          End
       ELSE
          Html += RTrim(Item)
          IF (i != c) .AND. ( NextMode == HTML_MODE ) .AND. !( Right( Html,1 ) $ CRLF )
             Html += ';'
          End
       End
   End
   
#ifdef COMPILER_ENABLED_TRACE
   Item := ''
   aEval( aHtml, {|a| Item += str(a[1],1) + ' ' + a[2] + CRLF })
   MemoWrit( CurrentPath() + 'wxc.arr', Item )
#endif
   RETURN Html

FUNCTION Ntrim(x)
   RETURN alltrim( Str(x) )
   
/*
 * Ajusta o HEADER do arquivo .HRB para chamar as funcoes corretas!!
 * 08/04/2008 - 17:22:16
 *
FUNCTION AdjustFileHeader()
   LOCAL h := FOpen( scDest, 2)
   
   IF FError() <> 00 THEN;
      AADD( saFileTemp, scDest ); Error(0201,{scDest,NTRIM(FError())})
      
   FWrite( h, HEADER_VERSION )
   
   IF FError() <> 00 THEN;
      AADD( saFileTemp, scDest ); Error(0201,{scDest,NTRIM(FError())})
      
   FClose( h )
   RETURN nil
/***/

FUNCTION HB_NOMOUSE()
   RETURN nil
