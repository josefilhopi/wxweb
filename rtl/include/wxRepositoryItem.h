/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 07/07/2008 - 18:56:11
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxRepositoryItem.h
 *                            
 *  Funções para manipulação de "pedaços" de informações
 *
 *---------------------------------------------------------------------------*/
#ifndef WXREPOSITORY_HEADER  
   #define WXREPOSITORY_HEADER
   #include "hbdefs.h"
   #include "hbapiitm.h"
   
   /*
    * Representa um COOKIE ou qqer coisa do tipo =P
    * 9/12/2006 08:13:25
    */
   typedef enum { rtiValue, rtiItem } TRepositoryItemType;
                  
   /*
    * Representa cada item individual de texto a ser bufferizado.
    * 03/07/2008 - 23:12:54
    */
   typedef struct _RepositoryItem
   {
      TRepositoryItemType Type;
      WX_PTR Key;           // como string, contendo o NOME do valor para localização futura
      WX_PTR Value;         // o valor do objeto em si. Podendo ser STRING ou PHB_ITEM

      ULONG Capacity;       // se for STRING, qual o tamanho TOTAL do buffer disponivel.
      ULONG Len;            // se for STRING, este é o tamanho real da string contida em Value
      
      struct _RepositoryItem *pNext;
   } TRepositoryItem;
   
   typedef TRepositoryItem *PRepositoryItem;
      
   PRepositoryItem RepositoryList_Create( void );
   WX_RES RepositoryList_Destroy( PRepositoryItem pBuffer );
   WX_RES RepositoryList_Finalize( PRepositoryItem pBuffer );
   
   PRepositoryItem RepositoryList_AddStr ( PRepositoryItem pBuffer, BYTE *Source, ULONG Length, BOOL bInsertCRLF );
   PRepositoryItem RepositoryList_AddItem( PRepositoryItem pBuffer, PHB_ITEM pItem );
   
   WX_RES RepositoryList_UpdateStr ( PRepositoryItem pItem, BYTE *Source, ULONG Length );
   WX_RES RepositoryList_UpdateItem( PRepositoryItem pItem, PHB_ITEM pValue );
   WX_RES RepositoryList_UpdateStrPtr( PRepositoryItem pItem, BYTE *Source, ULONG Length );
   char *RepositoryList_GetCPtr( PRepositoryItem pItem, ULONG *Length );

#endif
