/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 19/11/2006 09:55:50
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxmemory.h
 *                            
 *  Rotinas diversas para controle e gerenciamento de memoria
 *
 *---------------------------------------------------------------------------*/
#include <wxweb.h>
#include "hbapi.h"
#include "hbapifs.h"
#include "hbapiitm.h"
#include <ctype.h>
#include <wxTrace.h>
  
char *xStrDup(const char *z);
char *xStrNDup(const char *z, int n);
char *xStrNew(int len);
char *xStrRealloc(char *z, int len);
char *xStrReadFile(char *s, ULONG * BytesRead );

void * wxAlloc(long len);
void   wxRelease(void *z);

char *strxaddcount(char *dst,ULONG * len, const char *src, ULONG BufferSize );
char *strxadd(char *dst,ULONG * len, const char *src, ...);
char *my_strxmov(char *dst,const char *src, ...);   

int SameText( const char *s1, const char * s2 );

/*
 * 19/11/2006 09:58:31
 * Make a copy of a string in memory obtained from hb_xgrab()
 */
char *xStrDup(const char *z)
{
  char *zNew;
  int Size;
  
  if (!z) 
     return 0;
     
  Size = strlen(z);
  zNew = ((Size < 0) ? NULL : (char *) hb_xgrab(Size+1));
  
  if (zNew)
  {
     strcpy(zNew, z);
     zNew[ Size ] = '\0';  // Finaliza a string com zero! 17/07/2008 - 20:07:50
  }   
  return zNew;
}

/*
 * 19/11/2006 09:58:59
 * Make a copy of a string in memory obtained from hb_xgrab() with fixed length
 */
char *xStrNDup(const char *z, int n)
{
  char *zNew;
  if (z==0)
     return 0;
     
  zNew = (char *) hb_xgrab(n+1);

  if (zNew)
  {
    memcpy(zNew, z, n);
    zNew[n] = 0;
  }
  return zNew;
}

/*
 * 19/11/2006 10:03:49
 * Make a new string with fixed length and fill the first value with zero
 */
char *xStrNew(int len)
{
  char *zNew;
  if (len<1)
     return 0;
     
  zNew = (char *) hb_xgrab(len+1);

  if (zNew)
    zNew[0] = 0;

  return zNew;
}

/*
 * 19/11/2006 10:03:49
 * Make a new string with fixed length and fill the first value with zero
 */
char *xStrNewBuff(int len, const char *Buff)
{
  char *zNew;
  if (len==-1)
     len = strlen( Buff );
     
  zNew = (char *) hb_xgrab(len+1);

  if (!zNew)
     return zNew;
  
  memmove( zNew, Buff, len );    
  zNew[len] = 0;
  return zNew;
}

/*
 * 19/11/2006 10:06:33
 * Make a new string with fixed length and fill the first value with zero
 */
char *xStrRealloc(char *z, int len)
{
   return (char *)hb_xrealloc( z, len);
}

/*
 * Create a new buffer!
 * 11/12/2006 09:07:11
 */
void * wxAlloc(long len)
{
   return (void *) hb_xgrab(len);
}
/*
 * Delete a current buffer
 * 11/12/2006 09:04:52
 */
void wxRelease(void *z)
{
   if (z) hb_xfree(z);
}

/*
 * Duplica a string passada como argumento para um nobo buffer e converte-a para 
 * maiusculas!
 * 21/07/2008 - 07:38:42
 */
char *xStrUpperNew( char *src, int len )
{
  int i;
  char *zNew;
 
  if (len==-1)
     len = strlen( src );
     
  zNew = (char *) hb_xgrab(len+1);

  if (!zNew)
     return zNew;
  
  for (i=0;i<len;i++)
      zNew[i] = toupper( src[i] );

  zNew[len] = 0;
  return zNew;
}


/*
 * Copia o conteudo da string passada como argumento para o buffer de destino e 
 * converte-a para maiusculas durante esta opera‡Æo!
 * 21/07/2008 - 07:38:42
 */
