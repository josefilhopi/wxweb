#include "wxweb.ch"

FUNCTION Main()
   LOCAL oHtml
   LOCAL rec, acao, msg

   SET DEFAULT TO (wxExePath() + '..\')
   USE netest.dbf INDEX netest SHARED
   
   reg := wxGetField( 'registro' )
   acao:= wxGetField( 'Submit' )

   IF reg != NIL
      GOTO VAL(reg)
   End
      
   IF acao == NIL
      * Nao temos para fazer nada
   ELSEIF acao = 'Editar'
      RETURN Editar()
   ELSEIF acao = 'Salvar'
      RETURN Salvar()

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

   ExibeDados( msg )
   RETURN nil

/*
 * Exibe os dados do registro atual para o usuario
 */
PROCEDURE ExibeDados( cMsg )
   oHtml=TWebTemplate():New()
   oHtml:LoadFromFile( wxExePath() + 'template.html' )
   
   oHtml:Params( 'cod', FIELD->COD )
   oHtml:Params( 'desc',FIELD->DESC )
   oHtml:Params( 'val', FIELD->VAL )
   oHtml:Params( 'msg', cMsg )
   oHtml:Params( 'est', FIELD->EST )
   oHtml:Params( 'rec', alltrim(str(RECNO())) )
   oHtml:Params( 'last', LASTREC() )
   oHtml:Renderize()
   RETURN
   
/*
 * Se ele quiser editar os dados do registro atual, montamos o formulario
 * especifico para ele digitar as informações que ele precisa.
 * 25/11/2009 - 16:12:57
 */
PROCEDURE Editar()
   oHtml=TWebTemplate():New()
   oHtml:LoadFromFile( wxExePath() + 'form.html' )

   oHtml:Params( 'cod', alltrim( FIELD->COD ))
   oHtml:Params( 'desc',alltrim( FIELD->DESC ))
   oHtml:Params( 'val', alltrim( str( FIELD->VAL )) )
   oHtml:Params( 'est', FIELD->EST )
   oHtml:Params( 'rec', alltrim(str(RECNO())) )
   oHtml:Renderize()
   RETURN
   
/*
 * Se for para gravar os dados, iremos grava-los aqui nesta rotina!
 * 25/11/2009 - 16:13:33
 */
PROCEDURE Salvar()

   IF Eof()
      ? 'Registro nao encontrado no sistema!'
      QUIT
   End

   IF !RLock()
      ? 'Registro em uso por outra estacao!'
      QUIT
   End
   
   FIELD->COD  := wxGetField( 'cod' )
   FIELD->DESC := wxGetField( 'desc' )
   FIELD->VAL  := VAL( wxGetField( 'val' ) )
   DBCommit()
   
   ExibeDados( '' )
   RETURN