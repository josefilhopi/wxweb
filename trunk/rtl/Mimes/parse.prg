#include "common.ch"
#define CRLF CHR(13)+CHR(10)
/*
 * Entra principal do projeto
 * 21/11/2008 - 19:12:09
 */
FUNCTION Main()

   LOCAL cFile := ".\mimetypes.txt"
   LOCAL aLines:= ListAsArray( MemoRead( cFile ), CRLF )
   LOCAL aMimes:= {}
   LOCAL aExt  := {}
   LOCAL i, p, a, e, m, t
   
   FOR i := 1 TO Len( aLines )
       a := aLines[i]
       a := Limpa(a)
       
       IF Left( a, 2 ) == "//"
          LOOP 
       End
       
       p := At( " ", a )
       e := Substr( a, 1, p-1 )
       m := Substr( a, p+1 )
       
       IF Empty(e)
          Loop
       End
       
    // Ja existe no array?
       IF aScan( aMimes, {|x| x[1] == e }) < 1
          AADD( aMimes, { e, m })
       End

    // Ja existe no array?
       IF aScan( aExt, {|x| x[2] == m }) < 1
          AADD( aExt, { e, m })
       End
              
   End
   
   /* Sorteia os itens pela extensÆo */
   ASORT( aMimes,,, { |x, y| x[1] < y[1] })
   ASORT( aExt  ,,, { |x, y| x[2] < y[2] })  
   
   h := FCreate( "wxMimes.c" )
   t := "#include <string.h>|" +;
        "|" +;
        "/*|" +;
        " * wxMimeGetType( <cExt> ) --> <cMimeType>|" +;
        " * Retorna o tipo mime de uma extensao fornecida como argumento|" +;
        " * "+dtoc(date())+ " " + time()+"|" +;
        " */|" +;
        "char *wxMimeGetType( const char *ext ) |" +;
        "{|" +;
        ""          
        
   FWrite( h, StrTran( t, '|', CRLF ) )
   
   FOR i := 1 TO Len( aMimes )
       a := aMimes[I]
       t := '  if ( strcmp("' + a[1] + '", ext ) == 00 ) return "' + a[2] + '";' + CRLF
       FWrite( h, t  )       
   End
   
   t := '  ' + CRLF +;
        '  return (char *)0;' + CRLF +;
        "}" + CRLF        
   FWrite( h, t )
   
   t := "|" +;
        "/*|" +;
        " * wxMimeGetExt( <cMimeType> ) --> <cExt>|" +;
        " * Retorna a extensÆo padrÆo de um arquivo (sem ponto), com base no |" +;
        " * tipo mime fornecido como argumento|" +;
        " * "+dtoc(date())+ " " + time()+"|" +;
        " */|" +;
        "char *wxMimeGetExt( const char *mime ) |" +;
        "{|" +;
        ""  
        
        
   FWrite( h, StrTran( t, '|', CRLF ) )
   
   FOR i := 1 TO Len( aExt )
       a := aExt[I]
       t := '  if ( strcmp("' + a[2] + '", mime ) == 00 ) return "' + a[1] + '";' + CRLF
       FWrite( h, t  )       
   End
   
   t := '  ' + CRLF +;
        '  return (char *)0;' + CRLF +;
        "}" + CRLF        
   FWrite( h, t )
   
   t := "" + CRLF +;
        '#include "hbapi.h"' + CRLF +;
        '#include "hbapiitm.h"' + CRLF +;
        "" + CRLF +;
        "/*" + CRLF +;
        " * wxMimeGetType( cExt ) --> cMimetype" + CRLF +;
        " * Interface em [x]HB para a funcao acima. Se for passado um argumento" + CRLF +;
        " * com NOME.EXT entao esta funcao tratar  isto e usar  apenas a extensao" + CRLF +;
        " * e passar  do argumento fornecido." + CRLF +;
        " */" + CRLF +;
        'HB_FUNC(WXMIMEGETTYPE)' + CRLF +;
        '{' + CRLF +;   
        '   HB_THREAD_STUB' + CRLF +;   
        '' + CRLF +;   
        '   if (ISCHAR(1))' + CRLF +;
        '   {' + CRLF +;
        '      char * file = hb_parc(1);' + CRLF +;
        '      char * ext;' + CRLF +;
        '' + CRLF +;      
        "      if ( file && (ext  = strrchr( file, '.' )) )" + CRLF +;
        '         ext ++;' + CRLF +;
        '      else' + CRLF +;
        '         ext = file;' + CRLF +;
        '' + CRLF +;      
        '      hb_retc( wxMimeGetType( ext ));' + CRLF +;
        '   }else' + CRLF +;
        '      hb_retc( "" );' + CRLF +;
        '}' + CRLF +;
        "" + CRLF +;
        "/*" + CRLF +;
        " * wxMimeGetExt( cMimetype ) --> cExt" + CRLF +;
        " * Interface em [x]HB para a funcao acima" + CRLF +;
        " */" + CRLF +;
        'HB_FUNC(WXMIMEGETEXT)' + CRLF +;
        '{' + CRLF +;   
        '   HB_THREAD_STUB' + CRLF +;   
        '' + CRLF +;   
        '   if (ISCHAR(1))' + CRLF +;
        '      hb_retc( wxMimeGetExt( hb_parc(1) ));' + CRLF +;
        '   else' + CRLF +;
        '      hb_retc( "" );' + CRLF +;
        '}' + CRLF +;
        ''
   FWrite( h, t )   
   FClose( h )
   RETURN nil
   
/* Remove 'lixos' do mime especificado */   
FUNCTION Limpa(x)
   LOCAL p := At( "(", x )
   
      IF p > 0
         x := Substr( x, 1, p-1 ) 
      End
   
      x := StrTran( x, "=>", " " )
      x := StrTran( x, ".", "" )
      x := StrTran( x, ",", "" )
      x := StrTran( x, CHR(9), " " )
      x := StrTran( x, "  ", " " )
      x := StrTran( x, "  ", " " )
      x := StrTran( x, "  ", " " )
      x := lower( x )
      x := alltrim( x )

   RETURN x      
/*
 * Funcao necess ria para alguns detalhes abaixo
 * 16/07/2007 - 21:39:49
 */	
STATIC;	   
FUNCTION ListAsArray( cList, cDelimiter )
   
   LOCAL nPos              // Position of cDelimiter in cList
   LOCAL aList := {}       // Define an empty array
   LOCAL nSize
   
   DEFAULT cDelimiter TO ","
   nSize := Len( cDelimiter )

   // Loop while there are more items to extract
   DO WHILE ( nPos := AT( cDelimiter, cList )) != 0
   
      // Add the item to aList and remove it from cList
      AADD( aList, SUBSTR( cList, 1, nPos - 1 ))
      cList := SUBSTR( cList, nPos + nSize )
      
   ENDDO
   AADD( aList, cList )                         // Add final element         
   RETURN ( aList )                             // Return the array

   