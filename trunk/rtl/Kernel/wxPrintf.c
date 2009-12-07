/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 26/07/2008 - 08:01:46
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxPrintf.c
 *                            
 *  Funções formatação de string, para obter um resultado semelhante às funções
 *  em C ou PHP... 
 *
 *---------------------------------------------------------------------------*/
#define USES_WXWEB

#ifdef USES_WXWEB
   #include <wxweb.h>
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapierr.h"
#include "hbstack.h"

#ifdef HB_OS_WIN
   #include <io.h>
#endif
#include <stdlib.h>
#ifndef max
	#define max( a, b ) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifdef USES_WXWEB
   #include <wxMemory.h>
   #include <wxConnManager.h>
   #include <wxTrace.h>
#endif

#define NONE      0
#define OK        1
#undef FAILURE  
#define FAILURE   2

/* Uma struct simples para nos ajudar nos parametros! */
typedef struct _PRINTF_
{
   const char *Mask;
   char *Buffer;
   char *Result;
   
   ULONG msk_len;  // size of mask
   ULONG out_len;  // size of result
   ULONG cap_len;  // capacity  
   
   int argp;
   int error;
   
} TPrintInfo;

typedef TPrintInfo *PPrintInfo;

extern void hb_conOutAlt( const char * pStr, ULONG ulLen );

/*
 *
 * 26/07/2008 - 11:16:34
 */
static
void printf_add_str( PPrintInfo pInfo, char *text, ULONG request_len )
{
   if (!request_len)
      return;
      
   // Precisa realocar memoria?
   if (pInfo->out_len+request_len > pInfo->cap_len)
   {
      pInfo->cap_len += request_len;
      pInfo->Result   = (char *) hb_xrealloc( pInfo->Result, pInfo->cap_len+1 );
      pInfo->Buffer   = pInfo->Result + (pInfo->out_len);
      pInfo->out_len += request_len;
   } else {
      pInfo->out_len += request_len;
   } 

   memmove( pInfo->Buffer, text, request_len );
   pInfo->Buffer += request_len;
   return;    
}

