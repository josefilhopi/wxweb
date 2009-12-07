/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado C ..: 09/07/2008 - 17:01:19
 *
 *  Revisado C++.: 08/12/2006 - 08:09:11
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxSerialize.c
 *                            
 *  Funções para manipulação da conexão com o cliente
 *
 *---------------------------------------------------------------------------*/

#include <wxweb.h>
#include "hbvmopt.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapifs.h"
#include "hbapicls.h"
#include "hbmath.h"
#include "hbstack.h"
#include "hbvm.h"

#ifdef HB_OS_WIN
   #include <io.h>
   #include <windows.h>
#endif

#include <wxTrace.h>
#include <wxMemory.h>
#include <wxSerialize.h>

#include <wxMT.h>

// Adicionado em 31/07/2008 - 18:17:50
HB_FUNC_EXTERN( __OBJGETVALUEDIFF );
HB_FUNC_EXTERN( __CLSINST );  

static PHB_DYNS pGetValues = NULL;
 
extern HB_EXPORT UINT hb_clsGetHandleFromName( char *szClassName );

/*
 * Converte um inteiro para uma string
 * 16/12/2006 08:51:31
 */
WX_RES Int2Str( LONG lValue, char *OutPut, int *OutPutLength )
{
   if ((lValue >= 0L) && 
       (lValue <= 255L))
   {
      OutPut[ 0 ] = ( char )( lValue );
      OutPut[ 1 ] = '\0';            
      if (OutPutLength) *OutPutLength = 1;
      
   } else {
      OutPut[ 0 ] = ( char )( ( lValue & 0x000000FF ) );
      OutPut[ 1 ] = ( char )( ( lValue & 0x0000FF00 ) >> 8 );
      OutPut[ 2 ] = ( char )( ( lValue & 0x00FF0000 ) >> 16 );
      OutPut[ 3 ] = ( char )( ( lValue & 0xFF000000 ) >> 24 );
      
      if (OutPutLength) *OutPutLength = 4;
   }
   return TRUE;
} 

LONG Str2Int( char *InPut, int Length )
{
   return (LONG) HB_MKLONG( ( Length >= 1 ) ? ( BYTE ) InPut[ 0 ] : 0,
                            ( Length >= 2 ) ? ( BYTE ) InPut[ 1 ] : 0,
                            ( Length >= 3 ) ? ( BYTE ) InPut[ 2 ] : 0,
                            ( Length >= 4 ) ? ( BYTE ) InPut[ 3 ] : 0 );
}

/*
 * Retorna a qtde de bytes necessários para alocar memória para o conteudo
 * de um item serializado!
 * 16/12/2006 09:53:57
 */
