/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 7/12/2006 10:09:30
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxFileUtils.prg
 *                            
 *  Funções para manipulação de nomes-de-arquivos
 *
 *
 * @define FUNCS AdjustPath() ExtractFileExt() ExtractFileName() ExtractFileNameEx()
 * @define FUNCS ExtractFilePath() WebAdjustPath()
 *
 * @see @request(FUNCS)
 *---------------------------------------------------------------------------*/
#define XBASE_CC

#include "simpleio.ch"
#include "common.ch"
#include "wxWebFramework.ch"

/**
 * ExtractFileName( <FileName> ) -> cFileName
 *
 * Extrai o nome completo do arquivo com sua extensão à partir de uma string passada
 * como argumento.
 *
 * @<cFileName>  A string contendo o nome do arquivo que deverá ser extraido.
 *
 * @see @request(FUNCS)
 * 18/11/2006 17:25:37
 */
FUNCTION ExtractFileName( cFileName )
   LOCAL d := HB_OSPATHSEPARATOR()
   LOCAL p

   p := RAt( d, cFileName )
   
   IF p <> 00 THEN ;
      cFileName := Subst( cFileName, p+1 )
   
   RETURN cFileName   
   
/**
 * ExtractFileNameEx( <cFileName> ) -> cName
 *
 * Retorna apenas o nome do arquivo contido em cFileName juntamente com seu PATH
 * (se estiver disponível) mas sem extensão.
 *
 * @<cFileName>  A string contendo o nome do arquivo que será processado.
 *
 * <sample>
 * #include "wxweb.ch"
 *
 * FUNCTION main()
 *
 *       cDbf := 'c:\data\estoque.dbf'
 *       cCdx := ExtractFileNameEx( cDbf ) + '.cdx'
 *
 *       USE ( cDBF ) NEW ALIAS est
 *
 *       IF !File( cCdx )
 *          INDEX ON ...
 *       End
 *
 *    RETURN nil
 * </sample>
 *
 * @see @request(FUNCS)
 *
 * 18/11/2006 17:25:37
 */
FUNCTION ExtractFileNameEx( cFileName )
   LOCAL d := '.'
   LOCAL p

   cFileName := ExtractFileName( cFileName )   
   p := At( d, cFileName )
   
   IF p <> 00 THEN ;
      cFileName := Subst( cFileName, 1, p-1 )
   
   RETURN cFileName      

/**
 * ExtractFileExt( <cFileName> ) -> cExt
 *
 * Retorna apenas a extensão à partir de uma string contendo o nome do
 * arquivo. Quaisquer informações sobre PATH ou NOME serão descartadas e inclusive
 * o caracter de ponto que separa o nome do arquivo de sua extensão não será
 * incluido no retorno desta função.
 *
 * @see @request(FUNCS)
 * 18/11/2006 17:25:37
 */
FUNCTION ExtractFileExt( cFileName )
   LOCAL d := '.'
   LOCAL p

   cFileName := ExtractFileName( cFileName )   
   p := At( d, cFileName )
   
   IF p <> 00 THEN ;
      cFileName := Subst( cFileName, p+1 )
   
   RETURN cFileName   
   
/**
 * ExtractFilePath( <cFileName> ) -> cPath
 *
 * Extrai informações sobre  PATH à partir de uma string fornecida como
 * argumento incluindo o caracter separador "\" ou "/". Quaisquer informações
 * disponiveis sobre o nome do arquivo serão descartadas.
 *
 * @see @request(FUNCS)
 * 18/11/2006 17:25:37
 */
FUNCTION ExtractFilePath( cFileName )
   LOCAL d := HB_OSPATHSEPARATOR()
   LOCAL p

   p := RAt( d, cFileName )
   
   IF p <> 00 THEN ;
      cFileName := Subst( cFileName, 1, p )
   
   RETURN cFileName   
   
/**
 * AdjustPath( <cPath>, [<cDefault>] ) -> cPath
 * Ajusta o PATH passado como parametro e asegura que o delimitador de PATHs
 * seja o ultimo caracter na string de retorno. Esta funcao troca os caracteres '/'
 * e '\' para o delimitador de PATH correto conforme o sistema operacional em uso.
 *
 * @<cPath>    A string contendo o PATH à ser analisado.
 *
 * @<cDefault> Valor a ser retornado caso seja especificado e nenhuma informação
 *             esteja disponivel em <cPath>.
 *
 * @see @request(FUNCS)
 * 18/11/2006 17:20:37
 */