// 26/07/2008 - 11:32:47
static
void printf_add_conv( PPrintInfo pInfo, PHB_ITEM pItem )
{        
   char flag = 0;
   int width = 0;
   int precision = 0;
   char specifier = '\0';
   char m = '\0';
   char c;
   char mask[20];
   const char *t1;
   const char *t2;
   
   char * cValue;
   double dValue;
   ULONG  Length;
   
   /*
    * Procura por uma string de conversao com o formato:
    *        0       1        2         3      4
    *     %[flags][width][.precision][length]specifier
    *
    */  
   t1 = pInfo->Mask;
   mask[0] = '\0';

   pInfo->Mask ++;
   pInfo->msk_len--;
   
   /*
    * Se nao tem nenhum item de argumento, e o proximo caracter de escape nao for
    * o "%", entao temos que abortar a rotina... indicando erro de argumento! 
    */   
   if (pInfo->msk_len &&
       // pInfo->Mask[0] != '%' &&
      !pItem)
   {  
      pInfo->error =  FAILURE;
      return;
   }

   /* processamos a string como um todo */
   while (pInfo->error == NONE   && 
          pInfo->msk_len         && 
          pInfo->Mask[0] )
   {   
      c = pInfo->Mask[0];
      
      // setou o flag?
      if (strchr( "-+ #0", c ))
      {
         flag = c; c = 'A'; 
      }

      // setar o width?
      if (strchr( "1234567890", c ))
      {
         char *t = (char *) hb_xgrab(15);
         char *s = t;
                  
         do
         {
            *t = c; t++;
            pInfo->Mask ++; pInfo->msk_len--;
            c = pInfo->Mask[0];
            
         } while (pInfo->msk_len && strchr( "1234567890", c ));

         *t = '\0';
         width = atoi( s );                  
         hb_xfree(s);
      }

      // setar precision?
      if (c == '.')
      {         
         char *t = (char *) hb_xgrab(15);
         char *s = t;
                  
         pInfo->Mask ++; pInfo->msk_len--; c = pInfo->Mask[0];

         while (pInfo->msk_len && strchr( "1234567890", c )) 
         {
            *t = c; t++;            
            pInfo->Mask ++; pInfo->msk_len--;
            c = pInfo->Mask[0];        
         } 

         *t = '\0';
         precision = atoi( s );                  
         hb_xfree(s);
         
         c = pInfo->Mask[0];        
      }
      
      if (c == 'l' && strchr( "idouxX", pInfo->Mask[1] ))
         m = c;
      if (c == 'h' && strchr( "idouxX", pInfo->Mask[1] ))
         m = c;
      if (c == 'L' && strchr( "eEfgG", pInfo->Mask[1] ))
         m = c;
      
      // Chegou no tipo?
      if (strchr( "cdieEfgGosuxXpn%", c ))
      {
         specifier = c;
         pInfo->Mask ++;
         pInfo->msk_len--;
         
         t2 = pInfo->Mask;
         
         switch( specifier )
         {
            case '%':
            {
               printf_add_str( pInfo, "%", 1L );
               break;
            }   
            case 'c':   
            //  O argumento é tratado como um inteiro, e mostrado como o caractere ASCII correspondente. 
            {
               char s[2];
               memset( s, 0, 2 );
               
               if (HB_IS_STRING( pItem ))
               {
                  const char *t = hb_itemGetCPtr( pItem );
                  s[0] = ((t) ? t[0] : 0); 
               } else if( HB_IS_NUMERIC( pItem ) )
               {
                  s[0] = (char) hb_itemGetNI( pItem );
               }
               
               printf_add_str( pInfo, s, 1L );
               break;
            }   
            case 's':
            {
               Length = t2-t1;
               width  = max( hb_itemGetCLen( pItem ), (ULONG) width );
               cValue = (char *) hb_xgrab( width + 1 );
               
               memmove( mask, t1, Length );
               mask[Length] = '\0';
               
               cValue[0] = '\0';
               Length = sprintf( cValue, mask, hb_itemGetCPtr( pItem ) );               
               printf_add_str( pInfo, cValue, Length );
               hb_xfree( cValue );
               break;               
            }               
            case 'p':
            {
               char s[9];               
               s[0] = '\0';
               sprintf( s, "%p", hb_itemGetPtr( pItem ) );                
               printf_add_str( pInfo, s, 8);
               break;
            }               
               
               /*
                * Separamos aqui as operações sobre inteiros 
                */         
            case 'i':
            case 'd':  
            // O argumento é tratado como um INTEIRO, e mostrado como um número decimal com sinal.            
            case 'o':
            // O argumento é tratado com um INTEIRO, e mostrado como un número octal. 
            case 'u':
            // O argumento é tratado com um INTEIRO, e mostrado como um número decimal sem sinal.
            case 'x':
            // O argumento é tratado como um INTEIRO, e mostrado como um número hexadecimal (com as letras minúsculas).
            case 'X':
            // O argumento é tratado como um INTEIRO, e mostrado como um número hexadecimal (com as letras maiúsculas).  
            {
               Length = t2-t1;
               width  = ((width) ? width : 32 );
               cValue = (char *) hb_xgrab( width + 1 );
               
               memmove( mask, t1, Length );
               mask[Length] = '\0';
               cValue[0] = '\0'; 
               
               if (m == '\0')
                  Length = sprintf( cValue, mask, (int) hb_itemGetNI( pItem ));
               if (m == 'l')
                  Length = sprintf( cValue, mask, (LONG) hb_itemGetNL( pItem )); // como LONG ???
               if (m == 'h')
                  Length = sprintf( cValue, mask, (LONG) hb_itemGetNL( pItem )); // como LONG ???
               
               printf_add_str( pInfo, cValue, Length );
               hb_xfree( cValue );
               break;
            }
            
               /*
                * Separamos aqui as operações com numeros flutuantes
                */
            case 'e' :
            // O argumento é tratado como notação científica (e.g. 1.2e+2).  
            case 'E' :
            // O argumento é tratado como notação científica (e.g. 1.2e+2).  
            case 'f' :
            // O argumento é tratado como um float, e mostrado como um número de ponto flutuante.
            case 'F' :
            // O argumento é tratado como um float, e mostrado como um número de ponto flutuante. 
            {
               Length = t2-t1;
               width  = ((width) ? width : 64 );
               dValue = (double) hb_itemGetND( pItem );     // converting double --> float ???
               cValue = (char *) hb_xgrab( width + 1 );
               
               memmove( mask, t1, Length );
               mask[Length] = '\0';
               
               sprintf( cValue, mask, dValue );
               printf_add_str( pInfo, cValue, strlen( cValue ) );
               hb_xfree( cValue );
               break;
            }
                     
            default:
               break;               
         }
         break;
      } else {
         pInfo->Mask ++;
         pInfo->msk_len--;
      }
   }    
}     
      
/*    
 * Implementação de printf() para Harbour/xHarbour.
 *
 * TODO: Creio que uma ótima melhoria seria somar o tamanho de todos os argumentos
 * e criar um buffer já pre-determinado com um tamanho +/- necessário para evitar
 * tantas realocações de memoria como ocorre nestes casos.    
 * 26/07/2008 - 08:17:42
 */   
