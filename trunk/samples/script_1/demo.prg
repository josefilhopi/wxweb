#include "wxweb.ch"

FUNCTION Main()
   LOCAL oScript := TWebScript():New()
   
   /*
    * Este componente permite carrega o conteudo de um arquivo .WXS e executar
    * direto dentro da p gina.
    *
    * O arquivo .WXS ‚ gerado pelo compilador personalizado da WxWeb presente na
    * pasta COMPILER fornecido juntamente com a biblioteca. No prompt do DOS use
    * um comando semelhante a este:
    *
    * ..\..\Compiler\wxc.exe script.prg
    */
    
   IF !File( wxExePath() + 'script.wxs' )
      ? 'Execute a seguinte linha de comando:<br><b>wxcompiler.exe script.prg</b><br><br>para gerar o script.wxs necessario<br>para rodar este exemplo.'
      quit
   End
   
   oScript:LoadFromFile( wxExePath() + 'script.wxs' )
   oScript:Renderize()
   oScript:Unload()
   RETURN