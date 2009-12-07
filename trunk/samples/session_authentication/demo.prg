#include 'wxWeb.ch'

REQUEST br, href
REQUEST directory
REQUEST dbUseArea
REQUEST DbSelectArea,dbSkip, dbGotop
REQUEST __dbLocate, Eof, Alltrim, Upper

function main()
   set date to brit
   set century on
   set deleted on
   set default to ( wxExePath() + 'dbf' )

   cPage := wxGetField('page')
   
   if Empty( cPage )
      cPage := 'index'
   end
   
   cPage   := wxExePath() + 'pages\' + cPage + '.wxs'
   oScript := TWebScript():New()
   oScript:LoadFromFile( cPage )
   oScript:Renderize() 
   oScript:Unload()
   RETURN

#ifdef XXX   
   
#include 'w:\wxweb\include\wxWeb.ch'
#include 'error.ch'

REQUEST wxWeb
REQUEST wxWebCGI

function main()
   session_start()
   if !session_exist('AUTH')
*    wxRedirect('./main.exe','module=login')
     wxRedirect('./mainw.exe','module=login')
      return
   endif
   
   printf( "Bem vindo %s, você está logado!", session( "auth" ))
#ifdef xx
   session_start()

   /* Se a condição abaixo for .T. não há session() aberta! */      
   if session( "id" ) = nil   
   
      /* A condicao abaixo será .T. se ele tiver preenchido o FORM de login */
      if wxGetField( "user" ) <> nil
         user := wxGetField( "user" )
         pass := wxGetField( "pass" )
         
         if Alltrim( Upper( user )) == 'WEB' .AND. ;
            Alltrim( Upper( pass )) == '123'
            session( "id", user )
            session( "login_time", time()) 
            ? wxRedirect( "protected_page.html" )
            return
         end
         
         /* Neste ponto, a senha informada não confere! Enviamos a msg de erro! */
         ? 'Usuario (',user,') e/ou senha (',pass,') incorretos!',br()
         ? href( 'login.html', 'Clique aqui para efetuar login!' )
         return
      
      /* Se nao preencheu o FORM, para prosseguir forçamos ele a fazer LOGIN */
      else
         ? 'Sessao nao existe!',br()
         ? href( 'login.html', 'Clique aqui para efetuar login!' )
         return
      end

   /* Ok, session() aberta e válida! Pode deixar ele passar */      
   else
      ? 'Seja bem vindo usuario',session('id'), br()
      ? 'voce se logou as',session('login_time'), br()
      ? href( 'login.html', 'Clique aqui para efetuar logoff!' )
      return
   end
#endif   
   ?      
   return   
#endif
