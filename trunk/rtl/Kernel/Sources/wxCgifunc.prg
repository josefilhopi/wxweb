/*
 * $Id: cgifunc.prg,v 1.1 2006/06/11 22:38:56 fsgiudice Exp $
 */

/*
 * xHarbour Project source code:
 *   Utility functions for HTML LIB
 *
 * Copyright 2003-2006 Francesco Saverio Giudice <info / at / fsgiudice / dot / com>
 * www - http://www.xharbour.org
 * www - http://www.harbour-project.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version, with one exception:
 *
 * The exception is that if you link the Harbour Runtime Library (HRL)
 * and/or the Harbour Virtual Machine (HVM) with other files to produce
 * an executable, this does not by itself cause the resulting executable
 * to be covered by the GNU General Public License. Your use of that
 * executable is in no way restricted on account of linking the HRL
 * and/or HVM code into it.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA (or visit
 * their web site at http://www.gnu.org/).
 *
 */

#DEFINE CRLF   (CHR(13)+CHR(10))
#include "common.ch"

/**
 * DateToGMT( [<dDate>], [<cTime>], [<nDaysToAdd>], [<nSecsToAdd>] ) -> cGMTDate
 *
 * Formata a uma data e hora para uma string no formato GMT.
 *
 * @<dDate>    A data a ser convertida. Ser† assumido a data atual obtida com a
 *             funá∆o Date() caso seja omitido.
 *
 * @<cTime>    A hora no formato HH:MM[:SS]. Se omitido ser† assumido a hora e
 *             atual obtida com Time().
 *
 * @<nDaysToAdd> Adiciona em <dDate> a quantidade de dias informados Ö data antes
 *               da convers∆o. Pode ser passado um valor negativo neste parÉmetro.
 *
 * @<nSecsToAdd> Informa a quantidade de segundos Ö serem acrescidos Ö <dDate> e
 *               <cTime> antes da convers∆o.
 * <sample>
 * #include "wxweb.ch"
 *
 * FUNCTION main()
 *
 *    dHoje := date()               // 10/31/2003
 *
 *    ? DateToGMT( dHoje )          // exibe "Saturday, 31-Oct-03 00:00:00 GMT".
 *
 *    RETURN nil
 * </sample>
 */
