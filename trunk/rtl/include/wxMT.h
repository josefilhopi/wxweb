/*---------------------------------------------------------------------------
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado C ..: 23/11/2009 - 19:45:32
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxMT.h
 *
 *  Configurações específicas para habilitar o MT no xHB
 *
 *---------------------------------------------------------------------------*/

/*
 * To avoid some errors on HB+BCC
 * 23/11/2009 - 18:40:37
 */
#if !defined( HB_THREAD_STUB )
   #define HB_THREAD_STUB
#endif