void xStrUpperCopy( char *dst, char *src, int len )
{
  int i;
 
  if (len==-1)
     len = strlen( src );
     
  if (!dst)
     return;
  
  for (i=0;i<len;i++)
      dst[i] = toupper( src[i] );

  dst[len] = 0;
}

/*
 * Converte uma sequencia para maiusculas!
 * 26/12/2006 14:41:57
 */
void xStrUpper( char *src, int len)
{
   int i;
   
   if (len == -1)
      len = strlen( src );
   
   for (i=0;i<len;i++)
      src[i] = toupper( src[i] );
}

/*
 * Converte uma sequencia para minusculas!
 * 26/12/2006 14:52:15
 */
void xStrLower( char *src, int len)
{
   int i;
   
   if (len == -1)
      len = strlen( src );
   
   for (i=0;i<len;i++)
      src[i] = tolower( src[i] );
}

char *xStrMove(char *dst,const char *src, ...)
{
  va_list pvar;

  va_start(pvar,src);
  while (src != ((char *)0))
  {
    while ((*dst++ = *src++)) ;
    dst--;
    src = va_arg(pvar, char *);
  }
  va_end(pvar);
  *dst = 0;			/* there might have been no sources! */
  return dst;
}

char *xStrAdd(char *dst,ULONG * len, const char *src, ...)
{
  va_list pvar;
  va_start(pvar,src);

//  HB_TRACE(HB_TR_DEBUG, (" strxadd('%s' %p,%lu)",dst,dst,*len));

  if (!( *len == 00 ))
  {
     ULONG i;
     for (i=0;i<(*len);i++,dst++)
         ;
     // dst--;
  }
  
  while (src != ((char *) 0))
  {
    while ((*dst++ = *src++)) *len = *len +1;
    dst--;
    src = va_arg(pvar, char *);
  }
  va_end(pvar);
  *dst = 0;			/* there might have been no sources! */
//  HB_TRACE(HB_TR_DEBUG, ("  --> '%s' Len -> %lu",dst,*len));
  return dst;
}

char *xStrAddCount(char *dst,ULONG * len, const char *src, ULONG BufferSize )
{
  ULONG i=0;
  
//  HB_TRACE(HB_TR_DEBUG, (" strxaddcount('%s'/%p,%lu,'%s',%lu)",dst,dst,*len,src,BufferSize));
  if (BufferSize == 00)
    BufferSize = strlen(src);
    
  if (!( *len == 00 ))
  {
     ULONG i;
     for (i=0;i<(*len);i++,dst++)
         ;
     //dst--;
  }

  while ((*dst++ = *src++))
  {
        i++;        
        if (i>BufferSize)
           break;
        *len = *len +1;
  }
  dst--;
  
  *dst = 0;			/* there might have been no sources! */
 // HB_TRACE(HB_TR_DEBUG, ("  --> '%s' Len -> %lu",dst,*len));
  return dst;
}

/*
 * Lˆ um arquivo do disco para a memoria e retorna uma string com o conteudo do
 * mesmo... no segundo parametro ela retorna o tamanho de bytes lidos do arquivo. 
 *
 * O primeiro parametro ‚ o nome do arquivo que deve ser lido do hd 
 * 19/11/2006 09:58:59
 */