static 
long ItemSize( PHB_ITEM pItem )
{  
   long  Length = 0;

   HB_TRACE( HB_TR_DEBUG, ("ItemSize( %p ) --> %c", pItem, wxItemType( pItem )   ));

   if (!pItem)
      return Length;
   
   switch( pItem->type )
   {
      case HB_IT_NIL     :
         return 3; // 1 + 2 
              
      case HB_IT_INTEGER :     
      case HB_IT_LONG    :     
      case HB_IT_DOUBLE  :                 
      case HB_IT_NUMERIC :     
      case HB_IT_NUMINT  :
         {     
            /*
             * Converte o numero para texto e chega os digitos
             * para ver se está com ERRO
             */
            char * SemZero = hb_itemStr( pItem, NULL, NULL );
            int i,j;            
             
            if (!SemZero)
               break;  // ñ deixamos ele gravar nada!

            Length = strlen( SemZero );
            
            /*
             * Removemos os espaços em branco à esqueda do numero
             * 16/12/2006 08:46:29
             */   
            for (i=0,j=0;i<Length;i++)
            {
               if (SemZero[i]== ' ')
                  continue;
               
               j++;
            }
 
            hb_xfree( SemZero );
            Length = j;
            break;                                           
         }
                 
      case HB_IT_DATE    :
         {
           if ( hb_itemGetDL( pItem ) == 0 )
              return 3; // 1 + 1 + 1    /* TIPO + LEN + DATA */
           else 
              return 6; // 1 + 1 + 4
         } 

      case HB_IT_LOGICAL :     
           return 3; // 1 + 1 + 1

      case HB_IT_STRING  :     
      case HB_IT_MEMO    :     
           Length = hb_itemGetCLen( pItem );
         break;
                 
      case HB_IT_ARRAY   :     
   // case HB_IT_OBJECT  :
         {
            PHB_ITEM n = NULL;
            PHB_ITEM p;
            ULONG j, i;
            BOOL  Obj;

            Obj = hb_arrayIsObject( pItem );
            
            if (Obj)
            {                             
               char *B = hb_objGetClsName( pItem );

               if (!pGetValues)
                  break;
                  
               hb_vmPushSymbol( pGetValues->pSymbol );
               hb_vmPushNil();
               hb_vmPush( pItem );
               hb_vmDo( 1 );
               
               if( hb_param( -1, HB_IT_ARRAY ) )
               {
                  n = hb_itemNew( NULL );
                  hb_itemCopy( n, hb_param( -1, HB_IT_ARRAY ) );
               }

               /* 
                * No caso dos OBJs, reservamos espaço para os nomes das propriedades
                * Ao todo serão 73 bytes para identificar o NOME da propriedade e 02
                * para o tipo e tamanho. 
                */
               Length += strlen(B)+1;
                   
            } else {
               n = pItem;
            }
                      
            if (!n)
               break;
                  
            i  = hb_arrayLen( n );
              
            /* For para processar o array */
            for ( j=1; j<=i; j++ )
            {  
               /* Se nao conseguiu puxar o item da pilha, pula fora! */
               p = hb_arrayGetItemPtr(n, j);
               
               if (!p)
                  continue;
               /*
                * Computamos o tamanho necessario e adicionamos
                * no valor de retorno! 
                */ 
               Length  += ItemSize( p );               
            }           
            
            if ((Obj) && (n))
               hb_itemRelease(n);
             
            break;                  
         }
         
   default:
      {
         return 3; // 1 + 1 + 1
      }
   }
   
   if(Length>255)
      Length += 5L; // 1 + 4
   else
      Length += 2L; // 1 + 1
              
   return Length;
}

/*
 * Retorna um BYTE indicando o tipo de dados do item passado como argumento 
 */
char  wxItemType( PHB_ITEM Item )
{
   if (!Item)
      return 'U';
   
   switch( Item->type )
   {
      case HB_IT_INTEGER :     
      case HB_IT_LONG    :     
      case HB_IT_DOUBLE  :                 
      case HB_IT_NUMERIC :     
      case HB_IT_NUMINT  :
            return 'N';
                 
      case HB_IT_DATE    :
           return 'D';

      case HB_IT_LOGICAL :     
           return 'L';

      case HB_IT_STRING  :     
      case HB_IT_MEMO    :     
           return 'C';
                 
      case HB_IT_ARRAY   :     
            if (hb_arrayIsObject( Item ))
              return 'O';
            else
              return 'A';
         break;
   }
   return 'U';
}

/*
 * Gera um texto formatado a partir do item atual!
 *
 * Convertido de C++ para C puro em 09/07/2008 - 18:20:25
 * Revisado em: 16/12/2006 09:32:08
 * Criado em .: 14/12/2006 21:30:27
 */
