/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado C ..: 09/07/2008 - 17:25:50
 *
 *  Revisado C++.: 16/12/2006 - 09:26:54
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxSerialize.h
 *                            
 *  Funções para resialização e deserialização de valores para a wxWeb!
 *
 *---------------------------------------------------------------------------*/

#ifndef WXSERIALIZE_HEADER
   #define WXSERIALIZE_HEADER
      
   #define SERIALIZE_HEADER_ITEM_SIZE     5
   #define MASK_TYPE(X)                   (X-64)
   #define MASK_TYPE_EX(X)                (X-29)
   #define _MASK_EX_(X)                   (X>33)
   #define _MASK_(C,L)                    ((L>255) ? MASK_TYPE_EX(C) : MASK_TYPE(C))
   #define UNMASK_TYPE(X)                 ((_MASK_EX_(X)) ? (X+29) : (X+64))

   char  wxItemType( PHB_ITEM Item );
   char *wxItemSerialize( PHB_ITEM Item, ULONG *Length, HB_FHANDLE hHandle );
   char *wxItemDeserialize( char *RawData, PHB_ITEM Item );
#endif
