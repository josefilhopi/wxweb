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
 *  Arquivo..: wxMemvar.h
 *                            
 *  Funções para manipulação de variaveis de memoria em nivel xBase
 *
 *---------------------------------------------------------------------------*/
#ifndef WXMEMVAR_HEADER  
   #define WXMEMVAR_HEADER
   
   #include <wxweb.h>
   #include "hbapi.h"
   
   char *wxMemvarGetCPtr( char * szVarName, ULONG *pulLen );
   int   wxMemvarGetNI( char * szVarName );
   LONG  wxMemvarGetNL( char * szVarName );
   int   wxMemvarPut( char * szVarName, PHB_ITEM pValue );

#endif