static
char *Item2Str( PHB_ITEM Item, char *Buffer, ULONG *Length )
{        
   char *Temp;
   ULONG Len;
   int i,j;
   
   HB_TRACE( HB_TR_DEBUG, ("Item2Str( %p, '%s', %lu )", Item, Buffer, *Length ));
   
   if (!Item)
      return Buffer;
   
   switch( Item->type )
   {
      case HB_IT_STRING  :     
      case HB_IT_MEMO    :
         {     
            Len  = hb_itemGetCLen( Item );
            Temp = hb_itemGetCPtr( Item );
            
           *Buffer = _MASK_('C',Len);
            Buffer++;
            Int2Str( Len, Buffer, &i );
            Buffer += i;
           *Length += Len + i + 1; 

            memmove( Buffer, Temp, Len );
            Buffer += Len; 
            break;                                           
         }
      case HB_IT_INTEGER :     
      case HB_IT_LONG    :     
      case HB_IT_DOUBLE  :                 
      case HB_IT_NUMERIC :     
      case HB_IT_NUMINT  :
         {
            char *A;     
            /*
             * Converte o numero para texto e chega os digitos
             * para ver se está com ERRO
             */
            Temp = hb_itemStr( Item, NULL, NULL );
            
            if (!Temp)
               break;  // ñ deixamos ele gravar nada!
            
            /*
             * Removemos os espaços em branco à esqueda do numero
             * 16/12/2006 08:46:29
             */   
            A = Temp; 
            i = 0;
            j = strlen(Temp);
             
            for ( ; i<j; i++, Temp++ )
               if (*Temp != ' ') 
                  break;
                        
            j = strlen(Temp);

           *Buffer = _MASK_('N',j);
            Buffer ++;
            Int2Str( j, Buffer, &i );
            Buffer += i;
           *Length += j+2;
             
            memmove( Buffer, Temp, j );
            Buffer += j;
            hb_xfree( A );
            break;                                           
         }
      case HB_IT_DATE    :
         {
           Temp = (char *) hb_xgrab(9);
           hb_itemGetDS( Item, Temp );
            
            /* 
             * Convertemos a data para um valor 'binario'!
             * 16/12/2006 09:21:22
             */      
            j = 4;       
           *Buffer = _MASK_('D',j);
            Buffer ++;
            Int2Str( j, Buffer, &i );
            Buffer ++;

            Int2Str( atol( Temp ), Buffer, &i );
            Buffer += i;
           *Length += i+2; 
                         
            hb_xfree( Temp );
            break;                                           
          }      
      case HB_IT_LOGICAL :     
         {           
           *Buffer = _MASK_('L',1);
            Buffer++;
            Int2Str( 1, Buffer, &i );
            Buffer += i;
           *Length += i + 2; 

           /* Converte T/F para 2/1 .. 16/12/2006 09:42:49 */
            if (hb_itemGetL( Item ))
               *Buffer = 2;
            else
               *Buffer = 1;
               
            Buffer++;              
            break;
          }                                                            
      case HB_IT_ARRAY   :     
   // case HB_IT_OBJECT  :
      {
            PHB_ITEM p,n;
            ULONG L, Count;
            char *B;
               
            if (hb_arrayIsObject( Item ))
            {                             
               B = hb_objGetClsName( Item );
               n = NULL;
               
               if (!pGetValues)
                  break;
                  
               hb_vmPushSymbol( pGetValues->pSymbol );
               hb_vmPushNil();
               hb_vmPush( Item );
               hb_vmDo( 1 );
               
               if( hb_param( -1, HB_IT_ARRAY ) )
               {
                  n = hb_itemNew( NULL );
                  hb_itemCopy( n, hb_param( -1, HB_IT_ARRAY ) );
               }

               if (!n)
                  break;
                  
               Count = hb_arrayLen( n );
              *Buffer = _MASK_('O',1);
               Buffer++;                  
               Int2Str( Count, Buffer, &i );
               Buffer += i;
              *Length += i + 1L; 

               i = strlen(B)+1;               
               memmove( Buffer, B, i );               
               Buffer += i;
              *Length += i; 
               
            } else {
               Count = hb_arrayLen( Item );
              *Buffer = _MASK_('A',Count);
               Buffer++;
               Int2Str( Count, Buffer, &i );
               Buffer += i;
              *Length += i + 1L;
              
               n = Item;
            }

            /* For para processar o array */
            for ( L = 1L; L<=Count; L++ )
            {              
               /* Se nao conseguiu puxar o item da pilha, pula fora! */
               p = hb_arrayGetItemPtr(n, L);
               
               if (!p)
                  continue;
               /*
                * 18/12/2006 18:56:21 - Chamos NÓS mesmos! 
                * (char *) wxItemSerialize( PHB_ITEM Item, ULONG *Length, BOOL *Delete, HB_FHANDLE hHandle )
                */
               Buffer = Item2Str( p, Buffer, Length );
            }            

            if (hb_arrayIsObject( n ))
               hb_itemRelease( n );
               
            break;
      }
      default:
         {      
           *Buffer = _MASK_('U',1);
            Buffer++;
            Int2Str( 1, Buffer, &i );
            Buffer += i;
           *Length += i + 2; 
           *Buffer = '\0';
               
            Buffer++;              
            break;
         }
   }
   return Buffer;
}

