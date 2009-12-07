/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Convertido p/ C : 27/07/2008 - 10:16:49
 *
 *  Orignal em C++ .: 11/12/2006 - 11:23:03
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxSession.c
 *                            
 *  Funções para manipulação de seções dentro da wxWeb!
 *
 *---------------------------------------------------------------------------*/
#ifndef WXSESSION_HEADER
   #define WXSESSION_HEADER

   WX_RES wxSession_Clear( PConnection pConn, BOOL Parcial );
   WX_RES wxSession_CreateNew( PConnection pClientConn );      
   PRepositoryItem wxSession_Find( PConnection pConn, char *KeyName );
   WX_RES wxSession_Load( PConnection pClientConn );
   WX_RES wxSession_ParseRawData( PConnection pClientConn, char *Buffer, ULONG Length ); 
   WX_RES wxSession_Start( PConnection pClientConn );
   WX_RES wxSession_Write( PConnection pClientConn );      
#endif