static
char *wx_printf( ULONG *Length )
{     
   PPrintInfo pInfo;
   char c;
   char *result;
   ULONG request_len;

   *Length = 0L;
   
   // o primeiro argumento tem que ser uma string!   
   if ( !ISCHAR(1) )
      return NULL;
        
   /* Iniciamos a memoria */
   pInfo = (PPrintInfo) hb_xgrab( sizeof(TPrintInfo) );
   memset( pInfo, 0, sizeof(TPrintInfo) );
   
   pInfo->Mask   = hb_parcx(1);
   pInfo->msk_len= hb_parclen(1);
   
   pInfo->Result = (char *) hb_xgrab( pInfo->msk_len+1 );
   pInfo->Buffer = pInfo->Result;
   pInfo->cap_len= pInfo->msk_len;

   pInfo->argp ++;

   /* processamos a string como um todo */
   while (pInfo->error == NONE   && 
          pInfo->msk_len         && 
          pInfo->Mask[0] )
   {
         c = pInfo->Mask[0];
         
         switch (c)
         {
            case '%':
            {
               /*
                * Se nao tem nenhum item de argumento, e o proximo caracter de escape nao for
                * o "%", entao temos que abortar a rotina... indicando erro de argumento! 
                */   
               if (pInfo->Mask[1] == '%')
               {  
                  printf_add_str( pInfo, "%", 1L );
                  pInfo->Mask    += 2;
                  pInfo->msk_len -= 2;
                  continue;
               }
               
               pInfo->argp ++;
               printf_add_conv( pInfo, hb_param( pInfo->argp, HB_IT_ANY ));
               continue;
            }
               
            default:
            {               
               // Precisa realocar memoria?
               request_len = 1L;
               
               if (pInfo->out_len+request_len > pInfo->cap_len)
               {
                  pInfo->cap_len += request_len;
                  pInfo->Result   = (char *) hb_xrealloc( pInfo->Result, pInfo->cap_len+1 );
                  pInfo->Buffer   = pInfo->Result + (pInfo->out_len);
                  pInfo->out_len += request_len;
               } else {
                  pInfo->out_len += request_len;
               } 
               
               /*
                * É um caracter simples ou é uma sequencia de escape a ser add?
                * Links relacionados:
                *    http://docs.sun.com/app/docs/doc/816-0220/6m6nkorp8?a=view
                *    http://docs.sun.com/app/docs/doc/816-0213/6m6ne387j?a=view
                */
               if (c == '\\')
               {
                  pInfo->Mask ++;
                  pInfo->msk_len--;
                  
                  if (!pInfo->msk_len)
                     continue;
                  
                  c = pInfo->Mask[0];
                  
                  switch(c)
                  {
                     case '\\':
                        c = '\\';
                        break;          
                     case '\0':
                        c = '\0';
                        break;          
                     case 'a':
                        c = '\a';
                        break;          
                     case 'b':
                        c = '\b';
                        break;          
                     case 'f':
                        c = '\f';
                        break;          
                     case 'n':
                        c = '\n';
                        break;          
                     case 'r':
                        c = '\r';
                        break;          
                     case 't':
                        c = '\t';
                        break;          
                     case 'v':
                        c = '\v';
                        break;          
                  }                  
               }
               
               pInfo->Buffer[0] = c;
               pInfo->Buffer ++;

               pInfo->Mask ++;
               pInfo->msk_len--;
               break;
            }
         }      
   }
   pInfo->Result[pInfo->out_len] = '\0'; 
   
   result  = pInfo->Result;
   *Length = pInfo->out_len;

   /* Liberamos a memoria alocada */      
   hb_xfree( pInfo );
   return result;
}

#ifndef USES_WXWEB
HB_FUNC( PRINTF )
{
   char *Text;
   ULONG Size;
   
   Text = wx_printf( &Size );
   
   hb_conOutAlt( Text, Size );
   hb_retnl( Size );   
   hb_xfree( Text );
   return;   
}
#else
/*
 * sprintf( mask, arg1, argN ... ) -> nSize 
 * Gera uma string formatada baseada em mask, processando os arqumento informados
 * e a envia direto para o dispositivo de uma saída. Retorna a quantidade de bytes
 * gravados.  
 * 26/07/2008 - 22:20:46
 */
HB_FUNC( PRINTF )
{
   PConnection pClientConn;
   char *Text;
   ULONG Size;
   
   pClientConn = wxGetClientConnection();
   
   if (!pClientConn)
   {
      hb_retni(-1);
      return;
   }   
   
   Text = wx_printf( &Size );
   
   if (wxConnection_SendText( pClientConn, (BYTE *)Text, Size ) == FAILURE)
      hb_retni(-1);
   else
      hb_retnl( Size );   

   if (Text)
      hb_xfree( Text );
   return;   
}
#endif

/* 
 * sprintf( mask, arg1, argN ... ) -> cResult
 * Retorna uma string produzida de acordo com a string de formatação format . 
 * 26/07/2008 - 22:15:52
 */
HB_FUNC( SPRINTF )
{
   char *Text;
   ULONG Size;
   
   Text = wx_printf( &Size );
   hb_retclenAdopt( Text, Size );
   return;   
}