char *wxItemSerialize( PHB_ITEM Item, ULONG *Length, HB_FHANDLE hHandle )
{
   char *Buffer;
   ULONG L;

   HB_TRACE( HB_TR_DEBUG, ("wxItemSerialize( %p, %lu, %lu )", Item, *Length, hHandle ));

   *Length = 0;
   
   if (!Item)
      return NULL;
   if (!pGetValues)
      pGetValues = hb_dynsymFindName( "__OBJGETVALUEDIFF" ); // Trocamos em 11/07/2008 - 08:16:13 pois antes era __CLSGETIVARNAMESANDVALUES();

   L = ItemSize( Item );
   HB_TRACE( HB_TR_DEBUG, ("L := ItemSize( %p ) ===> %lu )", Item, L ));
   
   Buffer = (char *) hb_xgrab( L+1 );
   memset( Buffer, 0, L+1 );
   Item2Str( Item, Buffer, Length );
   HB_TRACE( HB_TR_DEBUG, ("  wxItemSerialize ==> %p, '%s', >> %lu << )", Item, Buffer, *Length ));
   
   /* 
    * Se for para gravar direto em um arquivo, faremos isto agora ao inves de 
    * retornar uma string e forçamos a limpeza de memoria.
    * 16/12/2006 10:44:34
    */
   if (hHandle)
   {
      hb_fsWriteLarge( hHandle, (BYTE *)Buffer, *Length );
      hb_xfree(Buffer);
     *Length = 0;
      return NULL;      
   }
   
   /* 
    * Não é para gravar? Ele está esperando retornarmos uma string!
    * 19/12/2006 08:45:17
    */
   return Buffer;
}

/*
 * wxSerialize() - Converte o primeiro argumento de qualquer tipo para uma string
 * serializada. Se o segundo  argumento  opcional  for  informado este deverá ser  
 * numérico e deve conter o  handle  de  um arquivo aberto com FCREATE/FOPEN para 
 * gravação dos dados.
 * 
 * 10/07/2008 - 07:32:20
 */
HB_FUNC( WXSERIALIZE )
{
   HB_THREAD_STUB         
   PHB_ITEM pItem   = hb_param(1, HB_IT_ANY );
   PHB_ITEM pHandle = hb_param(2, HB_IT_NUMERIC );

   ULONG   Length = 0;
   HB_FHANDLE hHandle;
   char   *Buffer;
   
   // TODO: TESTAR ISTO AQUI!!
   // 24/11/2009 - 08:25:52
   if (pHandle)
#if defined( HB_OS_WIN )
      hHandle = hb_itemGetNL( pHandle );
#else
      hHandle = hb_itemGetNI( pHandle );
#endif
   else
      hHandle = 0;
      
   Buffer = wxItemSerialize( pItem, &Length, hHandle );   
   hb_retclenAdopt(Buffer, Length);
}