FUNCTION AdjustPath( cPath, cDefaultPathIFEmpty )
   LOCAL x,d
   
   x := Alltrim( cPath )
   
   if Empty(x)
      if Valtype(cDefaultPathIFEmpty) == 'C' 
         x := Alltrim(cDefaultPathIFEmpty)
      else
         return x
      end
   end
      
   IF Empty(x) THEN;
      RETURN x

   d := HB_OSPATHSEPARATOR()
         
   x := StrTran( x, '/', d )
   x := StrTran( x, '\', d )   

   IF !( Right(x, 1 ) == D ) THEN;
      x += D
               
   RETURN x

/**
 * WebAdjustPath( <cPath>, [<cDefault>] ) -> cPath
 *
 * Ajusta o PATH passado como parametro e asegura que a barra normal "/" seja o
 * ultimo caracter da string passada. Esta funcao nao altera nenhum dos
 * caracteres '\' ou '/' existentes na string passada como argumento.
 *
 * @<cPath>    A string contendo o PATH à ser analisado.
 *
 * @<cDefault> Valor a ser retornado caso seja especificado e nenhuma informação
 *             esteja disponivel em <cPath>.
 *
 * @see @request(FUNCS)
 * 21/11/2006 17:49:33
 */
FUNCTION WebAdjustPath( cPath, cDefaultPathIFEmpty )
   LOCAL x,d
   
   x := Alltrim( cPath )
   
   if Empty(x) then;
      x := Alltrim( cDefaultPathIFEmpty)
      
   d := '/'

   IF Empty(x) THEN;
      RETURN x
      
   IF !( Right(x,1) == D ) THEN;
      x += D
               
   RETURN x   

#pragma BEGINDUMP

#include "hbapi.h"
#include "hbapiitm.h"
#include <windows.h>

char *wxAdJustPath( char *Path, char *Default );
char *wxWebAdjustPath( char *Path, char *Default );

char *wxAdJustPath( char *Path, char *Default )
{
   int x,i;
   char d;
   char *s;   
   
   x = strlen(Path);
   
   if (x<1) 
   {
      Path = Default;
      x = strlen(Path);
   }

   if (x<1)
      return NULL;
    
   /* Removemos os espaços iniciais se houver */
   while (*Path == ' ')
         Path ++;
   
   /* Removemos os espaços finais se houver */
   while ((x>0) &&
          (Path[x-1]==' '))
         x --;
           
   if (x<1)
      return NULL;
    
   s = (char *) hb_xgrab(x+2);
   s[0]=0;
   
   sprintf( s, "%s", HB_OS_PATH_DELIM_CHR_STRING );
   d = s[0];
   
   memmove( s, Path, x );
   s[x] = '\0';
    
   for (i=0;i<x;i++)
   {
      if ((s[i] == '/') ||
          (s[i] == '\\'))
         s[i] = d;
   }   

   if (s[x-1] != d )
   {
      s[x] = d; x++;
      s[x] = '\0';
   }            
   return s;
}

char *wxWebAdjustPath( char *Path, char *Default )
{
   int x;
   char d;
   char *s;   
   
   x = strlen(Path);
   
   if (x<1) 
   {
      Path = Default;
      x = strlen(Path);
   }

   if (x<1)
      return NULL;
    
   /* Removemos os espaços iniciais se houver */
   while (*Path == ' ')
         Path ++;
   
   /* Removemos os espaços finais se houver */
   while ((x>0) &&
          (Path[x-1]==' '))
         x --;
           
   if (x<1)
      return NULL;
    
   s = (char *) hb_xgrab(x+2);
   s[0]=0;
   
   d = '/';
   
   memmove( s, Path, x );
   s[x] = '\0';
    
   if (s[x-1] != d )
   {
      s[x] = d; x++;
      s[x] = '\0';
   }            
   return s;
}

#pragma ENDDUMP