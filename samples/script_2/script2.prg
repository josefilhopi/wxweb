CODIGO     DESCRICAO                                VALOR    ESTOQUE
===========================================================================<%

 USE ( wxExePath() + '..\NETEST' ) NEW ALIAS est SHARED READONLY
 

 DO WHILE !EOF()
    ? cod, desc, val, str(est,11,3)
    SKIP
 End
%>
===========================================================================