/*
 * wxItemDeserialize() - Converte o primeiro argumento represetnando uma string
 * serializada para o seu valor original de qualquer tipo.
 * 
 * 10/07/2008 - 08:34:09
 */
HB_FUNC( WXITEMDESERIALIZE )
{
   HB_THREAD_STUB         
   PHB_ITEM pRawData = hb_param(1, HB_IT_STRING );
   PHB_ITEM pItem;
   char *Buffer;

   if (!pRawData)
   {
      hb_ret();
      return;
   }
      
   Buffer = hb_itemGetCPtr( pRawData );
   pItem  = hb_itemNew( NULL );
   pItem->type = HB_IT_NIL;
      
   wxItemDeserialize( Buffer, pItem );
   hb_itemReturn( pItem );
   hb_itemRelease( pItem );
}

/*
 * wxItemDeserialize( char *RawData, PHB_ITEM Output )
 * Deserializa um valor previamente obtido com wxItemSerialize() conforme passado
 * pelo primeiro argumento e coloca o seu valor restaurado em OutPut. 
 * 25/12/2006 09:17:06
 */
char *wxItemDeserialize( char *RawData, PHB_ITEM Item )
{
   char  Type;
   ULONG Len;   
   BOOL B; 
   
   HB_THREAD_STUB   
   HB_TRACE( HB_TR_DEBUG, ("wxItemDeserialize( (%c%c%c)'%s', %p )", RawData[0], RawData[1], RawData[2], RawData, Item ));
   
   if (!RawData)
      return NULL;
   if (!RawData[0])
      return NULL;
   if (!pGetValues)
      pGetValues = hb_dynsymFindName( "__OBJGETVALUEDIFF" ); // Trocamos em 11/07/2008 - 08:16:13 pois antes era __CLSGETIVARNAMESANDVALUES();

   /* 1° Passo, lemos o "tipo" de dados! */
   Type = *RawData;
   B    = _MASK_EX_(Type);
   //HB_TRACE( HB_TR_DEBUG, ("  >>%c<< [[%c]] ## %d ##", Type, UNMASK_TYPE( Type ), B ));
   Type = UNMASK_TYPE( Type );
   RawData ++; 

   /* 2° Passo: Qtos digitos tem o tamanho total da string? */
   if (B)
   {
      Len = Str2Int( RawData, 4 );
      RawData += 4;
   } else {
      Len = Str2Int( RawData, 1 );
      RawData ++;
   }
      
   switch( Type )
   {
       case 'U':
         hb_itemClear( Item );
         return ++RawData;

       case 'C':
         hb_itemPutCL( Item, RawData, Len );
         RawData += Len;
         break;
            
       case 'N':
         {                                             /// 2147483647 -> 10 bytes
            BOOL IsLong;
            char C = RawData[Len];
            
            RawData[Len] = '\0';
            IsLong       = ((strpbrk(RawData,".") == NULL) && (Len < 10 ));
            
            // Se é LONG ñ possui casas decimais... ;-)
            if (IsLong)
               hb_itemPutNL( Item, atol(RawData));
            else
               hb_itemPutND( Item, atof(RawData));
               
            RawData += Len;
            RawData[0] = C;
            break;
         }
         
       case 'L':
         {
            hb_itemPutL( Item, (RawData[0] == 2) );
            RawData ++;
            break;
         }
         
       case 'D':
         {
            LONG Value = Str2Int( RawData, Len );
            char Text[9]; 
             
            Text[0] = '\0';
            sprintf( Text, "%lu", Value );
            
            hb_itemPutDS( Item, Text );
            
            RawData += Len;            
            break;
         }

       case 'A':
         {
            PHB_ITEM p;
            ULONG i;
            
            hb_arrayNew( Item, Len );
            
            if (Len<1)
            {
               Len = 1L;
               break;
            }
            
            for (i=1L;i<=Len;i++)
            {
               /* Se nao conseguiu puxar o item da pilha, pula fora! */
               p = hb_arrayGetItemPtr(Item, i);
               
               if (!p)
                  continue;
               
               RawData = wxItemDeserialize( RawData, p );
               
               // Em caso de erro, abortamos o processo!               
               if (!RawData) return NULL;
            }
            
            Len = 0L;            
            break;
         }         
       case 'O':
         {
            char *ClsName;
            PHB_DYNS pCreateObj;
            int L;
            
            ClsName = RawData;
            L = strlen( ClsName );
            
            RawData += (L+1); 
    
HB_TRACE( HB_TR_DEBUG, ("  >> OBJ OF (%s) %d bytes  <<", ClsName, L ));
//HB_TRACE( HB_TR_DEBUG, ("  **** (%c%c%c%c%c)", RawData[0], RawData[1], RawData[2], RawData[3], RawData[4]));

            /*
             * Create a new object from classname... 
             */
            pCreateObj = hb_dynsymFindName( ClsName );
            
            if (pCreateObj)
            {
               hb_vmPushSymbol( pCreateObj->pSymbol );
               hb_vmPushNil();
               hb_vmDo( 0 );
               
               /*
                * The Object constructor is in the return, calling NEW now to 
                * get a valid new instace! 
                */
               hb_objSendMsg( hb_stackSelfItem(), "NEW", 0 );
               hb_itemCopy( Item, hb_stackSelfItem() );
               
HB_TRACE( HB_TR_DEBUG, ("  >> %s(): New () --> %c <<", ClsName, wxItemType( Item ) ));
               if (!hb_arrayIsObject( Item ))
                  hb_itemClear( Item );

            } 

            /*
             * Vamos deserializar os campos do objeto e iremos gravar os dados
             * diretamente no novo OBJ criado!
             */
            if (Item)
            {
               PHB_ITEM p,t,k,v;
               ULONG i,l;
               
               t = hb_itemNew( NULL );
               hb_arrayNew( t, Len );
               
               for (i=1L;i<=Len;i++)
               {
                  // Se nao conseguiu puxar o item da pilha, pula fora! 
                  p = hb_arrayGetItemPtr(t, i);
                  
                  if (!p)
                     continue;
                  if (!RawData[0])
                  {
                     Len = 0L;
                     break;
                  }
                  
                  RawData = wxItemDeserialize( RawData, p );
                  
                  if (!HB_IS_ARRAY(p))
                     continue;
                  
                  l = hb_arrayLen( p );
                  
                  if (l!=2)
                     continue;
                     
                  k = hb_arrayGetItemPtr(p, 1);
                  v = hb_arrayGetItemPtr(p, 2);
                  
                  if (hb_itemGetCLen( k )<1)
                      continue;
/*                  
HB_TRACE( HB_TR_DEBUG, ("  >> OBJ: %c   PTR: %p  <<", wxItemType( Item ), Item ));
HB_TRACE( HB_TR_DEBUG, ("  >> KEY: %c   VALUE: %c <<", wxItemType( k ), wxItemType( v ) ));
HB_TRACE( HB_TR_DEBUG, ("  >> KEY: %lu  VALUE: %lu <<", hb_itemGetCLen( k ), hb_itemGetCLen( v ) ));
HB_TRACE( HB_TR_DEBUG, ("  >> KEY: %s   <<", hb_itemGetCPtr( k ) ));    
HB_TRACE( HB_TR_DEBUG, ("  >> VALUE: %s <<", hb_itemGetCPtr( v ) ));                                                                                                                                        
*/                  
                  if (hb_arrayIsObject( Item ))
                     hb_objSendMsg( Item, hb_itemGetCPtr( k ), 1, v );
               }
               
               hb_itemClear(t);
               hb_itemRelease(t);
               break;
            }
            /**/
         }
       default:
         RawData += Len;
   }            

   //HB_TRACE( HB_TR_DEBUG, ("  **** (%c)", RawData[0]));
   return RawData;
}
