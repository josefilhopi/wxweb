#include "common.ch"
#include "error.ch"
#include "fileio.ch"

#include "wxWebFramework.ch"

#undef CRLF
#define CRLF (chr(13)+chr(10))


#ifndef _NADA_

ANNOUNCE ErrorSys

REQUEST Select,Alias,RecNo,DbFilter,DbRelation,IndexOrd,IndexKey
REQUEST wxErrorGetTemplate

/*
 * Obtem a lista geral de erros
 * 05/10/2008 - 09:00:27
 */
STATIC;
FUNCTION GetErrorListMsgs()
   STATIC aError := nil

      IF aError != NIL THEN;
         RETURN aError 
         
      aError := { ;
                  { 1000, "%1" } ,;
                  { 1001, "Erro de argumento: %1" } ,;
                  { 1002, "Arquivo não encontrado: %1" } ,;
                  { 1003, "Nenhuma página especificada para 'default_page' em %1." } ,;
                  { 1004, "Erro enviando os cabeçalhos iniciais da pagina.%1" } ,;
                  { 1005, "Impossível persistir os dados da seção.%1" } ,;
                  { 0, "" } ;
                 }
      RETURN aError

/*
 * Seta o errorsys default da wxWeb!
 * 22/12/2006 09:05:59
 */

PROCEDURE ErrorSys
     wxWebErrorSys()
   RETURN

PROCEDURE wxWebErrorSys
     Errorblock( { | oError | wxWebDefError( oError ) } )
   RETURN

/*
 * Eis a funcao principal que trata das exceções ocorridas dentro do sistema.
 * 20/12/2006
 */
STATIC; 
FUNCTION wxWebDefError( oError, lClearBuffer )

     LOCAL cMessage
     LOCAL cDOSError

     LOCAL aOptions
     LOCAL nChoice

     DEFAULT lClearBuffer TO .F.
     lClearBuffer := .T.

     // By default, division by zero results in zero
     If oError:genCode == EG_ZERODIV
        Return 0
     Endif

     // Set NetErr() of there was a database open error
     If oError:genCode == EG_OPEN .and. ;
                oError:osCode == 32 .and. ;
                oError:canDefault
        Neterr( .T. )
        Return .F.
     Endif

     // Set NetErr() if there was a lock error on dbAppend()
     If oError:genCode == EG_APPENDLOCK .and. ;
                oError:canDefault
        Neterr( .T. )
        Return .F.
     Endif

     cMessage := wxGetErrorMessage( oError )
     
     If !Empty( oError:osCode )
        cDOSError := "(DOS Error " + Ltrim( Str( oError:osCode ) ) + ")"
     Endif

     If ValType( oError:Args ) == "A"
       cMessage += " Arguments: (" + Arguments( oError ) + ")"
     Endif

     // Build buttons

     IF MaxCol() > 0
         aOptions := {}

         // AAdd( aOptions, "Break" )
         Aadd( aOptions, "Quit" )

         If oError:canRetry
            Aadd( aOptions, "Retry" )
         Endif

         If oError:canDefault
            Aadd( aOptions, "Default" )
         Endif

         // Show alert box
         //TraceLog( cMessage )

         nChoice := 1   // force QUIT - vailton @ 29-05-2006 : 19:01
         
         If !Empty( nChoice )
            Do Case
                  Case aOptions[ nChoice ] == "Break"
                     Break( oError )
                  Case aOptions[ nChoice ] == "Retry"
                     Return .T.
                  Case aOptions[ nChoice ] == "Default"
                     Return .F.
            Endcase
         Endif
     ENDIF

     // "Quit" selected

     If !Empty( oError:osCode )
        cMessage += " " + cDOSError
     Endif

     SET PRINTER OFF
     SET PRINTER TO
     
     SET DEVICE  TO SCREEN
     SET CONSOLE ON
     
     *?? "Content-Type: text/html"+CHR(13)+CHR(10)
     *?? CHR(13)+CHR(10)
     
     /* 
      * Opcionalmente limpamos todos os buffers para forçarmos apenas a saida 
      * na tela da janela de erros!
      * 22/12/2006 09:04:58
      */  
     IF lClearBuffer
//        wxWebClearOutPutBuffer()
//        wxWebClearOutPutHeader()
//        wxWebContentType("Content-Type: text/html")
     End

     wxQQout( LogError( oError, cMessage ) )
     ErrorLevel(1)
     Quit
Return .F.

/*
 * 17/11/2006 20:24:05
 * Gera um erro do sistema.
 */   
FUNCTION xWeb_RaiseError( cError, cFileName, nErrorNumber )
   RETURN xWeb_Raise( cError, cFileName, nErrorNumber )
   
