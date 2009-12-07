<HTML>
Este conteudo foi preenchido pelo script da wxWeb.<br><br>
<?

dia = date()

? dia

if day(dia) == 1
   ? '<br> Hoje e dia primeiro'
else
   ? '<br> Hoje e dia:', day( dia )
end

?>Agora iremos exibir 10 linhas seguidas:
<?
for i := 1 to 10
   ? i,'<br>'
end
?>
</HTML>
