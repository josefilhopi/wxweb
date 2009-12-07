/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 19/07/2008 - 23:14:58
 *
 *  Criado em: 14/11/2006 - 10:03:30
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: xWebUtils.c
 *                            
 *  Funcoes diversas para tratamento de Strings
 *
 *---------------------------------------------------------------------------*/
#include <wxweb.h>
#include "hbvmopt.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapierr.h"
#include "hbdate.h"
#include "hbstack.h"

//#include <mem.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <wxMemory.h>
#include <wxTrace.h>

#if defined( WEB_DEBUG )
extern char  wxItemType( PHB_ITEM Item );
#endif

/*
 * Retorna .T. se as 2 strings passadas como argumento forem do mesmo valor. A
 * comparação é feita ignorando-se maiusculas/minusculas.
 * 19/07/2008 - 23:22:34
 */
HB_FUNC( WXSAMETEXT )
{
   PHB_ITEM pText1 = hb_param( 1, HB_IT_STRING );
   PHB_ITEM pText2 = hb_param( 2, HB_IT_STRING );

   char *s1, *s2;
   int l1, l2;
   
   HB_TRACE( HB_TR_DEBUG, ("wxSameText()" ));
   hb_retl( FALSE );
   
   // Algum dos 2 parametros não é string?
   if ((!pText1) || (!pText2))
      return;
   
   // As 2 strings possuem tamanho diferente?
   l1 = pText1->item.asString.length; 
   l2 = pText2->item.asString.length;
    
   if (l1 != l2)
      return;

   // Agora validamos os caracteres
   s1 = pText1->item.asString.value;
   s2 = pText2->item.asString.value;
   
   // Teste simples... se for para validarmos a mesma variavel, já fazemos aqui.
   if (s1 == s2)
   {
      hb_retl( TRUE );
      return;
   }   
   
   for ( l2 = 0; l2 < l1; l2 ++ )
   {
      if (toupper(s1[l2]) != toupper(s2[l2] ))
         return;
   }   
   
   hb_retl( TRUE );
   return;
}
   
/* 
 * Retorna o 1o. parametro NAO NIL da lista de argumetnos passados. Exemplo:
 *    wxCoalese( arg1, arg2, argN, ... )
 *
 * 1/1/2007 13:53:45
 */
HB_FUNC( WXCOALESE )
{
   int pc, i;
   PHB_ITEM arg;
   
   HB_TRACE( HB_TR_DEBUG, ("wxCoalese()" ));
   
   for (i=1,pc = hb_pcount(); i<=pc; i++)
   {
      arg = hb_param( i, HB_IT_ANY );

      /* Nao possui um argument válido! */      
      if (!arg)
         continue;
      
      /* Se for NIL, ignore! */
      if (arg->type == HB_IT_NIL)
         continue;
      
      /* Retornamos este valor nao NIL da listagem */
      hb_itemReturn( arg );
      return;
   }   
   hb_ret();   // Retorna NIL caso nenhum item válido tenha sido encontrado!
}

/*
 * wxCoaleseStr( <bIgnoreNULL>, <argC1>, <argC2>, <argCN>, ... ) 
 * Retorna o 1o. parametro string encontrado na lista de argumentos fornecida. 
 * Se o primeiro parametro for um valor LOGICO, ele indicará se .T., que devemos  
 * ignorar quaisquer strings vazias durante a varredura dos argumentos passados.  
 * O comportamento é padrão é processar todos os parametros recebidos. 
 * 
 * Exemplo:
 *    wxCoaleseStr( .T., argC1, argC2, argCN, ... )
 *
 * 1/1/2007 13:53:45
 */
HB_FUNC( WXCOALESESTR )
{
   PHB_ITEM arg;
   int pc, i = 1;
   BOOL IgnoreEmpty = FALSE;    
   
   HB_TRACE( HB_TR_DEBUG, ("wxCoaleseStr()" ));
   if (ISLOG(1))
   {
      IgnoreEmpty = hb_parl(1); i++;
   } 
   
   for (pc = hb_pcount(); i<=pc; i++)
   {
      arg = hb_param( i, HB_IT_ANY );

      /* Nao possui um argument válido? Quebramos o LOOP */      
      if (!arg)
         break;
      
      /* Se for String ignore! */
      if (arg->type != HB_IT_STRING)
         continue;
      
      /* Ops... string vazia? esquece... */
      if (IgnoreEmpty && 
          ( arg->item.asString.length <1 ))
         continue;
         
      /* Retornamos este valor nao NIL da listagem */          
      hb_itemReturn( arg );
      return;
   }   
   hb_retc(""); // Se ele nao encontrar nada, retorna uma string NULA
}

/*
 * wxListAsArray( <argC>, <delimC>, <nMaxSize> ) --> aResult
 * Converte uma string para array usando o delimitador passado como segundo
 * argumento.
 * 
 * Convertida para C em:
 *    31/12/2006 14:32:01
 * Original:
 *    31/12/2006 14:32:01    
 */
