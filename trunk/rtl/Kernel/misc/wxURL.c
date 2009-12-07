/*--------------------------------------------------------------------------- 
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado.: 14/11/2006 10:13:47
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxURL.c
 *                            
 *  Rotinas para manipulação de strings
 *
 *---------------------------------------------------------------------------*/

#include "hbapi.h"
#include "hbapiitm.h"
#include <ctype.h>
#include <wxMT.h>

static 
int isValidDigit(unsigned char c)
{
  if ((c >= 0x30 && c <= 0x39) ||   // 0 .. 9
      (c >= 0x41 && c <= 0x46) ||   // A .. F 
      (c >= 0x61 && c <= 0x66))     // a .. f
   return 1;
  
  return 0;
}

/*
 * Converte a string de HEX para INT.. a string tem que ter no minimo 2 bytes
 */
static 
char Hex2Int(char *s)
{
	unsigned char *b = (unsigned char *) s;
   int value;
	int c;
	
	c = tolower(*b); b++;	
	value = (c >= '0' && c <= '9' ? c - '0' : c - 'a' + 10) * 16;

	c = tolower(*b);
	value += c >= '0' && c <= '9' ? c - '0' : c - 'a' + 10;

	return ((char) value);
}

/*
 * Converte a a URL passada como parametro para um string normal, reutilizando o
 * buffer passado como argumento. Retorna o total de bytes da nova string convertida.
 *
 * A função que nos chamar, deve liberar o buffer de retorno usando hb_xfree()
 * 16/07/2008 - 14:21:49
 */
char *wxUrlDecode( char *Text, ULONG Length, ULONG *out_size )
{
	char *Result, *Buffer;

   /*
    * Quando se usa uma variavel de memoria como parametro, o seu endereçamento
    * de memoria é 'compartilhado' com suas cópias. Isto pode afetar o comporta-
    * mento do seu sistema de modo imprevisto. 
    *
    * Se desejar evitar este problema, passe o ultimo parametro como TRUE e um
    * novo BUFFER será criado para conter o resultado desta memoria. Deixando-o
    * como FALSE o desempenho será melhor.
    */
   Buffer = (char *) hb_xgrab( Length + 1 );
   Result = Buffer;

	while (Length--)
   {
		if (*Text == '+') 
      {
			*Result = ' ';
		} else {
         if ((*Text == '%') && 
             (Length >= 2) && 
             (isValidDigit((unsigned char) *(Text + 1))) &&
	          (isValidDigit((unsigned char) *(Text + 2)))) 
         {   
   		  *Result  = Hex2Int(Text + 1);
   			Text   += 2;
   			Length -= 2;
   		} else {                                       
   		  *Result  = *Text;
   		}
		}
		Text++; Result++;
	}
  *Result = '\0';
  
	if (out_size)
	   *out_size = Result - Buffer;
	   
   return Buffer;
}

/* 
 * Retorna uma string em que todos os caracteres não-alfanuméricos serão 
 * substituidos com um sinal de porcento (%) siguido por dois digitos hexadecimais 
 * e espaços codificados como um sinal de (+).
 */
char *wxUrlEncode( char *s, ULONG len, ULONG *out_size)
{
   unsigned char hex[] = "0123456789ABCDEF";
	unsigned char c;        
	unsigned char *Buffer, *Text;
	unsigned char *from, *end;
	
	from = s;
	end  = s + len;
	Text = Buffer = (unsigned char *) hb_xgrab((3 * len)+1);

	while (from < end)
   {
		c = *from++;

		if (c == ' ')
      {
			*Buffer++ = '+';
		} else {
         if ((c < '0' && c != '-' ) ||
		       (c < 'A' && c > '9') ||
			    (c > 'Z' && c < 'a') ||
			    (c > 'z')) 
         {
   			Buffer[0] = '%';
   			Buffer[1] = hex[c >> 4];
   			Buffer[2] = hex[c & 15];
   			Buffer += 3;
   		} else {
   			*Buffer++ = c;
   		}
		}
	}
	
	*Buffer = 0;
	if (out_size) 
		*out_size = Buffer - Text;
		
	return (char *) Text;
}

/*
 * [x]HB interface
 */
HB_FUNC( WXURLDECODE )
{
   HB_THREAD_STUB           
   char *Text   = hb_parc(1);
   ULONG Length = hb_parclen(1);
   char *Result;
   ULONG Size;
          
   Result = wxUrlDecode( Text, Length, &Size );
   hb_retclen_buffer( Result, Size );
}

HB_FUNC( WXURLENCODE )
{
   HB_THREAD_STUB   

	char *in;
   char *out;
	ULONG in_len, out_len;

// Parametro passado nao é caracter? Sai fora...
   if (ISCHAR(1))
   {
      in = hb_parcx(1);
      in_len = hb_parclen(1);
      out_len = 0L;
   	out = wxUrlEncode( in, in_len, &out_len);
   	hb_retclen_buffer( (char *) out, out_len);
	} else 
      hb_retc("");
}

/*
 * 22/11/2006 12:18:49
 * Valida os caracteres dentro da string para validar corretamente.
 */
HB_FUNC( __ISVALIDCOOKIENAME )
{   
   HB_THREAD_STUB   

   if (ISCHAR(1))
   {
      char *name = hb_parcx(1);

      if (name && strpbrk(name, "=,; \t\r\n\013\014") != NULL)
         hb_retl(0);
      else
    	   hb_retl(1);            
	} else {
	  hb_retl(0);
   }   
}

/*
 * 22/11/2006 12:18:49
 * Valida os caracteres dentro da string para validar corretamente.
 */
HB_FUNC( __ISVALIDCOOKIEVALUE )
{   
   HB_THREAD_STUB   

   if (ISCHAR(1))
   {
      char *name = hb_parcx(1);

      if (name && strpbrk(name, ",; \t\r\n\013\014") != NULL)
         hb_retl(0);
      else
    	   hb_retl(1);            
	} else {
	  hb_retl(0);
   }   
}
