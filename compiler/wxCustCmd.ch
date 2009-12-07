// 08/04/2008 - 20:00:26
#translate TRUE         => .T.
#translate FALSE        => .F.

#command ?  [ <list,...> ]      =>  wxQout( <list> )
#command ?? [ <list,...> ]      => wxQQout( <list> )
#command ECHO  [ <list,...> ]   => wxQQout( <list> )
#command PRINT [ <list,...> ]   => wxQQout( <list> )
#command TEXT                   => text wxQOut,wxQQOut

#xtranslate Qout(               =>  wxQout(      // to avoid conflicts with [x]Harbour functions
#xtranslate QQout(              => wxQQout(      // to avoid conflicts with [x]Harbour functions
#xtranslate DispOut(            => wxQQout(      // to avoid conflicts with [x]Harbour functions
#xtranslate DevOut (            => wxQQout(      // to avoid conflicts with [x]Harbour functions

#define  CRLF (HB_OsNewLine())

#Command IF <Cond> THEN <*Cmd1*> ;
      => IF <Cond> ; <Cmd1> ; End
