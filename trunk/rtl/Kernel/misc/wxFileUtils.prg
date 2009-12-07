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
 *---------------------------------------------------------------------------*/
#define XBASE_CC

#include "simpleio.ch"
#include "common.ch"
#include "wxWebFramework.ch"

/*
 * 18/11/2006 17:25:37
 * Extrai a extensao de um nome do arquivo
 */   
FUNCTION ExtractFileExt( cFileName )
   LOCAL d := '.'
   LOCAL p

   cFileName := ExtractFileName( cFileName )   
   p := At( d, cFileName )
   
   IF p <> 00 THEN ;
      cFileName := Subst( cFileName, p+1 )
   
   RETURN cFileName   
   
/*
 * 18/11/2006 17:25:37
 * Extrai o path do nome do arquivo
 */   
FUNCTION ExtractFilePath( cFileName )
   LOCAL d := HB_OSPATHSEPARATOR()
   LOCAL p

   p := RAt( d, cFileName )
   
   IF p <> 00 THEN ;
      cFileName := Subst( cFileName, 1, p )
   
   RETURN cFileName   
   
/*
 * Ajusta o PATH passado como parametro e asegura que o delimitador de PATHs
 * é o ultimo caracter do esquema. Esta funcao troca os caracteres '/' e '\' para
 * o delimitador de PATH correto conforme o sistema operacional em uso.
 * 
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

/*
 * Ajusta o PATH passado como parametro e asegura que o delimitador de PATHs
 * é o ultimo caracter da string passada. Esta funcao nao altera nenhum dos 
 * caracteres '\' ou '/' existentes na string passada como argumento.
 * 
 * 21/11/2006 17:49:33
 */
FUNCTION WebAdjustPath( cPath, cDefaultPathIFEmpty )
   LOCAL x,d,i
   
   x := Alltrim( cPath )
   
   if Empty(x) then;
      x := Alltrim( cDefaultPathIFEmpty)
      
   d := '/'

   IF Empty(x) THEN;
      RETURN x
      
   IF !( Right(x,l) == D ) THEN;
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
   
   sprintf( s, "%s", HB_OSPATHSEPARATOR );
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