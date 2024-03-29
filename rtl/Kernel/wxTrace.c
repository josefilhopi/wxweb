/*
 * $Id: trace.c,v 1.20 2007/04/22 22:50:39 ronpinkas Exp $
 */

/*
 * Harbour Project source code:
 * The Clipper tracing API.
 *
 * Copyright 1999 Gonzalo A. Diethelm <gonzalo.diethelm@iname.com>
 * www - http://www.harbour-project.org
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#include "hbapifs.h"
#include "hbapierr.h"

#ifdef HB_THREAD_SUPPORT
   static HB_CRITICAL_T s_CriticalMutex;
#endif

#define LOG_NAME  "wxTrace.Log"

// It is Thread Safe - It's manipulated only once at primary thread startup.
static BOOL s_bEmpty = TRUE;

void wxTraceInit( void )
{
   FILE *fpTrace;

   #ifdef HB_THREAD_SUPPORT
      HB_CRITICAL_INIT( s_CriticalMutex );
   #endif

   if( s_bEmpty && hb_fsFile( ( BYTE *) "trace.log" ) )
   {
      /* Empty the file if it exists. */
      fpTrace = fopen( LOG_NAME, "w" );

      if( fpTrace )
      {
         fclose( fpTrace );
      }
      else
      {
         hb_errInternal( HB_EI_ERRUNRECOV, "Unable to create trace.log file", NULL, NULL );
      }
   }
}

void wxTraceExit( void )
{
   #ifdef HB_THREAD_SUPPORT
      HB_CRITICAL_DESTROY( s_CriticalMutex );
   #endif
}

HB_EXPORT void wxTraceLog( const char * sTraceMsg, ... )
{
   char * sFile = NULL; 
   FILE *hFile;

   if( ! sTraceMsg )
   {
      return;
   }

   #ifdef HB_THREAD_SUPPORT
      HB_CRITICAL_LOCK( s_CriticalMutex );
   #endif

   if( sFile == NULL )
   {
      if( s_bEmpty )
      {
         s_bEmpty = FALSE;

         /* Empty the file if it exists. */
         hFile = fopen( LOG_NAME, "w" );
      }
      else
      {
         hFile = fopen( LOG_NAME, "a" );
      }
   }
   else
   {
      hFile = fopen( sFile, "a" );
   }

   if( hFile )
   {
      va_list ap;

      va_start( ap, sTraceMsg );
      vfprintf( hFile, sTraceMsg, ap );
      va_end( ap );

      vfprintf( hFile, "\n", NULL );
      fclose( hFile );
   }

   #ifdef HB_THREAD_SUPPORT
      HB_CRITICAL_UNLOCK( s_CriticalMutex );
   #endif
}

// 18/07/2008 - 09:29:10
HB_FUNC( WXTRACE )
{
   char *Text = hb_parcx(1);
   
   if (Text)
      wxTraceLog( Text );  
}