HB_FUNC( WXLISTASARRAY ) 
{
   PHB_ITEM pArray, pItem;
   PHB_ITEM pList, pDelim;
   char *cList;
   int Count, nMinSize;
   ULONG Length, Pos;
   BOOL Loop;

   /*
    * Uma validação simples: Se ele já nos tiver passado um ARRAY, então iremos
    * ignorar todo o processo e retornar o primeiro argumento!
    */
   if (ISARRAY(1))
   {
      hb_itemReturn( hb_param(1, HB_IT_ANY ));
      return;                         
   } 
   
   /*
    * Aqui validamos se os 2 parametros obrigatórios foram passados com os tipos 
    * corretos! 
    */
   pList  = hb_param( 1, HB_IT_STRING );
   pDelim = hb_param( 2, HB_IT_STRING );
   
   HB_TRACE( HB_TR_DEBUG, ("wxListAsArray( '%c', '%c' )", wxItemType( pList ), wxItemType( pDelim ) ));
   if ((!pList) || (!pDelim))
   {
      hb_errRT_BASE_SubstR( EG_ARG, 3012, "Wrong parameter count/type",
         "wxListAsArray",
         2, hb_paramError(1), hb_paramError(2), hb_param(3, HB_IT_ANY ) );
      return;
   }
      
   pArray = hb_itemNew( NULL );
   pArray->type = HB_IT_NIL;

   pItem = hb_itemNew( NULL );
   pItem->type  = HB_IT_NIL;
   
   hb_arrayNew( pArray, 0 );
   
   cList   = pList->item.asString.value;   
   Length  = pList->item.asString.length;
   Loop    = (( pList->item.asString.length > 0 ));
   Count   = 0;
   nMinSize= hb_parni(3);
   
   while (Loop)
   {
      Pos = hb_strAt( pDelim->item.asString.value, pDelim->item.asString.length, cList, Length );
   
      if (!Pos)
      {
         Loop = FALSE;
         Pos  = Length+1;
      }
            
      hb_itemPutCL( pItem, cList, Pos-1 );
      hb_arrayAddForward( pArray, pItem);
      
      if (Loop)
      {
         if (pDelim->item.asString.length>1)
            Pos += pDelim->item.asString.length-1;
            
         cList += Pos; 
         Length-= Pos;
      }  
      
      // Tem valor maximo a ser processado?
      if ((nMinSize && ++Count == nMinSize))
         break;    
   } 
   
   hb_itemReturn( pArray );
   hb_itemRelease( pArray);
   hb_itemRelease( pItem );
   return;   
}

/*
 * wxEnsureString( <xValue> ) -> cValue
 * Assegura-se que o valor passado seja convertido para string
 * 20/11/2006 11:03:46
 */   
HB_FUNC( WXENSURESTRING )
{
   PHB_ITEM pItem;
   char *Text;
   ULONG ulLen;
   BOOL bFreeReq;
   
   /* Verificamos os parametros passados */
   pItem = hb_param( 1, HB_IT_ANY );

   HB_TRACE( HB_TR_DEBUG, ("wxEnsureString( %p  ) -- > %c", pItem, wxItemType( pItem ) ));
   if (!pItem)
   {
      hb_retc("");
      return;
   }
   if( HB_IS_LOGICAL( pItem ) )
   {
      ulLen = 3;
      bFreeReq = FALSE;
      Text = ( char * ) ( hb_itemGetL( pItem ) ? ".T." : ".F." );
   } else {
      Text = hb_itemString( pItem, &ulLen, &bFreeReq );
   }

   if( bFreeReq )
   {
      PHB_ITEM pTemp = hb_itemNew( NULL );      
      hb_itemPutCLPtr( pTemp, Text, ulLen );
      hb_itemReturn( pTemp );
   } else {
      hb_retclen( Text, ulLen ); 
   }
}

/*
 * wxEnsureBoolean( <xValue> ) -> cValue
 * Assegura-se que o valor passado seja convertido para um valor Lógico
 * 20/11/2006 11:03:46
 */   