char *xStrReadFile(char *s, ULONG * BytesRead )
{
   int fh;
   char *Buff; 
   ULONG nEnd, nStart, Length;

   HB_TRACE( HB_TR_DEBUG, (" xStrReadFile( '%s' )", s ));
   *BytesRead = 0; // 31/07/2008 - 16:35:30
   
   if (!hb_spFile( ( BYTE * ) s, NULL ))
   {
      HB_TRACE( HB_TR_DEBUG, ("  Arquivo nao existe: %s",  s ));
      return NULL;
   } else { 
      HB_TRACE( HB_TR_DEBUG, ("  Arquivo existe: %s",  s ));
   }

   fh   = hb_fsOpen( ( BYTE * ) s , 0  ); // 0 -> FO_READ
   HB_TRACE( HB_TR_DEBUG, (" HANDLE: %d",  fh ));

   nEnd = hb_fsSeek( fh, 0 , 2 );
   nStart = hb_fsSeek( fh , 0 , 0 );

   HB_TRACE( HB_TR_DEBUG, (" Start .: %lu",  nStart ));
   HB_TRACE( HB_TR_DEBUG, (" End ...: %lu",  nEnd ));
   Length = nEnd - nStart;

   Buff = (char *) hb_xgrab( Length+1 ); 

   * BytesRead = hb_fsReadLarge( fh , ( BYTE * ) Buff, Length );
   Buff[ * BytesRead ] = '\0';
   
   hb_fsClose( fh );
   return Buff;
}

int SameText( const char *s1, const char * s2 )
{
   int l = strlen(s1);
   int l2= strlen(s2);
   
   if (l != l2)
      return 0;
   
   for ( l2 = 0; l2 < l; l2 ++ )
   {
      if (toupper(s1[l2]) != toupper(s2[l2] ))
         return 0;
   }   
   return 1;
}

/*
 * Acha uma TAG dentro da STRING fornecida como argumento, ignorando letras
 * maiúsculas e minúsculas. Exemplo de uso:
 *
 * wxLocateTag( cString, "</head>" )
 *
 * 1/1/2007 18:26:06
 */
HB_FUNC( WXLOCATETAG )
{
   long Result = 0;
   int i, l = hb_parclen(2);
   char a,b,c, *Text, *Tag, *Buff;

   hb_retni(0);
   
   if ((hb_parclen(1)<1) || (hb_parclen(2)<1))
      return;
   
   Text  = hb_parcx(1);
   Tag   = hb_parcx(2);
   Buff  = Text;
   
   while (Text)
   {
      Text = strchr( Text, Tag[0] );
      
      if (!Text) 
         break; 
      
      /* Testa se é o item que queremos! */
      c = 1;
      
      for (i=0;i<l;i++)
      {      
         a = Text[i];
         b = Tag[i];
         
         if (a == 0)
         {
            c = 0;         
            break;
         }
      
         a = toupper(a);
         b = toupper(b);
         
         if ( a != b )
         {
            c = 0;         
            break;
         }
      }
      
      if (!c)
      {
         Text ++;
         continue;
      }
      
      /*
       * Opa... ele achou, tudo confere! Entao computamos a posicao na memoria
       * e retornamos para ele a posicao correta da substring!
       * 1/1/2007 18:43:00
       */
      Result = (long) (Text - Buff);
      Result += 1L;
      break;
   }
      
   hb_retnl( Result );
}


/*
 * Pesquisa uma determinada regiao da memoria por uma string e reporta sua posicao
 * ou NULL se nada for encontrado. Seria o mesmo que strstr() porem trabalhando com
 * strings que aceitam NULL dentro de si.
 * 09/11/2008 - 17:17:58
 */
char *wxMemFind( char *buffer, ULONG buffer_len, 
                  const char *findstr, const ULONG findstr_len)
{
   char *e,*c;
   
   if (!buffer)  return NULL;
   if (!findstr) return NULL;

   if (buffer_len < 1) return NULL;
   if (findstr_len< 1) return NULL;

   if (buffer_len < findstr_len) return NULL;
   
   c = buffer;
   e = &buffer[ buffer_len-1 ];
   
   /* Faça enquanto nao achar o fim da string */
   for (; c <= e; c++, buffer_len-- )
   {
       /* O primeiro caracter confere! */  
       if (*c == *findstr)
       {
          /* Ops... o tamanho da string que temos nao é o suficiente? Ignore entao! */
          if (buffer_len < findstr_len)
             break;  
          /* Se achar os bytes desejados, retornamos a posicao na memoria! */
          if ( memcmp( c+1, findstr+1, findstr_len-1 ) == 00 )
             return c;  
       }
   }
   return NULL;
}