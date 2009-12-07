#include "wxweb.ch"

FUNCTION Main()
   LOCAL oHtml
   LOCAL rec, acao, msg

   SET DEFAULT TO (wxExePath() + '..\')
   USE netest.dbf INDEX netest SHARED READONLY
   
   reg := wxGetField( 'registro' )
   acao:= wxGetField( 'Submit' )

   IF reg != NIL
      GOTO VAL(reg)
   End
      
   IF acao == NIL
      * Nao temos para fazer nada
   ELSEIF acao = 'Anterior'
      SKIP -1
   ELSEIF acao = 'Primeiro'
      GOTO TOP
   ELSEIF acao = 'Ultimo'
      GO BOTTOM
   ELSEIF acao = 'Proximo'
      SKIP +1
   End

   IF Eof()
      GO BOTTOM
      msg := "Ops... este é o ultimo registro!"
   End

   IF Bof()
      msg := "Este é o primeiro registro!"
   End

   oHtml=TWebTemplate():New()
   oHtml:LoadFromFile( wxExePath() + 'template.html' )
   
   oHtml:Params( 'cod', FIELD->COD )
   oHtml:Params( 'desc',FIELD->DESC )
   oHtml:Params( 'val', FIELD->VAL )
   oHtml:Params( 'msg', msg )
   oHtml:Params( 'est', FIELD->EST )
   oHtml:Params( 'rec', alltrim(str(RECNO())) )
   oHtml:Params( 'last', LASTREC() )
   oHtml:Renderize()
   RETURN