HB_FUNC( WXENSUREBOOLEAN )
{
   PHB_ITEM pItem;
   ULONG ulLen;
   BOOL bResult;
   
   /* Verificamos os parametros passados */
   pItem   = hb_param( 1, HB_IT_ANY );
   bResult = FALSE;

   HB_TRACE( HB_TR_DEBUG, ("wxEnsureBoolean( %p  ) -- > %c", pItem, wxItemType( pItem ) ));
   if (!pItem)
   {
      hb_retl( bResult );
      return;
   }

   switch( pItem->type )
   {         
      case HB_IT_STRING:
         ulLen = hb_itemGetCLen( pItem );
         
         if (ulLen == 1L || ulLen == 3L || ulLen == 4L )
         {
            const char *Text = hb_itemGetCPtr( pItem );
            bResult = SameText( Text, ".T." ) ||
                      SameText( Text, ".Y." ) ||
                      SameText( Text, "SIM" ) ||
                      SameText( Text, "SI"  ) ||
                      SameText( Text, "YES" ) ||
                      SameText( Text, "T"   ) ||
                      SameText( Text, "Y"   ) ||
                      SameText( Text, "S"   ) ||
                      SameText( Text, "TRUE" );
         }
         break;
         
      case HB_IT_DATE:
    	 {
         bResult = ( hb_itemGetDL( pItem ) != 0 );
         break;
       }

      default:
         bResult = hb_itemGetL( pItem );
         break;
   }
   
   hb_retl( bResult );
   return;
}

/*
 * wxEnsureNumeric( <xValue> ) --> nValue
 * Assegura-se que o valor passado seja convertido para numerico.
 * 20/11/2006 14:21:25
 */   
HB_FUNC( WXENSURENUMERIC )
{
   PHB_ITEM pItem;

   pItem = hb_param( 1, HB_IT_ANY );

   HB_TRACE( HB_TR_DEBUG, ("wxEnsureNumeric( %p  ) -- > %c", pItem, wxItemType( pItem ) ));

   if (!pItem)
   {
      hb_retni(0);
      return;
   }
   
   switch( pItem->type )
   {
      case HB_IT_INTEGER :     
      case HB_IT_LONG    :     
      case HB_IT_DOUBLE  :                 
      case HB_IT_NUMERIC :     
      case HB_IT_NUMINT  :
         hb_itemReturn( pItem );
         return;
       
      case HB_IT_DATE:
    	 {
         int iYear, iMonth, iDay;
         long lDate = hb_itemGetDL( pItem );
         char szDate[9];
    	 
         if( !lDate )
         {
           hb_retni(0);
           return;
         }
         
         hb_dateDecode( lDate, &iYear, &iMonth, &iDay );
         hb_dateStrPut( szDate, iYear, iMonth, iDay );
         szDate[ 8 ] = '\0';

         hb_retnl( atol( szDate ) );
         return;
		 }

      case HB_IT_LOGICAL:
         hb_retni( (pItem->item.asLogical.value) ? 1 : 0 );
         return;

      case  HB_IT_STRING:
         if( pItem->item.asString.length > 0 )
         {
            if (strrchr( pItem->item.asString.value, '.' ))
               hb_retnd( atof( pItem->item.asString.value ));
            else
               hb_retnl( atol( pItem->item.asString.value ));
         } else
            hb_retni( 0 );
         return;
   }
   hb_retni( 0 );
}         

/*
 * wxEnsureNumericString( <nValue> ) --> cValue
 * Converte o valor passado para numerico e depois  converte-o para String
 * 31/12/2006 20:14:41
 */
HB_FUNC( WXENSURENUMERICSTRING )
{
   PHB_ITEM pItem;

   pItem = hb_param( 1, HB_IT_ANY );

   HB_TRACE( HB_TR_DEBUG, ("wxEnsureNumericString( %p  ) -- > %c", pItem, wxItemType( pItem ) ));

   if (!pItem)
   {
      hb_retc("0");
      return;
   }
   
   switch( pItem->type )
   {
      case HB_IT_INTEGER :     
      case HB_IT_LONG    :     
      case HB_IT_DOUBLE  :                 
      case HB_IT_NUMERIC :     
      case HB_IT_NUMINT  :
       {
         char *buffer = hb_itemStr( pItem, NULL, NULL );

         if( buffer )
            hb_retclenAdopt( ( char * ) buffer, strlen( buffer ));
         else
            hb_retc("");
         return;
       }
      case HB_IT_DATE:
    	 {
         int iYear, iMonth, iDay;
         long lDate = hb_itemGetDL( pItem );
         char szDate[8];
    	 
         if( !lDate )
         {
           hb_retc("0");
           return;
         }
         
         hb_dateDecode( lDate, &iYear, &iMonth, &iDay );
         hb_dateStrPut( szDate, iYear, iMonth, iDay );
         szDate[ 8 ] = '\0';

         hb_retc( szDate );
         return;
		 }

      case HB_IT_LOGICAL:
         hb_retc( (pItem->item.asLogical.value) ? "1" : "0" );
         return;

      case  HB_IT_STRING:
         if( pItem->item.asString.length > 0 )
         {
            char Text[40] = {0};
                 
            if (strrchr( pItem->item.asString.value, '.' ))
            {
               sprintf( Text, "%f", atof( pItem->item.asString.value ));
            } else
               sprintf( Text, "%ld", atol( pItem->item.asString.value ));
               
            hb_retc( Text );
         } else
            hb_retc( "0" );
         return;
   }
   hb_retc( "0" );
}
