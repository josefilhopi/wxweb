/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 23/07/2008 - 14:40:00
 *
 *  Original.: 08/04/2008 - 22:42:39
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxWebScript.prg
 *                            
 *  Fun‡äes para leitura e execu‡Æo de Scripts no lado servidor gerados com o
 *  wxCompiler.exe ou harbour.exe
 *
 *---------------------------------------------------------------------------*/
// 
#include "wxWebFramework.ch"
#include "hbclass.ch"

CLASS TWebScript

 * Carrega o template armazenado em um arquivo
   METHOD LoadFromFile( cFileName )

 * Carrega o template armazenado em um arquivo um campo ou variavel de memoria
   METHOD LoadFrom( cBuffer )

 * Descarrega o template da memoria e libera recursos atualmente em uso.
   METHOD Unload()
   METHOD Clear()      

 * Gera um HTML com base nos parametros ativos
   METHOD Renderize()

 * Destructor da classe  
   DESTRUCTOR Destroy()
      
    * Indica erro em algum processo
      DATA cError                   INIT ''
      DATA cFileName                INIT ''                                      && Nome do script atualmente carregado na memoria - 28/10/2008 - 17:17:58
      DATA nType                    INIT WX_SCRIPT_NONE                          && Tipo de SCRIPT atualmente carregado: NONE, WXS, HTML

   HIDDEN:
    * Conteudo a ser processado para o site!
      DATA nHandle                  INIT 0
      DATA cInit                    INIT ''
      
    * Indica se h  necessidade de descarregarmos o template de memoria
      DATA lLoaded                  INIT False
END CLASS

/*
 * Garante que os dados da memoria sejam liberados!
 * 28/10/2008 - 18:04:09
 */
PROCEDURE Destroy() ;
   CLASS TWebScript

   ::Clear()
   RETURN

/*
 * Carrega um template armazenado em um arquivo para a memoria. Retorna um valor
 * num‚rico indicando se o processo foi bem sucedido ou nÆo.
 * 10/04/2008 - 15:10:50
 *
 * Possiveis valores de retorno sÆo:
 *   -1 - Erro: arquivo nao encontrado!
 *    0 - Ok, template carregado com sucesso!
 *   >0 - LoadFrom() erro! Consulte a fun‡Æo para averiguar a causa
 */
METHOD LoadFromFile( cFileName ) ;
   CLASS TWebScript

 * Existe o arquivo? Senao existir dˆ uma msg de erro avisando pelo-amor-de-Deus
 * 28/10/2008 - 17:39:11
   IF !File( cFileName )
      ::cError := 'TWebScript:LoadFromFile() error - script not found: '+cFileName
      ::nType  := WX_SCRIPT_NONE
      ::lLoaded:= False
      RETURN 1           
   End
   
   /* Liberamos quaisquer dados da memoria antes de prosseguir */ 
   RETURN ::LoadFrom( hb_MemoRead(cFileName), cFileName )

/*
 * Carrega o template armazenado em um arquivo um campo ou variavel de memoria.
 * Esta fun‡Æo retorna um valor num‚rico indicando se o processo foi bem sucedido
 * ou nÆo.
 * 10/04/2008 - 15:16:32
 *
 * Possiveis valores de retorno sÆo:
 *    0 - Ok, template carregado com sucesso!
 *    1 - Erro desconhecido
 */
METHOD LoadFrom( cBuffer, cFileName ) ;
   CLASS TWebScript

   LOCAL l,f,i
   LOCAL oError, bBlock

   bBlock := ErrorBlock( {|o| Break(o) })

   BEGIN SEQUENCE
      f := Substr(cBuffer,11, 65)
      i := At( chr(0), f )
      f := substr(f,1,i-1)
      
    * Antes de mais nada, h  algo para lermos?
      ::Clear()      
    
      L := Len( cBuffer )
      
    * Estamos tentando carregar um script .WXS??    
      IF L>4 .AND. LEFT( cBuffer, 4 ) == WXS_SIGNATURE
         ::nHandle := HB_HRBLOAD( cBuffer )

         // Valida o retorno da fun‡Æo!
         IF Valtype( ::nHandle ) == "P"
            ::cInit   := f
            ::lLoaded := .T.
            ::nType   := WX_SCRIPT_WXS
         End
      
    * Um arquivo .HTML, .TXT ou qqer outro. Este suporte foi adicionado em
    * 28/10/2008 - 17:58:50 
      ELSE
         ::cInit   := cBuffer
         ::lLoaded := .T.
         ::nType   := WX_SCRIPT_HTML
      End
      
      cBuffer := nil
      
      IF ::lLoaded THEN;
         ::cFileName := cFileName
         
   RECOVER USING oError
      ::cError := wxGetErrorMessage( oError )
      ::nType  := WX_SCRIPT_NONE
            
   End

 * Restauramos o code-block original para tratar de erros
   ErrorBlock( bBlock )

   IF Empty( ::cError ) THEN;
      RETURN 00
      
   RETURN 01

/*
 * Processa o conteudo do script atualmente carregado e ecoa o resultado para o
 * browser do usuario
 * 11/04/2008 - 23:22:54
 */
METHOD Renderize() ;
   CLASS TWebScript

 * Agora validamos se ele carregou e em caso negativo, exibimos a msg de erro
 * indicando a causa do problema!
   IF !Empty( ::cError )
      wxQQout( ::cError ) 
      RETURN Self
   End
   
 * Aqui chamamos hb_ExecFromArray() para processar o 'script'  
   IF ::nType == WX_SCRIPT_WXS
      Hb_ExecFromArray( ::cInit )
   
 * Aqui ecoamos o conteudo do arquivo atual na memoria para o usuario
   ELSEIF ::nType == WX_SCRIPT_HTML
      wxQQout( ::cInit )
 
 * Qualquer outro valor, iremos ecoar na tela a msg de erro!
   ELSE
      wxQQout( ::cError )
      
   End   
   RETURN Self

/*
 * Descarrega o script atual da memoria e libera os recursos mais importantes.
 * 11/04/2008 - 23:22:43
 */
METHOD UnLoad() ;
   CLASS TWebScript

   IF ValType( ::nHandle ) == "P" THEN;
      HB_HRBUNLOAD( ::nHandle )
    
   ::lLoaded := False
   ::nHandle := 0
   ::nType   := WX_SCRIPT_NONE
   ::cInit   := ''       
       
   RETURN Self
   

/*
 * O mesmo que o ::Unload() exceto que tb apaga o nome do arquivo carregado do disco
 * 28/10/2008 - 17:29:33
 */
METHOD Clear() ;
   CLASS TWebScript

   ::Unload()
   ::cFileName  := ''
   ::cError     := ''
       
   RETURN Self
   