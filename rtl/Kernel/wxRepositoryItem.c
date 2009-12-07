/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado C ..: 07/07/2008 - 19:06:04
 *
 *  Revisado C++.: 08/12/2006 - 08:09:11
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxRepositoryItem.c
 *                            
 *  Funções para manipulação de "pedaços" de informações
 *
 *---------------------------------------------------------------------------*/
#include <wxweb.h>
#include "hbapi.h"
#include "hbapiitm.h"
#include "wxRepositoryItem.h"
#include <wxTrace.h>

extern char wxItemType( PHB_ITEM Item );

/*
 * Cria o buffer para cache e retorna o seu ponteiro de memoria
 * 07/07/2008 - 18:37:31
 */
PRepositoryItem RepositoryList_Create( void )
{
   PRepositoryItem pBuffer;
   
   pBuffer = (PRepositoryItem) hb_xgrab( sizeof( TRepositoryItem ) );
   memset( pBuffer, '\0', sizeof( TRepositoryItem ) );

   /* Preenchemos os valores da estrutura com seus valores default */
   pBuffer->Type = rtiValue;
   return pBuffer;   
};

/*
 * Libera a memoria ocupada pelos campos atrelados à estrutura passada como 
 * argumento, MAS NÃO destroi o objeto em si.
 * 08/07/2008 - 12:27:31
 */
WX_RES RepositoryList_Finalize( PRepositoryItem pBuffer )
{
   if (!pBuffer)
      return WX_FAILURE;
   
   if (pBuffer->Key)
   {
      hb_xfree( (WX_PTR) pBuffer->Key );
      pBuffer->Key = NULL;
   }

   if (pBuffer->Value)
   {
      if (pBuffer->Type == rtiItem)
         hb_itemRelease( (PHB_ITEM) pBuffer->Value );
      else 
         hb_xfree( (WX_PTR) pBuffer->Value );
         
      pBuffer->Value = NULL;
   }
   
   pBuffer->Type  = rtiValue; // Evita que futuramente ele tente se referenciar ao PHB_ITEM - 12/07/2008 - 08:58:36
   return WX_SUCCESS ;
}

/*
 * Libera a memoria ocupada pelos campos e o proprio item passado como argumento
 * 07/07/2008 - 19:13:57
 */
WX_RES RepositoryList_Destroy( PRepositoryItem pBuffer )
{                 
   if (RepositoryList_Finalize(pBuffer) != WX_SUCCESS)            
      return WX_FAILURE;
      
   hb_xfree( pBuffer );         
   return WX_SUCCESS ;
}
/*
 * Adiciona um novo item na sequencia de pBuffer como String e retorna o sua
 * posição na memoria.
 * 07/07/2008 - 19:57:04
 */
PRepositoryItem RepositoryList_AddStr( PRepositoryItem pBuffer, BYTE *Source, ULONG Length, BOOL bInsertCRLF )
{
   PRepositoryItem pItem;
   ULONG i = ((bInsertCRLF) ? Length+3 : Length+1 );
   
   pItem = RepositoryList_Create();
   pItem->Type     = rtiValue;
   pItem->Value    = (WX_PTR) hb_xgrab(i);
   
   // Falha de memoria?
   if (!pItem->Value)
   {  
      RepositoryList_Destroy( pItem );
      return (PRepositoryItem) NULL;
   }
   
   // Copiamos os dados
   hb_xmemcpy( (WX_PTR) pItem->Value, (WX_PTR) Source, Length);
   
   if (bInsertCRLF)
   {
      Length += 2;
      ((char *) pItem->Value)[Length-2] = '\r';
      ((char *) pItem->Value)[Length-1] = '\n';
   }
   
   // Ajustamos diversos flags
   if (pBuffer)
      pBuffer->pNext  = pItem;
      
   pItem->Capacity = pItem->Len = Length;
   return pItem;
}

/*
 * Adiciona um PHB_ITEM à pilha de sequencias e retorna o seu ponteiro.
 * 07/07/2008 - 21:24:47
 */                                                                 
PRepositoryItem RepositoryList_AddItem( PRepositoryItem pBuffer, PHB_ITEM pValue )
{
   PRepositoryItem pItem;
   
   pItem = RepositoryList_Create();
   pItem->Type     = rtiItem;
   pItem->Value    = (WX_PTR) hb_itemNew( NULL );
   
   // Falha de memoria?
   if (!pItem->Value)
   {  
      RepositoryList_Destroy( pItem );
      return (PRepositoryItem) NULL;
   }
   
   // Copiamos os dados
   if (pValue)
      hb_itemCopy( (PHB_ITEM) pItem->Value, pValue );
   
   // Ajustamos diversos flags
   if (pBuffer)
      pBuffer->pNext   = pItem;
   return pItem;
}

/*
 * Apenas atualiza o conteudo da STRING anexada ao item passado como argumento.
 * 08/07/2008 - 12:25:06
 */