FUNCTION xWeb_Raise( cError, cFileName, nErrorNumber )
   LOCAL oErr
   
   IF ValType( cError ) == 'N'      
      IF ValType( cFileName ) == "A" 
         RETURN xWeb_RaiseErrorNum( cError, cFileName)
      
      ELSE 
         RETURN xWeb_RaiseErrorNum( cError, {cFileName, nErrorNumber} )         
      End
   End

   IF cError <> NIL
      oErr := ErrorNew()
      oErr:severity    := ES_ERROR
      oErr:genCode     := EG_LIMIT
      oErr:subSystem   := "WxWeb"
      oErr:subCode     := iif( valtype( nErrorNumber ) == "N", nErrorNumber, 0)
      oErr:description := iif( valtype( cError ) == "C", cError, "" )
      oErr:canRetry    := .F.
      oErr:canDefault  := .F.
      oErr:fileName    := iif( valtype( cFileName ) == "C", cFileName, "" )
      oErr:osCode      := 0
      Eval( ErrorBlock(), oErr )
   ELSE
      QUIT
   ENDIF
   RETURN nil

/*
 * 17/11/2006 20:23:38  
 * Exibe um erro padrao dentro da wxWeb
 */
FUNCTION xWeb_RaiseErrorNum( nError, aArgs )
   RETURN xWeb_RaiseNum( nError, aArgs )
   
FUNCTION xWeb_RaiseNum( nError, aArgs )
   LOCAL a,i
   LOCAL Text
   LOCAL aError

 * Parametros para a String do erro
   IF aArgs == NIL 
      aArgs := Array(100)
      aFill( aArgs,"")
   End
   
   IF ValType( aArgs ) != "A"
      aArgs := {aArgs}
   End
   
 * Preenche o array
   IF nError == NIL 
      nError := ERR_ARGERROR
      aArgs  := { 'xWeb_RaiseNum' }
   End
   
 * Pegamos a string
   aError := GetErrorListMsgs()
   a := aScan( aError, {|_1| _1[1] == nError })
   
 * Se nao houver, garante que seja exibida a msg de texto
   IF a == 00 
      AADD( nError, { ERR_ARGERROR, "Erro de argumento: %1" })
      aArgs  := { 'xWeb_RaiseNum' }
   End
   
   Text   := aError[a][2]
   nError := aError[a][1]
   
 * Jogamos os valores do array lá
   FOR i := 1 TO Len(aArgs)
       a := aArgs[i]
       
       if a == NIL
          a := 'NIL'
          
       elseif ValType( a ) == 'O'
          a := a:ClassName
           
       elseif ValType( a ) == 'H'
          a := '{Hash}'
           
       elseif ValType( a ) == 'A'
          a := '{...}'
           
       end
       
       Text := StrTran( Text, '%' + Alltrim( Str( i )), a )
   End
   
 * Retornamos a string formatada
   RETURN xWeb_Raise( Text, '', nError ) 

// [vszakats]

/*
 * Formata a msg de erro a partir de um objeto Error()
 * 21/5/2007 08:11:24
 */
FUNCTION wxGetErrorMessage( oError )
     LOCAL cMessage

     // start error message
     cMessage := Iif( oError:severity > ES_WARNING, "Error", "Warning" ) + " "

     // add subsystem name if available
     If Ischaracter( oError:subsystem )
        cMessage += oError:subsystem()
     Else
        cMessage += "???"
     Endif

     // add subsystem's error code if available
     If Isnumber( oError:subCode )
        cMessage += "/" + Ltrim( Str( oError:subCode ) )
     Else
        cMessage += "/???"
     Endif

     // add error description if available
     If Ischaracter( oError:description )
        cMessage += "  " + oError:description
     Endif

     // add either filename or operation
     Do Case
      Case !Empty( oError:filename )
          cMessage += ": " + oError:filename
      Case !Empty( oError:operation )
          cMessage += ": " + oError:operation
     Endcase
   RETURN cMessage

/*
 * Cria um LOG com os detalhes do erro gerado e adicionalmente formata o objeto 
 * de erro passado como argumento para um formato HTML à ser ecoado na tela.
 */