FUNCTION DateToGMT( dDate, cTime, nDayToAdd, nSecsToAdd )
  LOCAL cOldDateFormat := Set( _SET_DATEFORMAT, "dd-mm-yy" )
  LOCAL cStr, nDay, nMonth, nYear, nDoW
  LOCAL aDays   := { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
  LOCAL aMonths := { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

  DEFAULT dDate      TO DATE()
  DEFAULT cTime      TO TIME()
  DEFAULT nDayToAdd  TO 0
  DEFAULT nSecsToAdd TO 0
   
  cTime := AddSecondsToTime( cTime, nSecsToAdd, @nDayToAdd )
  dDate += nDayToAdd

  nDay   := Day( dDate )
  nMonth := Month( dDate )
  nYear  := Year( dDate)
  nDoW   := Dow( dDate )

  cStr := aDays[ nDow ] + ", " + StrZero( nDay, 2 ) + "-" + aMonths[ nMonth ] + "-" + ;
            StrZero( nYear, 4 ) + " " + cTime + " GMT"

  Set( _SET_DATEFORMAT, cOldDateFormat )

RETURN cStr

/**
 * AddSecondsToTime( [<cTime>],  <nSecsToAdd>, [<@nDaysAdded>] ) -> cNewTime
 *
 * Acrescenta Ö uma string no formato HH:MM:SS a quantidade de segundos ou dias
 * solicitados.
 *
 * 22/11/2006 - 10:00:00
 *
 * @<cTime>      Determina horario base sobre o qual iremos operar. Se omitido
 *               ser† assumido a hora atual obtida com a uso da funá∆o Time().
 *
 * @<nSecsToAdd> Informa a quantidade de segundos que desejamos somar em <cTime>
 *               Se omitido ser† assumido o valor 0 e o valor original informado
 *               em <cTime> ser† retornado pela funá∆o.
 *
 * @<nDaysAdded> Parametro passado por referància que conter† a quantidade de dias
 *               que foram adicionados ou subtraidos Ö <cTime> caso o n£mero de
 *               segundos seja maior que 86400 (repesentando 1 dia inteiro).
 *
 */
FUNCTION AddSecondsToTime( cTime, nSecsToAdd, nDaysAdded )
  LOCAL nOneDaySeconds := 86400  // 24 * 60 * 60
  LOCAL cNewTime, nSecs

  DEFAULT cTime      TO TIME()
  DEFAULT nSecsToAdd TO 0
  DEFAULT nDaysAdded TO 0      // nDaysAdded can be already valued, so below i add to this value

  IF nSecsToAdd <> 0
     nSecs      := TimeAsSeconds( cTime ) + nSecsToAdd
     nDaysAdded += Int( nSecs / nOneDaySeconds )  // Attention! nDaysAdded can be already filled
     nSecs      := nSecs - nDaysAdded
     cNewTime   := TimeAsString( nSecs )
  ELSE
     cNewTime := cTime
  ENDIF
  RETURN cNewTime

/**
 * TimeDiffAsSeconds( <dDateStart>, <dDateEnd>, [<cTimeStart>], [<cTimeEnd>] ) -> nSeconds
 *
 * Retorna a diferenáa em segundos entre duas datas e/ou dois hor†rios fornecidos.
 * 22/11/2006 11:41:31
 *
 * @<dDateStart>     Data inicial para comparaá∆o.
 * @<dDateEnd>       Data final para comparaá∆o
 * @<cTimeStart>     Hor†rio inicial para comparaá∆o. Ser† assumido '00:00:00' se omitido.
 * @<cTimeEnd>       Hor†rio final para comparaá∆o. Ser† assumido '00:00:00' se omitido.
 *
 */
FUNCTION TimeDiffAsSeconds( dDateStart, dDateEnd, cTimeStart, cTimeEnd )
  LOCAL aRetVal

  DEFAULT dDateEnd     TO DATE()
  DEFAULT cTimeEnd     TO TIME()

  aRetVal := FT_ELAPSED( dDateStart, dDateEnd, cTimeStart, cTimeEnd )

RETURN aRetVal[ 4, 2 ]

/* 
 * Para anular as chamadas externas
 * 22/11/2006 11:41:31
 */  
STATIC; 
FUNCTION FT_ELAPSED(dStart, dEnd, cTimeStart, cTimeEnd)
  LOCAL nTotalSec, nCtr, nConstant, nTemp, aRetVal[4,2]

  IF ! ( VALTYPE(dStart) $ 'DC' )
     dStart := DATE()
  ELSEIF VALTYPE(dStart) == 'C'
     cTimeStart := dStart
     dStart     := DATE()
  ENDIF

  IF ! ( VALTYPE(dEnd) $ 'DC' )
     dEnd := DATE()
  ELSEIF VALTYPE(dEnd) == 'C'
     cTimeEnd := dEnd
     dEnd     := DATE()
  ENDIF

  IF( VALTYPE(cTimeStart) != 'C', cTimeStart := '00:00:00', )
  IF( VALTYPE(cTimeEnd)   != 'C', cTimeEnd   := '00:00:00', )

  nTotalSec  := (dEnd - dStart) * 86400                              + ;
                VAL(cTimeEnd)   *  3600                              + ;
                VAL(SUBSTR(cTimeEnd,AT(':', cTimeEnd)+1,2)) * 60     + ;
                IF(RAT(':', cTimeEnd) == AT(':', cTimeEnd), 0,         ;
                VAL(SUBSTR(cTimeEnd,RAT(':', cTimeEnd)+1)))          - ;
                VAL(cTimeStart) * 3600                               - ;
                VAL(SUBSTR(cTimeStart,AT(':', cTimeStart)+1,2)) * 60 - ;
                IF(RAT(':', cTimeStart) == AT(':', cTimeStart), 0,     ;
                VAL(SUBSTR(cTimeStart,RAT(':', cTimeStart)+1)))

  nTemp := nTotalSec

  FOR nCtr = 1 to 4
     nConstant := IF(nCtr == 1, 86400, IF(nCtr == 2, 3600, IF( nCtr == 3, 60, 1)))
     aRetVal[nCtr,1] := INT(nTemp/nConstant)
     aRetval[nCtr,2] := nTotalSec / nConstant
     nTemp -= aRetVal[nCtr,1] * nConstant
  NEXT
RETURN aRetVal
