#include "wxweb.ch"

FUNCTION Main()

   IF wxGetFieldCount()<1
      ? '<html><body>'
      ? 'Por favor, <a href="ficha.html">clique aqui</a> para preencher a ficha cadastral.'
      ? '</body>'
      ? '</html>'

      QUIT
   End

   for i := 1 to wxGetFieldCount()
       ? '<i>', wxGetFieldName(i), '</i><b>',wxGetField(i),'</b><br>'
   end
   ? '<a href="ficha.html">Preencher a ficha cadastral.</a>'
   RETURN