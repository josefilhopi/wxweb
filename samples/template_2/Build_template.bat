@ECHO OFF
REM Gerado pela xDev Studio v0.69 as 12/04/2008 @ 11:58:39
REM Compilador .: xHB build 0.99.61 (SimpLex) & BCC 5.5.1
REM Destino ....: W:\wxWeb\DEMOS\7. Template 02\template.EXE
REM Perfil .....: Batch file (Relative Paths)

REM **************************************************************************
REM * Setamos abaixo os PATHs necessarios para o correto funcionamento deste *
REM * script. Se voce for executa-lo em  outra CPU, analise as proximas tres *
REM * linhas abaixo para refletirem as corretas configuracoes de sua maquina *
REM **************************************************************************
 SET PATH=c:\xHB.0.99.61\bin;F:\Borland\BCC55\Bin;C:\Arquivos de programas\Borland\Delphi7\Bin;C:\Arquivos de programas\Borland\Delphi7\Projects\Bpl\;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\Arquivos de programas\ATI Technologies\ATI Control Panel;C:\Arquivos de programas\Arquivos comuns\Adobe\AGL;C:\ARQUIV~1\Griaule\FINGER~1\bin;C:\Arquivos de programas\QuickTime\QTSystem\
 SET INCLUDE=c:\xHB.0.99.61\include;F:\Borland\BCC55\include;;
 SET LIB=c:\xHB.0.99.61\lib;F:\Borland\BCC55\lib;F:\Borland\BCC55\lib\psdk;;

REM - Harbour.xCompiler.prg(97) @ 11:58:39:453
ECHO .ÿ
ECHO * (1/3) Compilando demo.prg
 harbour.exe ".\demo.prg" /q /o".\demo.c"   /M  /N  /P -DxHB  -DXHB_0990 -DXHB_0991 -DXHB_0992 -DXHB_0993 -DXHB_0994 -DXHB_09941 -DXHB_09950 -DXHB_09951a -DXHB_09951 -DXHB_09951b -DXHB_0996 -DXHB_09960 -DXHB_09961 
 IF ERRORLEVEL 1 GOTO FIM

REM - Harbour.xCompiler.prg(138) @ 11:58:39:515
 echo  -DxHB  -DXHB_0990 -DXHB_0991 -DXHB_0992 -DXHB_0993 -DXHB_0994 -DXHB_09941 -DXHB_09950 -DXHB_09951a -DXHB_09951 -DXHB_09951b -DXHB_0996 -DXHB_09960 -DXHB_09961 > "b32.bc"
 echo -I"c:\xHB.0.99.61\include;F:\Borland\BCC55\include;;" >> "b32.bc"
 echo -L"c:\xHB.0.99.61\lib;F:\Borland\BCC55\lib;F:\Borland\BCC55\lib\psdk;;;;;" >> "b32.bc"
 echo -o".\demo.obj" >> "b32.bc"
 echo ".\demo.c" >> "b32.bc"

REM - Harbour.xCompiler.prg(139) @ 11:58:39:531
ECHO .ÿ
ECHO * (2/3) Compilando demo.c
 BCC32 -M -c @B32.BC
 IF ERRORLEVEL 1 GOTO FIM

REM - Harbour.xCompiler.prg(285) @ 11:58:39:687
 echo -I"c:\xHB.0.99.61\include;F:\Borland\BCC55\include;;" + > "b32.bc"
 echo -L"c:\xHB.0.99.61\lib;F:\Borland\BCC55\lib;F:\Borland\BCC55\lib\psdk;;;;;" + >> "b32.bc"
 echo -Gn -M -m  -Tpe -s + >> "b32.bc"
 echo c0w32.obj +     >> "b32.bc"
 echo ".\demo.obj", +  >> "b32.bc"
 echo ".\template.EXE", +    >> "b32.bc"
 echo ".\template.map", +    >> "b32.bc"
 echo lang.lib +      >> "b32.bc"
 echo vm.lib +        >> "b32.bc"
 echo rtl.lib +       >> "b32.bc"
 echo rdd.lib +       >> "b32.bc"
 echo macro.lib +     >> "b32.bc"
 echo pp.lib +        >> "b32.bc"
 echo dbfntx.lib +    >> "b32.bc"
 echo dbffpt.lib +    >> "b32.bc"
 echo "W:\wxWeb\RTL\wxWeb.LIB" +   >> "b32.bc"
 echo common.lib +    >> "b32.bc"
 echo gtwin.lib +  >> "b32.bc"
 echo codepage.lib +  >> "b32.bc"
 echo pcrepos.lib +     >> "b32.bc"
 echo hbsix.lib +     >> "b32.bc"
 echo cw32.lib +      >> "b32.bc"
 echo import32.lib +  >> "b32.bc"
 echo rasapi32.lib + >> "b32.bc"
 echo nddeapi.lib + >> "b32.bc"
 echo iphlpapi.lib + >> "b32.bc"
 echo , >> "b32.bc"

REM - Harbour.xCompiler.prg(286) @ 11:58:39:687
ECHO .ÿ
ECHO * (3/3) Linkando template.EXE
 ILINK32 @B32.BC
 IF ERRORLEVEL 1 GOTO FIM

:FIM
 ECHO Fim do script de compilacao!
