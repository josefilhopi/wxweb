#include "wxweb.ch"

FUNCTION Main()

   IF wxGetFieldCount()<1
      ? '<html><body>'
      ? 'Por favor, <a href="form.html">clique aqui</a> para preencher o formulario de contato.'
      ? '</body>'
      ? '</html>'

      QUIT
   End

   ? 'Informacoes recebidas:'
   ? '<br><br>'
   for i := 1 to wxGetFieldCount()
       ? '<i>', wxGetFieldName(i), '</i><b>',wxGetField(i),'</b><br>'
   end
   ? '<br>'
   ? '<a href="form.html">Testar novamente.</a>'
   RETURN
