#include "wxweb.ch"

FUNCTION Main()
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
      ? 'Nao encontrado!'
   ELSE
      ? 'CODIGO:', COD, '<br>'
      ? 'DESCRICAO:', DESC, '<br>'
      ? 'VALOR:', VAL, '<br>'
      ? '<br>'
   End
   
   ? '<a href="pesq.html">Pesquisar de novo.</a>'
   RETURN
