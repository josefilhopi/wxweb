#include "wxweb.ch"

FUNCTION Main()
   LOCAL oHtml
   
   IF wxGetFieldCount()<1
      ? '<html><body>'
      ? 'Por favor, <a href="pesq.html">clique aqui</a> para preencher o formulario de pesquisa.'
      ? '</body>'
      ? '</html>'

      QUIT
   End

   // Note que puxamos o campo enviado pela pagina HTML pelo seu "nome"
   codigo := wxGetField( 'codigo' )
   codigo := PADR( codigo, 10 )
   
   SET DEFAULT TO (wxExePath() + '..\')
   
   USE netest.dbf INDEX netest SHARED READONLY
   
   IF !dbSeek( codigo )
      ? 'Not Found!'
      ? 'Por favor, <a href="pesq.html">clique aqui</a> para preencher o formulario de pesquisa.'
      QUIT
   End
   
   oHtml=TWebTemplate():New()
   oHtml:LoadFromFile( wxExePath() + 'template.html' )
   oHtml:Params( 'cod', FIELD->COD )
   oHtml:Params( 'desc',FIELD->DESC )
   oHtml:Params( 'val', FIELD->VAL )
   oHtml:Params( 'est', FIELD->EST )
   oHtml:Renderize()
   RETURN