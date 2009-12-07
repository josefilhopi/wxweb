#include "wxweb.ch"

REQUEST dbUseArea
REQUEST dbSkip

FUNCTION Main()
   LOCAL cModule := wxGetField( 'module' )
   LOCAL oScript

  ?? '<pre><code>'
  ?? 'Selecione uma opcao de script para execucao:'
   ?
   ? HRef( '?module=script1', 'Script 1 - Data e Hora' )
   ? HRef( '?module=script2', 'Script 2 - Listagem de Produtos' )
   ?
   ?

   IF cModule <> NIL
      oScript := TWebScript():New()
      oScript:LoadFromFile( wxExePath() + cModule + '.wxs' )
      oScript:Renderize()
      oScript:Unload()
   End

   ? '</code></pre>'
   RETURN