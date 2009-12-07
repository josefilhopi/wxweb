/******************************************************************************
 * Sistema .....: wxCompiler
 * Programa ....: wxErrorTable.ch
 * Autor .......: Vailton Renato
 * Data ........: 08/04/2008 - 11:32:53
 ******************************************************************************/
#include 'common.ch'

FUNCTION wxErrorDesc( nCode )
   SWITCH nCode
   CASE 01
      RETURN 'Cannot open input file: "%1"'
   CASE 02
      RETURN 'Cannot write output file: "%1"'
   CASE 0201
      RETURN 'Cannot write output file: "%1" (DOS error: #%2)'
   CASE 03
      RETURN 'Missing input file!'
   CASE 04
      RETURN "Error F0004  Could not execute required tool: '%1'"
   CASE 32
      RETURN "Error F0032  Could not find required tool: '%1'"
   CASE 33
      RETURN "Error F0033  Incomplete command line option: '%1'"
   CASE 34
      RETURN "Error F0034  Bad command line option: '%1'"
   End
   RETURN ''
   
FUNCTION GetHBPath( Path )
   LOCAL aPath := PathToArray(Path)
   LOCAL Result:= ''
   LOCAL i

   FOR i := 1 TO Len( aPath )
       Result := aPath[i] + 'harbour.exe'

       IF FILE( Result )
          RETURN Result
       End

       Result := aPath[i] + 'HB.exe'

       IF FILE( Result )
          RETURN Result
       End
   End
   RETURN ""

STATIC;
FUNCTION PathToArray( cPath )
   LOCAL cList := iif( Valtype(cPath) == 'C' .and. Len(cPath)>0, cPath, GetEnv( "PATH" ) )
   LOCAL aList := {}
   LOCAL cSep  := hb_OSPathListSeparator()
   LOCAL cDirSep := hb_OSPathDelimiters()
   LOCAL nPos

   IF cList != NIL

      DO WHILE ( nPos := At( cSep, cList ) ) != 0
         AAdd( aList, SubStr( cList, 1, nPos - 1 ) )        // Add a new element
         cList := SubStr( cList, nPos + 1 )
      ENDDO

      AAdd( aList, cList )                      // Add final element
      AAdd( aList, wxExePath() )                // Add final element

      /* Strip ending delimiters */
*     AEval( aList, { | x, i | iif( x[ -1 ] $ cDirSep,  aList[ i ] := Left( x, Len( x ) - 1 ), ) } )
      AEval( aList, { | x, i | iif( Right( x, 1 ) $ cDirSep,  nil, aList[ i ] += HB_OSPATHSEPARATOR() ) } )
   ENDIF

   RETURN aList

/*
 * Gera um nome aleatorio e unico de arquivo temporario na pasta passada como
 * argumento e que nao seja igual ao segundo argumento informado.
 * 08/04/2008 - 13:17:33
 */
FUNCTION RandomFileName( cPath, cInvalidName )
   STATIC aLast := {}
   
   LOCAL s := 'ABCDEFGHIJKLMNOPQRSTUVXZKYW01234567890_'
   LOCAL i,c,n,f
   
   DEFAULT cPath        TO CurrentPath()
   DEFAULT cInvalidName TO ''
   
   WHILE .T.
         f := ''
         WHILE (Len(f) != 15)
             n := HB_RANDOM( 1, Len(s) )
             c := Substr( S, n, 1 )
             
             IF Len(f)<1 .AND. !IsAlpha(c)
                LOOP
             End
             f += c
         End
         
         f := cPath + f + '.PRG'
         
         IF File(f)
            LOOP
         End
         
         IF f == cInvalidName
            Loop
         End
         
         IF aScan( aLast, f ) <> 00
            LOOP
         End

         AADD( aLast, f )
         
         IF Len( aLast ) > 10
            AIns( aLast, 1 )
            aDel( aLast, Len(aLast)-1)
            aLast[1] := f
         End

//         IF ' ' $ F
//            f := '"' + f + '"'
//         End
         RETURN f
   End
   RETURN nil
   

STATIC FUNCTION hb_pwd()
   RETURN CurDrive() + hb_osDriveSeparator() + hb_osPathSeparator() + CurDir()

FUNCTION CurrentPath()
   LOCAL cPath := hb_pwd()

   IF Right( cPath, 1 ) != HB_OSPATHSEPARATOR()
      cPath += HB_OSPATHSEPARATOR()
   End
   RETURN cPath
   