WX_RES RepositoryList_UpdateStr( PRepositoryItem pItem, BYTE *Source, ULONG Length )
{
   HB_TRACE( HB_TR_DEBUG, ("  RepositoryList_UpdateStr(%p, %p, %lu) ", pItem, Source, Length ));
   
   /* Se ele já tem algo, iremos zerar seu valor! */
   if (pItem->Value)
   {
      if (pItem->Type == rtiItem)
         hb_itemRelease( (PHB_ITEM) pItem->Value );
      else 
         hb_xfree( (WX_PTR) pItem->Value );
         
      pItem->Value = NULL;
   }

   if (!Source)
      Length = 0L;
         
   /* Ajustamos o valor para o novo! */
   pItem->Type  = rtiValue;   
   pItem->Value = (WX_PTR) hb_xgrab(Length+1);
   
   // Falha de memoria?
   if (!pItem->Value)   
      return WX_FAILURE ;
   
   // Copiamos os dados
   if (( Source) && (Length))
      hb_xmemcpy( (WX_PTR) pItem->Value, (WX_PTR) Source, Length);
      
   // Finalizamos a string com um ZERO binário!
   ((char *) pItem->Value)[Length] = '\0';

   // Ajustamos alguns flags!   
   pItem->Capacity = pItem->Len = Length;
   return WX_SUCCESS;
}

/*
 * Apenas atualiza o conteudo do PHB_ITEM anexado ao item passado como argumento.
 * 12/07/2008 - 08:50:01
 */
WX_RES RepositoryList_UpdateItem( PRepositoryItem pItem , PHB_ITEM pValue )
{
   HB_TRACE( HB_TR_DEBUG, ("RepositoryList_UpdateItem(%p,%p)", pItem, pValue ));
   
   /* Se ele já tem algo, iremos zerar seu valor! */
   if (pItem->Value)
   {
      if (pItem->Type == rtiValue)
      {
         hb_xfree( (WX_PTR) pItem->Value );
         pItem->Value = NULL;
      } else { 
         hb_itemClear( (PHB_ITEM) pItem->Value );
      }
   }

   /* Preparamos o buffer, caso não haja nenhum ITEM ainda vinculado à nos */
   if (!pItem->Value)
   {
      pItem->Type  = rtiItem;
      pItem->Value = (WX_PTR) hb_itemNew( NULL );
   }
   
   // Falha de memoria?
   if (!pItem->Value)
   {  
      // Limpamos a memoria, mas não chamamos DESTROY para evitar GPF futuramente
      RepositoryList_Finalize( pItem );
      return WX_FAILURE;
   }
   
   // Copiamos os dados
   if (pValue)
      hb_itemCopy( (PHB_ITEM) pItem->Value, pValue );
     
   return WX_SUCCESS;
}

/*
 * Apenas atualiza o conteudo da STRING anexada ao item passado como argumento mas
 * reaproveitando seu buffer.
 * 19/07/2008 - 11:56:47
 */
WX_RES RepositoryList_UpdateStrPtr( PRepositoryItem pItem, BYTE *Source, ULONG Length )
{
   HB_TRACE( HB_TR_DEBUG, ("  RepositoryList_UpdateStrPtr(%p, %p, %lu) ", pItem, Source, Length ));
   
   /* Se ele já tem algo, iremos zerar seu valor! */
   if (pItem->Value)
   {
      if (pItem->Type == rtiItem)
         hb_itemRelease( (PHB_ITEM) pItem->Value );
      else 
         hb_xfree( (WX_PTR) pItem->Value );
         
      pItem->Value = NULL;
   }

   if (!Source)
      Length = 0L;
         
   /* Ajustamos o valor para o novo! */
   pItem->Type  = rtiValue;   
   pItem->Value = (WX_PTR) Source;
        
   // Finalizamos a string com um ZERO binário!
   if (pItem->Value)
      ((char *) pItem->Value)[Length] = '\0';

   // Ajustamos alguns flags!   
   pItem->Capacity = pItem->Len = Length;
   return WX_SUCCESS;
}

/*
 * Retorna o valor string anexado ao item passado como argumento e opcionalmente
 * informa em *Length o tamanho da string retornada.
 * 31/07/2008 - 09:39:32
 */
char *RepositoryList_GetCPtr( PRepositoryItem pItem, ULONG *Length )
{
   HB_TRACE( HB_TR_DEBUG, ("  RepositoryList_GetCPtr(%p,%p) ", pItem, Length ));
// HB_TRACE( HB_TR_DEBUG, ("     pItem        --> %p", pItem, Length ));
// HB_TRACE( HB_TR_DEBUG, ("     pItem->Value --> %p", (pItem) ? pItem->Value : NULL ));
   
   if (!pItem || !pItem->Value)
   {
      if (Length) *Length = 0L;
      return NULL;
   }
      
   /* Ele necessita do tamanho da string? */
   if (Length)
   {
      if (pItem->Type == rtiItem)
         *Length = hb_itemGetCLen( (PHB_ITEM) pItem->Value );
      else 
         *Length = pItem->Len;
   }

   /* Se for um item, puxamos direto via API a string de retorno */
   if (pItem->Type == rtiItem)
      return hb_itemGetCPtr( (PHB_ITEM) pItem->Value );
   
   return (char *) pItem->Value;
}