STATIC;
FUNCTION LogError( oerr,cMessage )
     LOCAL aLogFile    := { wxExePath() + 'wxLog.txt', .T. }
     LOCAL cLogFile    := aLogFile[1]
     LOCAL lAppendLog  := aLogFile[2]
     LOCAL nCount
     LOCAL nHandle
     LOCAL Pos, Path
     LOCAL cTemp, Temp, nCols

     nCols := MaxCol()

     If !lAppendLog
        nHandle := Fcreate( cLogFile, FC_NORMAL )
     Else
        If !File( cLogFile )
           nHandle := Fcreate( cLogFile, FC_NORMAL )
        Else
           nHandle := Fopen( cLogFile, FO_READWRITE )
           FSeek( nHandle, 0, FS_END )
        Endif
     Endif

     If nHandle < 3 .and. lower( cLogFile ) != 'error.log'
        // Force creating error.log in case supplied log file cannot
        // be created for any reason
        cLogFile := 'error.log'
        nHandle := Fcreate( cLogFile, FC_NORMAL )
     Endif

     If nHandle < 3
     Else
        FWriteLine( nHandle, Padc( ' Arquivo de LOG de Erros da Aplicação ', 79, '*' ) )
        FWriteLine( nHandle, '' )
        FWriteLine( nHandle, 'Horário .........: ' + Dtoc( Date() ) + ' ' + Time() )
        FWriteLine( nHandle, 'Memória Disp. ...: ' + strvalue( Memory( 0 ) ) )
        FWriteLine( nHandle, 'Multi Threading .: ' + If( HB_MTVM(),"Yes","No" ) )
        FWriteLine( nHandle, 'Aplicativo  .....: ' + HB_CMDLINE() )
        FWriteLine( nHandle, 'OS. .............: ' + os() )
        FWriteLine( nHandle, 'Compilador C ....: ' + hb_compiler() )
        FWriteLine( nHandle, 'xHarbour (versao): ' + version() )
        FWriteLine( nHandle, 'xHarbour (Build).: ' + hb_builddate() )

        FWriteLine( nHandle, "IP ..............: " + wxClientIP() )
        FWriteLine( nHandle, "Browser .........: " + wxBrowserName() + ' v' + wxBrowserVersion() + ' on ' +;
                                                     wxOSVersion()   )   
        IF !Empty( wxDeviceType() ) THEN;
           FWriteLine( nHandle, "Device ..........: " + wxDeviceType() )      

        IF Type( "Select()" ) == "UI"
           FWriteLine( nHandle, 'Area atual ......:' + strvalue( &("Select()") ) )
        End

        FWriteLine( nHandle, "" )
        FWriteLine( nHandle, Padc( " Detalhes Internos da Exceção ", nCols, "-" ) )
        FWriteLine( nHandle, "" )
        FWriteLine( nHandle, "Mensagem Gerada .: " + cMessage )
        FWriteLine( nHandle, "Subsystem Call ..: " + oErr:subsystem() )
        FWriteLine( nHandle, "System Code .....: " + strvalue( oErr:suBcode() ) )
        FWriteLine( nHandle, "Default Status ..: " + strvalue( oerr:candefault() ) )
        FWriteLine( nHandle, "Description .....: " + oErr:description() )
        FWriteLine( nHandle, "Operation .......: " + oErr:operation() )
        FWriteLine( nHandle, "Arguments .......: " + Arguments( oErr ) )
        FWriteLine( nHandle, "Involved File ...: " + oErr:filename() )
        FWriteLine( nHandle, "Dos Error Code ..: " + strvalue( oErr:oscode() ) )
        FWriteLine( nHandle, "Thread ID .......: " + hb_cstr( HB_THREADID() ) )

        FWriteLine( nHandle, "" )
        FWriteLine( nHandle, Padc( " Rastreamento de Pilha ", nCols, "-" ) )
        FWriteLine( nHandle, "" )

        nCount := 2
        Path   := hb_argv(0)

         if (Pos := Rat( '/', Path )) <> 00
            Path := Substr( Path, 1, Pos )
         end

         if (Pos := Rat( '\', Path )) <> 00
            Path := Substr( Path, 1, Pos )
         end
         
        While !Empty( Procname( ++ nCount ) )
               Pos  := alltrim(ProcFile( nCount ))

               if Empty(Pos)
                  Pos := '{indefinido}'

               elseif File( Path + Pos )
                  Pos := Path + Pos

               endif

               Temp := ' ' + Alltrim(Procname( nCount )) + '('+alltrim(Transform( Procline( nCount ), "999,999,999" ))+') no modulo ' + Pos
               FWriteLine( nHandle, Temp )
               **FWriteLine( nHandle, Padr( Procname( nCount ), 21 ) + ' : ' + Transform( Procline( nCount ), "999,999" ) + " in Module: " + ProcFile( nCount ) )
        Enddo

        FWriteLine( nHandle, "" )
        FWriteLine( nHandle, Padc( " Variáveis de ambiente ", nCols, "-" ) )
        FWriteLine( nHandle, "" )

        cTemp := xWebLogServerVars(.F.)
        FWriteLine( nHandle, cTemp )

        FWriteLine( nHandle, Padc( ' Configurações SETs ativas ', 79, '-' ) )
        FWriteLine( nHandle, '' )
        FWriteLine( nHandle, "Exact ...........: " + strvalue( Set( 1 ), .T. ) )
        FWriteLine( nHandle, "Fixed ...........: " + strvalue( Set( 2 ), .T. ) )
        FWriteLine( nHandle, "Decimals is at ..: " + strvalue( Set( 3 ) ) )
        FWriteLine( nHandle, "Date Format .....: " + strvalue( Set( 4 ) ) )
        FWriteLine( nHandle, "Epoch ...........: " + strvalue( Set( 5 ) ) )
        FWriteLine( nHandle, "Path ............: " + strvalue( Set( 6 ) ) )
        FWriteLine( nHandle, "Default .........: " + strvalue( Set( 7 ) ) )
        FWriteLine( nHandle, "Exclusive .......: " + strvalue( Set( 8 ), .T. ) )
        FWriteLine( nHandle, "SoftSeek ........: " + strvalue( Set( 9 ), .T. ) )
        FWriteLine( nHandle, "Unique ..........: " + strvalue( Set( 10 ), .T. ) )
        FWriteLine( nHandle, "Deleted .........: " + strvalue( Set( 11 ), .T. ) )
        FWriteLine( nHandle, "Cancel ..........: " + strvalue( Set( 12 ), .T. ) )
        FWriteLine( nHandle, "Debug ...........: " + strvalue( Set( 13 ) ) )
        FWriteLine( nHandle, "Color ...........: " + strvalue( Set( 15 ) ) )
        FWriteLine( nHandle, "Cursor ..........: " + strvalue( Set( 16 ) ) )
        FWriteLine( nHandle, "Console .........: " + strvalue( Set( 17 ), .T. ) )
        FWriteLine( nHandle, "Alternate .......: " + strvalue( Set( 18 ), .T. ) )
        FWriteLine( nHandle, "AltFile .........: " + strvalue( Set( 19 ) ) )
        FWriteLine( nHandle, "Device ..........: " + strvalue( Set( 20 ) ) )
        FWriteLine( nHandle, "Printer .........: " + strvalue( Set( 23 ) ) )
        FWriteLine( nHandle, "PrintFile .......: " + strvalue( Set( 24 ) ) )
        FWriteLine( nHandle, "Margin ..........: " + strvalue( Set( 25 ) ) )
        FWriteLine( nHandle, "Bell ............: " + strvalue( Set( 26 ), .T. ) )
        FWriteLine( nHandle, "Confirm .........: " + strvalue( Set( 27 ), .T. ) )
        FWriteLine( nHandle, "Escape ..........: " + strvalue( Set( 28 ), .T. ) )
        FWriteLine( nHandle, "Insert ..........: " + strvalue( Set( 29 ), .T. ) )
        FWriteLine( nHandle, "Intensity .......: " + strvalue( Set( 31 ), .T. ) )
        FWriteLine( nHandle, "Scoreboard ......: " + strvalue( Set( 32 ), .T. ) )
        FWriteLine( nHandle, "Delimeters ......: " + strvalue( Set( 33 ), .T. ) )
        FWriteLine( nHandle, "Delimchars ......: " + strvalue( Set( 34 ) ) )
        FWriteLine( nHandle, "Wrap ............: " + strvalue( Set( 35 ), .T. ) )
        FWriteLine( nHandle, "Message .........: " + strvalue( Set( 36 ) ) )
        FWriteLine( nHandle, "MCenter .........: " + strvalue( Set( 37 ), .T. ) )
        //FWriteLine( nHandle, "" )

        FWriteLine( nHandle, "" )
        FWriteLine( nHandle, Padc( 'Detalhes sobre os ARQUIVOS DE DADOS abertos', nCols, "=" ) )
        FWriteLine( nHandle, "" )

        Pos := 0
        IF Type( "Select()" ) == "UI"
           For nCount := 1 To 600
              If !Empty( ( nCount )->( &("Alias()") ) )
                  Pos++
                 ( nCount )->( FWriteLine( nHandle, "Area Numero .....: " + strvalue( &("Select()") ) ) )
                 ( nCount )->( FWriteLine( nHandle, "Alias ...........: " + &("Alias()") ) )
                 ( nCount )->( FWriteLine( nHandle, "Registro atual ..: " + strvalue( &("RecNo()") ) ) )
                 ( nCount )->( FWriteLine( nHandle, "Filtro atual ....: " + &("DbFilter()") ) )
                 ( nCount )->( FWriteLine( nHandle, "Relação ativa ...: " + &("DbRelation()") ) )
                 ( nCount )->( FWriteLine( nHandle, "Indice atual ....: " + strvalue( &("IndexOrd(0)") ) ) )
                 ( nCount )->( FWriteLine( nHandle, "Indice (chave) ..: " + strvalue( &("IndexKey(0)") ) ) )
                 ( nCount )->( FWriteLine( nHandle, "" ) )
              Endif
           Next
        ENDIF

        if Pos == 00
           FWriteLine( nHandle, Padc( '( NAO HA ARQUIVOS DE DADOS ABERTOS )', nCols ) )
           FWriteLine( nHandle, "" )
        end
        
        FWriteLine( nHandle, Padc( "", nCols, "*" ) )
        Fclose( nHandle )
     Endif
   RETURN xWeb_ParseParms( cMessage )

STATIC;
FUNCTION strvalue( c, l )

     LOCAL cr := ''
     Default l To .f.
     Switch ValType( c )
         Case "C"
             cr := c
             exit
         Case "N"
             cr := Alltrim( Str( c ) )
             exit
         Case "M"
             cr := c
             exit
         Case "D"
             cr := Dtoc( c )
             exit
         Case "L"
             cr := If( l, If( c, "On", "Off" ), If( c, "True", "False" ) )
             exit
     End
Return cr

STATIC FUNCTION FWriteLine( nh, c )
   Fwrite( nh, c + HB_OsNewLine() )
Return nil

STATIC FUNCTION Arguments( oErr )

   LOCAL xArg, cArguments := ""

   IF ValType( oErr:Args ) == "A"
      FOR EACH xArg IN oErr:Args
         cArguments += " [" + Str( xArg:__enumIndex(), 2 ) + "] = Type: " + ValType( xArg )
         
         IF xArg != NIL
            cArguments +=  " Val: " + hb_CStr( xArg )
         ENDIF
      NEXT
   ENDIF

RETURN cArguments

/*******************************************************************************
 * xWeb Framework: Log Routines, 30-05-2006 @ 08:21 - Escritorio na EST.ITAP 910
 ******************************************************************************/
STATIC;
FUNCTION xWeb_ParseParms(ErrorMessage)
   LOCAL Page, Pos
   LOCAL Html, Temp, a, b, c
   LOCAL nCount
   LOCAL SrcFile, SrcLine
   LOCAL PrgFile, PrgLine
   LOCAL Path := hb_argv(0)
   LOCAL ClientInfo
   LOCAL Srce
   
   if (Pos := Rat( '/', Path )) <> 00
      Path := Substr( Path, 1, Pos )
   end

   if (Pos := Rat( '\', Path )) <> 00
      Path := Substr( Path, 1, Pos )
   end
   
   IF Subst( Path, 1, 4 ) == '\\?\'
      Path := Subst( Path, 5 )
   End
   
   Temp := wxGetEnv( 'REQUEST_URI' )

   IF ( Empty(Temp) .AND. 'IIS' $ wxGetEnv('SERVER_SOFTWARE') )
      Temp := wxGetEnv( 'SCRIPT_NAME' ) + wxGetEnv( 'PATH_INFO')
   End

 * Page := Substr( Temp, LEN( wxGetEnv( 'SCRIPT_NAME') ) +1 )
   Page := Temp

   if (Pos := Rat( '/', Page)) <> 00
      Page := Substr( Page, Pos )
   end

   if (Pos := Rat( '\', Page )) <> 00
      Page := Substr( Page, Pos )
   end

   if (Pos := Rat( '.exe', lower(Page) )) <> 00
      Page := Substr( Page, 1, Pos-1 )
   end

   if Substr( Page, 1, 1) == '/'
      Page := Substr( Page, 2 )
   end

   /*
    * Remove caracteres da QUERY_STRING atual
    */
   if ((Pos := At( '%', Page )) <> 00 )
      Page := iif( Pos == 01, '', Substr( Page, 1, Pos -1 ) )
   end

   if ((Pos := At( '?', Page )) <> 00 )
      Page := iif( Pos == 01, '', Substr( Page, 1, Pos -1 ) )
   end

   if ((Pos := At( '&', Page )) <> 00 )
      Page := iif( Pos == 01, '', Substr( Page, 1, Pos -1 ) )
   end

   Page := StrTran( Page, '.', '_' )
   
   IF Empty( allTrim(Page) )
      Page := wxGetEnv( 'SCRIPT_NAME' )
   End

   Temp := ""

   SrcFile := ''
   SrcLine := 00
   
   PrgFile := ''
   PrgLine := 00

   nCount := 3
   While !Empty( Procname( ++ nCount ) )
         Pos  := alltrim(ProcFile( nCount ))
         a :=b:= ''
         
         if Empty(Pos)
            Pos := '{indefinido}'
            
         elseif FindFile( Path, @Pos )
            Pos := /*Path + /**/Pos
            
         endif
         
       * Temp += '   Procedimento <b>' + Alltrim(Procname( nCount )) + '('+alltrim(Transform( Procline( nCount ), "@E 999,999,999" ))+')</b> no m&oacute;dulo <b>' + Pos + '</b>'+CRLF
         
         IF (Pos == '{indefinido}')
            *
         ELSE
            c := alltrim(ProcFile( nCount ))
            
            /*
             * Arquivo que contem os fontes (.PRG) a ser exibido
             */
            IF ( !Empty( PrgFile )) .OR. ;
                   ( PrgLine != 00 ) 
               *
            ELSEIF FindFile( Path, @c  )
               PrgFile := c // Path + alltrim(ProcFile( nCount ))
               PrgLine := Procline( nCount )
               
               a := '<font color=red>'
               b := '</font>'
            End
            
            /*
             * Arquivo com a ultima linha do erro!!
             */
            IF ( Procline( nCount ) == 00)
               *
            ELSEIF ( SrcLine == 00 )
               SrcFile := c //alltrim(ProcFile( nCount ))
               SrcLine := Procline( nCount )
            End
         End
        
         IF Empty(a)
            Temp += '   Procedimento <b>' + Alltrim(Procname( nCount )) + '('+alltrim(Transform( Procline( nCount ), "@E 999,999,999" ))+')</b> no m&oacute;dulo <b>' + Pos + '</b>'+CRLF
         ELSE
            Temp += '   '+a+'Procedimento <b>' + a + Alltrim(Procname( nCount )) + '('+alltrim(Transform( Procline( nCount ), "@E 999,999,999" ))+')</b>'+b+' no m&oacute;dulo <b>' + a+ Pos + b + '</b>'+b+''+CRLF
         End
   Enddo

   HTML := wxErrorGetTemplate()
   HTML := StrTran( HTML, '%script%', Page )
   HTML := StrTran( HTML, '%server%', wxGetEnv( 'SERVER_SOFTWARE') )
   HTML := StrTran( HTML, '%version%',wxWebVersion() + ' - ' + DTOC( WXBUILDDATE() ) + ' ' + WXBUILDTIME() )

   nCount  := 4
   
   IF Empty(SrcFile)
      SrcFile := alltrim(ProcFile( nCount ))
      SrcLine := Procline( nCount )
   End
   
   if Empty(SrcFile)
      SrcFile := '{indefinido}'

   elseif File( Path + SrcFile )
      *??  '<br>&nbsp;[[',Path,']]<BR>&nbsp;{{', SrcFile,'}}'
      SrcFile := Path + SrcFile

   endif
   
   Page := ''
   Srce := False
   
   IF File( PrgFile ) .and. PrgLine <> 00
      Page := XWebLoadPRGSource( PrgFile, PrgLine )
      Srce := True
      
      if Empty(Page)
         Page := "   {Impossível Rastrear}"
         Page := "<br>" + Page
         Srce := False

      elseif Left( Page,2 ) == Chr(13)+Chr(10)
         Page := " " + SUBSTR( Page,3)
         Page := "<br>" + Page

      end
   End
   
   ClientInfo := "IP: " + wxClientIP() + CRLF +;
                 "Browser: " + wxBrowserName( .T. ) + ' v' + wxBrowserVersion() + ' on ' +;
                               wxOSVersion()   + CRLF
   
   IF !Empty( wxDeviceType() ) THEN;
      ClientInfo += "Device: " + wxDeviceType() + CRLF      
   
   HTML := StrTran( HTML, '%src_line%', alltrim(Transform( SrcLine, "999,999,999" )) )
   HTML := StrTran( HTML, '%src_file%', SrcFile )
   HTML := StrTran( HTML, '%call_stack%', Temp, 1, 1 )
   HTML := StrTran( HTML, '%server_vars%', xWebLogServerVars(.T.) )
 * HTML := StrTran( HTML, '%user_info%'  , xWebLogUserInfo(.T.) )
   HTML := StrTran( HTML, '%error_message%', ErrorMessage )
   HTML := StrTran( HTML, '%lines%', Page )
   HTML := StrTran( HTML, '%client_info%', ClientInfo )
   HTML := StrTran( HTML, '#SOURCE_BEGIN', IIF( !Srce, '<!--', '' ))
   HTML := StrTran( HTML, '#SOURCE_END'  , IIF( !Srce, '<!--', '' ))
   return HTML
   
//STATIC;
FUNCTION xWebLogServerVars(lFormat)
      LOCAL Result := ''
      LOCAL Block  := {|cVarName,v|;
                                 v := wxGetEnv( cVarName ),;
                                 v := ;
            ;        //
            ;        // Corrige o BUG no IIS v5.x - by Vailton Renato
            ;        //
                     iif(( Empty(v) .AND. cVarName == 'REQUEST_URI' ) .and. ;
                         ( 'IIS' $ wxGetEnv('server_software') ),;
                        wxGetEnv('script_name') + wxGetEnv('path_info'), v ),;
            ;
                        if ( !lFormat, nil, ;
                           (v := StrTran(v,'<', '&lt;'),;
                            v := StrTran(v,'>', '&gt;'));
                        ),;
            ;
                        v := StrTran(v,Chr(13), ''),;
                        v := StrTran(v,Chr(10), ' '),;
            ;
                        if (empty(v), NIL,;
                           if ( lFormat,;
                              Result += '<br>   <b>' + Upper( Alltrim( cVarName )) + '</b>="<i>' + v + '</i>"';
                           ,;
                              Result += Upper( Alltrim( cVarName )) + '="' + v + '"'+Chr(13)+Chr(10);
                           );
                        );
                     }

      Block:Eval( 'AUTH_NAME' )
      Block:Eval( 'AUTH_USER' )
      Block:Eval( 'AUTH_TYPE' )
      Block:Eval( 'CGI_VERSION' )
      Block:Eval( 'DOCUMENT_ROOT' )
      Block:Eval( 'GATEWAY_INTERFACE' )
      Block:Eval( 'HTTP_ACCEPT' )
      Block:Eval( 'HTTP_ACCEPT_CHARSET' )
      Block:Eval( 'HTTP_ACCEPT_ENCODING' )
      Block:Eval( 'HTTP_ACCEPT_LANGUAGE' )
      Block:Eval( 'HTTP_CACHE_CONTROL' )
      Block:Eval( 'HTTP_CONNECTION' )
      Block:Eval( 'HTTP_COOKIE' )
      Block:Eval( 'HTTP_HOST' )
      Block:Eval( 'HTTP_USER_AGENT' )
      Block:Eval( 'PATH_INFO' )
      Block:Eval( 'PATH_TRANSLATED' )
      Block:Eval( 'QUERY_STRING' )
      Block:Eval( 'REMOTE_ADDR' )
      Block:Eval( 'REMOTE_PORT' )
      Block:Eval( 'REQUEST_METHOD' )
      Block:Eval( 'SCRIPT_FILENAME')
      Block:Eval( 'SCRIPT_NAME' )
      Block:Eval( 'SERVER_ADDR' )
      Block:Eval( 'SERVER_ADMIN' )
      Block:Eval( 'SERVER_NAME' )
      Block:Eval( 'SERVER_PORT' )
      Block:Eval( 'SERVER_SIGNATURE' )
      Block:Eval( 'SERVER_SOFTWARE' )
      Block:Eval( 'SERVER_PROTOCOL' )
      Block:Eval( 'USER_AGENT' )

    * Propositalmente deixamos por ultimo estes valores
      Block:Eval( 'REQUEST_URI' )      
      Result += "<br>&nbsp;"
   RETURN Result
   
STATIC;
FUNCTION xWebLogUserInfo(lFormat)
      LOCAL Result := ''
      LOCAL Block  := {|cText, v, cDefault|;
                                 v := iif( Empty(v) .and. !Empty( cDefault ), cDefault, v ),;
                                 v := ;
            ;
                        v := StrTran(v,Chr(13), ''),;
                        v := StrTran(v,Chr(10), ' '),;
            ;
                        if (empty(v), NIL,;
                           if ( lFormat,;
                              Result += '<br>   <b>' + Upper( Alltrim( cText )) + '</b>="<i>' + v + '</i>"';
                           ,;
                              Result += Upper( Alltrim( cText )) + '="' + v + '"'+Chr(13)+Chr(10);
                           );
                        );
                     }

      Block:Eval( 'BrowserName'      , wxBrowserName() )
      Block:Eval( 'BrowserVersion'   , wxBrowserVersion() )
      Block:Eval( 'OSVersion'        , wxOSVersion() + iif(wxHave64Proc(), ' (64-bit)', '' ))
      Block:Eval( 'DeviceType'       , wxDeviceType(), 'Unknow' )
      
      Result += "<br>&nbsp;"
   RETURN Result   
   
static ;
function FindFile( cPath, cFileName )
   LOCAL aPaths,i,j,t
   
   if File( cPath + cFileName )
      cFileName := cPath + cFileName
      return .t.
   end

   IF wxGetConfig( "document_path") == NIL
      * Nada definido? Que estranho...
      * 05/10/2008 - 22:04:10
   ELSEIF File( cPath + wxGetConfig( "document_path",'') + cFileName )
      cFileName := cPath + wxGetConfig( "document_path",'') + cFileName
      RETURN .t.
   End
   
   /*
    * Procura nos paths alternativos pelo arquivo desejado! 
    * 26/12/2006 21:32:17
    */
   aPaths := wxGetConfig( "search_path" )
   
   /*
    * Testamos isto pq agora wxGetConfig() pode retornar um NIL caso a informação
    * nao esteja disponível.
    * 05/10/2008 - 21:55:50
    */   
   IF aPaths == nil THEN;
      RETURN .F. 
      
   aPaths := wxListAsArray( StrTran(aPaths,',',';'), ';' )
   
   j := Len( aPaths )
   
   FOR i := 1 TO j
       t := aPaths[i]
       t := StrTran( t, '($)', cPath )      
       t := AdjustPath(t)
      
       if File( t + cFileName )
          cFileName := t + cFileName
          return .t.
       end
   End   
   return .F.
#endif
            
#pragma BEGINDUMP
#include "hbvmopt.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvmpub.h"
#include "hbstack.h"
#include "hbapifs.h"
#include "hbvm.h"

#define LINE_SPACE 4

HB_FUNC( XWEBLOADPRGSOURCE )
{
   PHB_ITEM pFileName = hb_param( 1, HB_IT_STRING );
   ULONG nLineCurr  = (ULONG) hb_parnl(2);
   ULONG nLineStart = nLineCurr - LINE_SPACE;
   ULONG nLineEnd   = nLineCurr + LINE_SPACE;

   if ((hb_parni(2)-LINE_SPACE)<0)
   {
      nLineStart = 0;
      nLineEnd   = LINE_SPACE + LINE_SPACE;
   }
   
   if( pFileName )
   {
      HB_FHANDLE fhnd = hb_fsOpen( ( BYTE * ) hb_itemGetCPtr( pFileName ), FO_READ | FO_SHARED | FO_PRIVATE );

      if( fhnd != FS_ERROR )
      {
         ULONG ulSize = hb_fsSeek( fhnd, 0, FS_END );
         ULONG nLine  = 1;
         ULONG nPos   = 0;
         ULONG nSize  = 0;
         char s[40];
         BOOL b = FALSE;

         if( ulSize )
         {
            BYTE * pbyBuffer;
            char Text[1024];

            /* Don't read the file terminating EOF character */

            #if ! defined(OS_UNIX_COMPATIBLE)
            {
               BYTE byEOF = HB_CHAR_NUL;

               hb_fsSeek( fhnd, -1, FS_END );
               hb_fsRead( fhnd, &byEOF, sizeof( BYTE ) );

               if( byEOF == HB_CHAR_EOF )
               {
                  ulSize--;
               }
            }
            #endif

            if (ulSize > 4096000)
               ulSize = 4096000;
               
            pbyBuffer = ( BYTE * ) hb_xgrab( ulSize + sizeof( char ) );
            Text[0]   = '\0';

            hb_fsSeek( fhnd, 0, FS_SET );
            hb_fsReadLarge( fhnd, pbyBuffer, ulSize );

            if (nLineCurr == nLine )
            {
               s[0] = '\0';
               b = TRUE;
               sprintf( s, "\n   <font color=red>Linha %lu: ", nLine );
               strcat( Text, s );
               nSize += strlen(s);
            }

            for ( ; nPos < ulSize; nPos ++)
            {
               if (pbyBuffer[nPos] == '\n')
               {
                  nLine ++;
               }

               if (nLine > nLineEnd)
                  break;
               if (nLine >= nLineStart)
               {
                  if (pbyBuffer[nPos] == '\n')
                  {
                     s[0] = '\0';

                     if ((nLine) == nLineCurr)
                     {
                        sprintf( s, "\n   <font color=red>Linha %lu: ", nLine );
                     } else if ((nLine) == nLineCurr+1)
                     {
                        sprintf( s, "\n   </font>Linha %lu: ", nLine );
                     } else {
                        sprintf( s, "\n   Linha %lu: ", nLine );
                     }
                     
                     b = TRUE;
                     strcat( Text, s );
                     nSize += strlen(s);
                     continue;
                  }

                  if (!b)
                  {
                     s[0] = '\0';
                     b = TRUE;
                     sprintf( s, "\n   Linha %lu: ", nLine );
                     strcat( Text, s );
                     nSize += strlen(s);
                  }
                  
                  /*
                   * Convertemos os caracteres "<" e ">" para o respectivo em HTML
                   * 27/12/2006 08:43:26
                   */
                   if ((pbyBuffer[nPos] == '<') ||
                       (pbyBuffer[nPos] == '>'))
                   {
                      Text[nSize] = '&'; nSize ++;
                      Text[nSize] = ((pbyBuffer[nPos] == '<') ? 'l' : 'g' ); nSize ++;
                      Text[nSize] = 't'; nSize ++;
                      Text[nSize] = ';'; nSize ++;
                   } else {
                      Text[nSize] = pbyBuffer[nPos];
                      nSize ++;
                   }
                   
                   Text[nSize] = '\0';
                   if (nSize == 1023)
                      break;
               }
            }

            Text[nSize] = '\0';
            hb_retc( Text );
            hb_xfree( pbyBuffer );
         }
         else
         {
            hb_retc( "" );
         }

         hb_fsClose( fhnd );
      }
      else
      {
         hb_retc( "" );
      }
   }
   else
   {
      hb_retc( "" );
   }
}

/*
 * Retorna o .HTML padrao utilizado como template para a msg de erro apresentada
 * ao usuario.
 * 05/10/2008 - 09:31:08
 */
HB_FUNC( WXERRORGETTEMPLATE )
{
#include "wxErrorTemplate.h"
   hb_retc( generic );
}
#pragma ENDDUMP
