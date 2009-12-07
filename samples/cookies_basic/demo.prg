#include "wxweb.ch"

   name := "myCookie"

// Atualizamos o cookie se ele existir. Caso o cookie não exista esta função irá
// criá-lo e ele estará disponível na próxima vez que o usuario executar este
// aplicativo novamente.
   SetCookie( name, time(), 360 )
   
   IF wxCookieExists( name )
      ? "O cookie " + name + " existe!", br()
      ? "Sua ultima visita a esta pagina foi em", ;
            wxUrlDecode( wxGetCookie( name ) )
   ELSE
      ? "O cookie " + name + " NAO existe!"
   End

   ? br()
   ? HREF( 'demo.exe', 'Clique aqui para atualizar' )
   ?