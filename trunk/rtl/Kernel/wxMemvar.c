/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 01/07/2008 - 08:48:34
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxMemvar.c
 *                            
 *  Funções para manipulação de variaveis de memoria em nivel xBase
 *
 *---------------------------------------------------------------------------*/
#ifndef HB_MACRO_SUPPORT
#  define HB_MACRO_SUPPORT
#endif

#include "hbvmopt.h"
#include "wxMemvar.h"
#include "hbapiitm.h"
#include "hbcomp.h"
#include "hbvm.h"

#include <wxMT.h>

extern PHB_DYNS s_memvarThFindName( char * szName, void *pstack );

/*
 * Retorna uma STRING de uma variavel caracter do xHarbour, criada via .PRG! Ela 
 * retorna em pulLen o tamanho da string encontrada.
 * 01/07/2008 - 08:40:47
 */
char *wxMemvarGetCPtr( char * szVarName, ULONG *pulLen )
{
   HB_THREAD_STUB
   HB_DYNS_PTR pDynVar;
   char *szValue = NULL;

   HB_TRACE(HB_TR_DEBUG, ("hb_memvarGetStrValuePtr(%s, %p)", szVarName, pulLen));

   #ifdef HB_THREAD_SUPPORT
      pDynVar = s_memvarThFindName( szVarName, &HB_VM_STACK );
   #else
      pDynVar = hb_dynsymFindName( szVarName );
   #endif

   if( pDynVar )
   {
      /* there is dynamic symbol with the requested name - check if it is
       * a memvar variable
       */
      if( pDynVar->hMemvar )
      {
         /* variable contains some data
          */
         HB_ITEM_PTR pItem = hb_memvarGetValueByHandle( pDynVar->hMemvar );

         if( HB_IS_BYREF( pItem ) )
         {
            pItem = hb_itemUnRef( pItem );   /* it is a PARAMETER variable */
         }

         if( HB_IS_STRING( pItem ) )
         {
            szValue = pItem->item.asString.value;
            *pulLen = pItem->item.asString.length;
         }
      }
   }
   return szValue;
}

/*
 * Retorna o valor LONG de uma variavel numérica do xHarbour, criada via .PRG
 * 01/07/2008 - 08:40:47
 */
LONG wxMemvarGetNL( char * szVarName )
{
   HB_THREAD_STUB   
   HB_DYNS_PTR pDynVar;
   LONG result = 0;

   HB_TRACE(HB_TR_DEBUG, ("hb_memvarGetStrValuePtr(%s, %p)", szVarName, pulLen));

   #ifdef HB_THREAD_SUPPORT
      pDynVar = s_memvarThFindName( szVarName, &HB_VM_STACK );
   #else
      pDynVar = hb_dynsymFindName( szVarName );
   #endif

   if( pDynVar )
   {
      /* there is dynamic symbol with the requested name - check if it is
       * a memvar variable
       */
      if( pDynVar->hMemvar )
      {
         /* variable contains some data
          */
         HB_ITEM_PTR pItem = hb_memvarGetValueByHandle( pDynVar->hMemvar );

         if( HB_IS_BYREF( pItem ) )
         {
            pItem = hb_itemUnRef( pItem );   /* it is a PARAMETER variable */
         }

         if( HB_IS_NUMERIC( pItem ) )
         {
            result = hb_itemGetNL( pItem );
         }
      }
   }
   return result;
}

/*
 * Retorna o valor INT de uma variavel numérica do xHarbour, criada via .PRG
 * 01/07/2008 - 08:46:31
 */
int wxMemvarGetNI( char * szVarName )
{
   HB_THREAD_STUB   
   HB_DYNS_PTR pDynVar;
   int result = 0;

   HB_TRACE(HB_TR_DEBUG, ("hb_memvarGetStrValuePtr(%s, %p)", szVarName, pulLen));

   #ifdef HB_THREAD_SUPPORT
      pDynVar = s_memvarThFindName( szVarName, &HB_VM_STACK );
   #else
      pDynVar = hb_dynsymFindName( szVarName );
   #endif

   if( pDynVar )
   {
      /* there is dynamic symbol with the requested name - check if it is
       * a memvar variable
       */
      if( pDynVar->hMemvar )
      {
         /* variable contains some data
          */
         HB_ITEM_PTR pItem = hb_memvarGetValueByHandle( pDynVar->hMemvar );

         if( HB_IS_BYREF( pItem ) )
         {
            pItem = hb_itemUnRef( pItem );   /* it is a PARAMETER variable */
         }

         if( HB_IS_NUMERIC( pItem ) )
         {
            result = hb_itemGetNI( pItem );
         }
      }
   }
   return result;
}

/*
 * Altera o valor de uma variavel de memoria em nivel xBase. Retorna 1 se for 
 * bem sucedido ou 0 em caso de erro.
 * 01/07/2008 - 17:12:17
 */
int wxMemvarPut( char * szVarName, PHB_ITEM pValue )
{
   HB_DYNS_PTR pDyn;
   int result = 0;

   #ifdef HB_THREAD_SUPPORT
      HB_THREAD_STUB
      pDyn = s_memvarThFindName( szVarName, (HB_STACK *) &HB_VM_STACK );
   #else
      pDyn = hb_dynsymFindName( szVarName );
   #endif

   /*
    * Se a variavel não existir ... criamos ela aqui como pública!
    */
   if( !pDyn )
   {
      PHB_ITEM pMemvar = hb_itemNew( NULL );
      hb_itemPutC( pMemvar, szVarName );
      hb_memvarCreateFromItem( pMemvar, VS_PUBLIC, NULL );
      hb_itemRelease( pMemvar );

   #ifdef HB_THREAD_SUPPORT
      pDyn = s_memvarThFindName( szVarName, &HB_VM_STACK );
   #else
      pDyn = hb_dynsymFindName( szVarName );
   #endif
   }

   if( pDyn )
   {
      /* there is dynamic symbol with the requested name - check if it is
       * a memvar variable
       */
      if( pDyn->hMemvar )
      {
         /* value is already created */
         HB_ITEM_PTR pSetItem = hb_memvarGetValueByHandle( pDyn->hMemvar );

         // JC1: the variable we have now can't be destroyed in the meanwhile.
         // It could be changed, but this is a race condition that must be
         // prevented at prg level.
         if( HB_IS_BYREF( pSetItem ) )
         {
            pSetItem = hb_itemUnRef( pSetItem );
         }
         hb_itemCopy( pSetItem, pValue );
         result = 1;

         // Count this new value.
         /* s_globalTable[ pDyn->hMemvar ].counter = 1; */
      }
   }
   return result;
}

HB_FUNC(WXTHREADID)
{
   #ifdef HB_THREAD_SUPPORT
      HB_FUNC_EXEC( HB_THREADID )
   #else
      hb_retni( 0 );
   #endif
}
