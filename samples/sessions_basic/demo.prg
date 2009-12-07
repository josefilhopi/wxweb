#include "wxweb.ch"

   /*
    * o servidor seta via wxServer(SESSION_PATH) o path onde as sessäes devem ser
    * gravadas. Caso vc deseje alterar, pode-se utilizar a funcao abaixo... neste
    * caso, for‡amos todas as sessoes a serem gravadas na subpasta SESSIONS junto
    * ao local de onde este .EXE est  rodando.
    */
   Session_savepath( WXEXEPATH() + 'sessions' )
   Session_start()
   
   ?? '<pre><code>'   
   
   ? "Current session ID: ", Session_id()
   ?
   ? WXGETCOOKIECOUNT(),'Cookies found:'
   
   for i := 1 to WXGETCOOKIECOUNT()
       ? WXGETCOOKIENAME(i), WXGETCOOKIE(i)
   end
   
   ?
   ?

   if (SESSION_EXIST('char'))
      ? 'A previous saved session found!!'
      ? ''
      
      for i := 1 to session_count()
          n := session_getname(i)
          
          if valtype( session(n) ) == 'A'
            for r := 1 to len( session(n) )
                ? n+'['+alltrim(str(r))+']', hb_cstr( session(n)[r] )
            end
          else
            ? n, hb_cstr( session(n) )
          end
      end
      
      session( 'time'   , time() )
                  
   else
      ? 'Starting a new session...'
      
      session( 'char'   ,  "This is a single text" )    
      session( 'num'    , 29 )    
      session( 'date'   , date() )
      session( 'boolT'  , .T. )
      session( 'boolF'  , .F. )
      session( 'time'   , time() )            
      session( 'array'  , { .T., 0, date(), 'hi!', {|| nil } } )
   end    
   
   session( 'array' )[2] ++
   session( 'array' )[2] --
   session( 'array' )[2] ++

   ?? '</code></pre>'   

   ? br()
   ? HREF( 'demo.exe', 'Clique aqui para atualizar' )
   ?
   return
