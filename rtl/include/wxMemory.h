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

#ifndef TWEB_MEMORY
   #define TWEB_MEMORY
   
   #include <stdarg.h>
   #include <ctype.h>
   
   extern char *xStrDup(const char *z);
   extern char *xStrNDup(const char *z, int n);
   extern char *xStrNew(int len);
   extern char *xStrNewBuff(int len, const char *Buff);
   extern char *xStrRealloc(char *z, int len);
   extern char *xStrMove(char *dst,const char *src, ...);
   extern void  xStrLower( char *src, int len);

   extern void  xStrUpperCopy( char *dst, char *src, int len );
   extern void  xStrUpper( char *src, int len);
   extern char *xStrUpperNew( char *src, int len );   
   
   extern char *xStrReadFile(char *s, ULONG * BytesRead );   
   
   extern void *wxAlloc(long len);
   extern void  wxRelease(void *z);
   
   extern int SameText( const char *s1, const char * s2 );

   #define wxDispose    wxRelease

   extern char *xStrAddCount(char *dst,ULONG * len, const char *src, ULONG BufferSize );
   extern char *xStrAdd(char *dst,ULONG * len, const char *src, ...);

   extern char *wxMemFind( char *buffer, ULONG buffer_len, 
                  const char *findstr, const ULONG findstr_len);
#endif
