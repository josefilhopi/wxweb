/* 
   wxBase64.c and wxBase64.h

   Copyright (C) 2004-2008 René Nyffenegger

   This source code is provided 'as-is', without any express or implied
   warranty. In no event will the author be held liable for any damages
   arising from the use of this software.

   Permission is granted to anyone to use this software for any purpose,
   including commercial applications, and to alter it and redistribute it
   freely, subject to the following restrictions:

   1. The origin of this source code must not be misrepresented; you must not
      claim that you wrote the original source code. If you use this source code
      in a product, an acknowledgment in the product documentation would be
      appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
      misrepresented as being the original source code.

   3. This notice may not be removed or altered from any source distribution.

   René Nyffenegger rene.nyffenegger@adp-gmbh.ch

*/
#include <wxweb.h>
#include "hbapi.h"
#include "hbapiitm.h"
#include "wxBase64.h"
#include <wxTrace.h>

static char base64_chars[] = { "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" };

static 
int is_base64(unsigned char c)
{
  return (isalnum(c) || (c == '+') || (c == '/'));
}

char *wxBase64_Decode( unsigned char const *encoded_string, ULONG in_len, ULONG *out_len )
{
  int i = 0;
  int j = 0;
  int l = 0;
  int in_ = 0;
  unsigned char char_array_4[4], char_array_3[3];
  char *ret, *rst, *t;

  HB_TRACE( HB_TR_DEBUG, ("wxBase64_Decode( '%s', %d )", encoded_string, in_len ));
  HB_TRACE( HB_TR_DEBUG, ("  hb_xgrab( %d )", (in_len / 4 + 1) * 3 ));
  
  ret = (unsigned char *) hb_xgrab( (in_len / 4 + 1) * 3 );
  rst = ret; ret[0] = '\0';
  *out_len = 0;
  
  while (in_len-- && ( encoded_string[in_] != '=') && is_base64(encoded_string[in_]))
  {
    char_array_4[i++] = encoded_string[in_]; in_++;
    if (i ==4) {
    
      for (i = 0; i <4; i++)
      {
         t = strchr( base64_chars, char_array_4[i] );         
         char_array_4[i] = (t) ? t - base64_chars : 0;
      }
      
      char_array_3[0] =  (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
      char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
      char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

      for (i = 0; (i < 3); i++, ret++, l++)
        *ret = char_array_3[i];
      i = 0;
    }
  }

  if (i) {
    for (j = i; j <4; j++)
      char_array_4[j] = 0;

    for (j = 0; j <4; j++)
    {
      t = strchr( base64_chars, char_array_4[j] );         
      char_array_4[j] = (t) ? t - base64_chars : 0;
    }

    char_array_3[0] =  (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
    char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
    char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

    for (j = 0; (j < i - 1); j++, ret++, l++) 
        *ret = char_array_3[j];
  }
  
  *ret = '\0';
  *out_len = (ret - rst);
  HB_TRACE( HB_TR_DEBUG, ("  result -> '%s' / %d", rst, *out_len ));
  return rst;
}

char* wxBase64_Encode(unsigned char const* bytes_to_encode, ULONG in_len, ULONG *out_len )
{
  int i = 0;
  int j = 0;
  char *ret, *rst;
  unsigned char char_array_3[3];
  unsigned char char_array_4[4];

  HB_TRACE( HB_TR_DEBUG, ("wxBase64_Encode( '%s', %d  )", bytes_to_encode, in_len ));

  *out_len = 0;
   
  if ((in_len + 2) < 0 || ((in_len + 2) / 3) >= (1 << (sizeof(int) * 8 - 2)))
  {
      HB_TRACE( HB_TR_DEBUG, ("  result -> '%s' / %d", NULL, *out_len ));
      return NULL;
  }

  ret = (unsigned char *) hb_xgrab( (((in_len + 2) / 3) * 4) +1 );
  rst = ret; ret[0] = '\0';
  
  while (in_len--)
  {
    char_array_3[i++] = *(bytes_to_encode++);
    
    if (i == 3)
    {
      char_array_4[0] = ( char_array_3[0] & 0xfc) >> 2;
      char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
      char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
      char_array_4[3] =   char_array_3[2] & 0x3f;

      for(i = 0; (i <4) ; i++, ret++)
        *ret = base64_chars[char_array_4[i]];
        
      i = 0;
    }
  }

  if (i)
  {
    for(j = i; j < 3; j++)
      char_array_3[j] = '\0';

    char_array_4[0] = ( char_array_3[0] & 0xfc) >> 2;
    char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
    char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
    char_array_4[3] =   char_array_3[2] & 0x3f;

    for (j = 0; (j < i + 1); j++, ret++)
      *ret = base64_chars[char_array_4[j]];

    while((i++ < 3))
    {
      *ret = '=';
       ret++;
    }
  }
  *ret = '\0';
  *out_len = (ret - rst);
  
  HB_TRACE( HB_TR_DEBUG, ("  result -> '%s' / %d", rst, *out_len ));
  return rst;
}

/*
 * wxBase64_Encode( <cText> ) --> cEncrypt
 * Codifica a string passada como argumento e obtém o seu valor criptografado  
 * utilizando-se como base o algoritmo Base64.
 *
 * Consulte:
 * http://en.wikipedia.org/wiki/Base64
 *
 * 06/08/2008 - 07:46:04
 */
HB_FUNC( WXBASE64_ENCODE )
{
   char *Text;
   char *Result;
   ULONG Length, Size = 0;
      
   if (!ISCHAR(1))
   {           
      hb_retc( "" );
      return;
   }
   
   Text   = hb_parcx(1);
   Length = hb_parclen(1);
   
   if (Length<1)
   {
      hb_retc( "" );
      return;
   }
   
   Result = wxBase64_Encode( Text, Length, &Size );
   
   if (Result)
      hb_retclenAdopt( Result, Size );
   else
      hb_retc( "" );   
}

/*
 * wxBase64_Decode( <cEncrypt> ) --> cText
 * Decodifica a string passada como argumento e obtém o seu valor original com 
 * base no algoritmo Base64.
 *
 * Consulte:
 * http://en.wikipedia.org/wiki/Base64
 *
 * 21/07/2008 - 22:25:21
 */
HB_FUNC( WXBASE64_DECODE )
{
   char *Text;
   char *Result;
   ULONG Length, Size = 0;
      
   if (!ISCHAR(1))
   {           
      hb_retc( "" );
      return;
   }
   
   Text   = hb_parcx(1);
   Length = hb_parclen(1);
   
   if (Length<1)
   {
      hb_retc( "" );
      return;
   }
   
   Result = wxBase64_Decode( Text, Length, &Size );
   
   if (Result)
      hb_retclenAdopt( Result, Size );
   else
      hb_retc( "" );
}
