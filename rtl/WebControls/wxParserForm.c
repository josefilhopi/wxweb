/*---------------------------------------------------------------------------
 *
 *  Projeto WxWeb
 *
 *  Inicio...: Maio / 2006
 *
 *  Revisado C ..: 06/10/2008 - 21:26:50
 *
 *  Revisado C++.: 28/09/2008 - 14:10
 *
 *  Por......: Vailton Renato da Silva
 *
 *  Arquivo..: wxParserForm.c
 *                            
 *  Funções para desmontar um formulario desenhad via IDE
 *
 *---------------------------------------------------------------------------*/
#include "string.h"
#include "stdio.h"
#include "ctype.h"

#include "hbvmopt.h"
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapierr.h"

#include <wxweb.h>
#include "hbstack.h"
#include "hbmath.h"
#include "hbvm.h"
#include "error.ch"

#ifdef HB_OS_WIN
   #include <io.h>
// #include <Winbase.h>
#endif

#include <wxMemory.h>
#include <wxTrace.h>

   #define ReadType(x)     ( (TValueType) (*(x)))
   
typedef enum {
//                0        1     2        3        4        5
               vaNull, vaList, vaInt8, vaInt16, vaInt32, vaExtended,
  //  6           7       8         9     10       11       12
    vaString, vaIdent, vaFalse, vaTrue, vaBinary, vaSet, vaLString,
  //  13       14          15       16          17          18
    vaNil, vaCollection, vaSingle, vaCurrency, vaDate, vaWString,
  //  19       20
    vaInt64, vaUTF8String} TValueType;  

typedef struct _FORM_DATA
{
   char *buff;
   char *orig;
   char *end;
   ULONG Length;
   
   PHB_ITEM  pItem;
} FORM_DATA;

char *ReadString( char *buff, long StrLen, char *OutPut, long *OutPutSize, long MaxSize )
{                           
   char *S = OutPut;
   HB_TRACE( HB_TR_DEBUG, ("ReadString( '%s', %lu, %p, %p, %lu ) ||", buff, StrLen, OutPut, OutPutSize, MaxSize ));
   
   S[0] = '\0';
   
   if (!buff)
      return NULL;
      
   memcpy( S, buff, StrLen );
   S[StrLen] = '\0';
   
   buff += StrLen;
   
   if (OutPutSize)
      *OutPutSize = StrLen;
      
   return buff;    
}

char *ReadSet( char *buff, char *OutPut, long *OutPutSize, long MaxSize )
{
   char S[256];
   long L;
   
   OutPut[0] = '\0';
   
   while (buff && *buff)
   {   
      buff = ReadString( buff+1, (unsigned char) *buff, S, &L, 255 );
    
      if (OutPut[0])
         strcat( OutPut, "," );   
      
      strcat( OutPut, S );   
   }
   
   if (OutPutSize)
      *OutPutSize = strlen( OutPut );
   
   if (buff) buff++;
   return buff;
}

char *ReadListStr( char *buff )
{
   char S[65535 +1];
   char *T;
   long L,N,M;
        
   S[0] = '\0';
   T = S;
   L = 65535;
   N = M = 0L;
                  
//cout << " *** ReadListStr( " << buff << ") " << endl;   
   while (buff && *buff)
   {   
      switch (ReadType( buff ))
      {
         case vaString:
            buff ++;
            buff = ReadString( buff+1, (unsigned char) *buff, T, &N, L);
            break;
                  
         case vaUTF8String:
            buff ++;
            buff = ReadString( buff+4, * (int *) buff, T, &N, L);
            break;      
            
         default:
            break;         
      } 

      T += N;            

      // So coloca CRLF se existir algo a mais para ser adicionado!
      if (*buff)
      {
         memcpy( T, "\n\0", 2 );
         T += 1;
      }       
      L -= N; M += N;
   }
//cout << "[[" << S << "]]" << endl;
   buff++;
   return buff;
}

static PHB_ITEM wxCreateNewOBJ( char *ClsName )
{
   PHB_ITEM pItem;
   PHB_DYNS pExecSym;

   HB_TRACE( HB_TR_DEBUG, ("wxCreateNewOBJ(%s)", ClsName ));
   pItem = hb_itemNew( NULL );

   pExecSym = hb_dynsymFind( ClsName );
   HB_TRACE( HB_TR_DEBUG, ("pExecSym --> %p", pExecSym));
   
   if (!pExecSym)
   {
      hb_errRT_BASE_SubstR( EG_NOFUNC, 1001, "Missing class", ClsName, 0 );
      return NULL;
   }
      
   hb_vmPushSymbol( pExecSym->pSymbol );
   hb_vmPushNil();
   hb_vmDo( 0 );

   /* The node is in the return */
   hb_objSendMsg( hb_stackSelfItem(), "NEW", 0 );
   hb_itemCopy( pItem, hb_stackSelfItem() );

   HB_TRACE( HB_TR_DEBUG, ("  RETURN ---> (%p)", pItem ));
   return pItem;
}

// 06/10/2008 - 23:35:41
static void wxObjSetProp( PHB_ITEM pObj, char *cProp, PHB_ITEM pValue )
{
   char n[66];   
   char *p;
   int i,l;
   
   p = n;
  *p = '_';
   
   for ( p++; *cProp; cProp++ )
       if (*cProp != '.')
       {
          *p = toupper( *cProp );
           p++;
       }
  *p = '\0';
   
   HB_TRACE( HB_TR_DEBUG, ("wxObjSetProp(%p '%c','%s' || '%s',%p)", pObj, (char) wxItemType(pObj), cProp, n, pValue ));
   if (!hb_objHasMsg( pObj, n ))
   {
      PHB_ITEM pProp;
      HB_TRACE( HB_TR_DEBUG, ("     Ele NAO tem esta propriedade --> %s", n ));

      pProp = hb_itemPutC( NULL, n );
      hb_objSendMsg( pObj, "SetPropValue", 2, pProp, pValue );
      hb_itemRelease( pProp );
   } else {
      HB_TRACE( HB_TR_DEBUG, ("     Ele TEM SIM esta propriedade --> %s", n ));
      hb_objSendMsg( pObj, n, 1, pValue );
   }
   return;
}

PHB_ITEM RestoreObj( FORM_DATA *pForm, char *PropValue )
{
   char ClsName[256];                          
   char Value[256];
   char PropName[256];
   char c;
   int i;
   long len;
   TValueType type;

   PHB_ITEM pItem, pTemp;
   HB_ITEM  pValue;
   PHB_DYNS pExecSym;
   
   if (*pForm->buff == '\0')
      pForm->buff++;
   
   pForm->buff = ReadString( pForm->buff+1, (unsigned char) *pForm->buff, ClsName, NULL, 255 );
   
   HB_TRACE( HB_TR_DEBUG, ("Class  ..: %s", ClsName ));      
   //cout << spc << "Class  ..: " << ClsName << endl;

   pForm->buff = ReadString( pForm->buff+1, (unsigned char) *pForm->buff, Value, NULL, 255 );

   HB_TRACE( HB_TR_DEBUG, ("Name ....: %s", Value ));
   //cout << spc << "Name   ..: " << Value << endl;

   xStrUpper( ClsName, -1 );

   if (PropValue)
   {
      *PropValue = '\0';
      strcat( PropValue, Value );
      xStrUpper( PropValue, -1 );
   }
   pItem = wxCreateNewOBJ( ClsName );
   
   if (!pItem)
      return NULL;
      
   /*
   if (Value && *Value)
   {
      PHB_ITEM pObjName = hb_itemPutC( NULL, Value ); 
      wxObjSetProp( pItem, "NAME", pObjName );
      hb_itemRelease( pObjName );
   }   
   /*
    * O primeiro passo seria convertermos as propriedades.
    * 08/09/2008 - 10:35:54
    */
   while ( pForm->buff && ReadType(pForm->buff) != vaNull )
   {
      pForm->buff = ReadString( pForm->buff+1, (unsigned char) *pForm->buff, PropName, &len, 255 );      
      HB_TRACE( HB_TR_DEBUG, ("Property : %s", PropName ));
      
      if (pForm->buff == NULL) break;
      
      type = ReadType( pForm->buff );
      pForm->buff++;
      
      HB_TRACE( HB_TR_DEBUG, ("Value ...: " ));

      switch (type)
      {  
         case vaList:
         {
            switch(ReadType( pForm->buff ))
            {
               case vaString:
               case vaUTF8String:
                  pForm->buff = ReadListStr( pForm->buff );
                  break;
                                                   
               default:
                  break;
            }               
            break;
         }               
         case vaInt8:
              i = (int) *pForm->buff;                                           // 1 byte  do Delphi para int
              pForm->buff ++; 
              hb_itemPutNI( &pValue, i );
              wxObjSetProp( pItem, PropName, &pValue );
//cout << i << endl;
            break;
             
         case vaInt16: 
              i = * (short int *) pForm->buff;                                  // 2 bytes do Delphi para (unsigned char *)
              pForm->buff += 2; 
              hb_itemPutNI( &pValue, i );
              wxObjSetProp( pItem, PropName, &pValue );
//cout << i << endl;
            break;
             
         case vaInt32:
            i = * (int *) pForm->buff;                                          //4 bytes do Delphi (int*) ou (long*)
//cout << i << endl;
            pForm->buff += 4; 
            hb_itemPutNI( &pValue, i );
            wxObjSetProp( pItem, PropName, &pValue );
            break;
    
         case vaString:
            pForm->buff = ReadString( pForm->buff+1, (unsigned char) *pForm->buff, Value, &len, 255 );
            hb_itemPutCL( &pValue, Value, len );
            wxObjSetProp( pItem, PropName, &pValue );
//cout << '"' << Value << '"' << endl;
            break;
            
         case vaIdent: 
            pForm->buff = ReadString( pForm->buff+1, (unsigned char) *pForm->buff, Value, &len, 255 );
            hb_itemPutCL( &pValue, Value, len );
            wxObjSetProp( pItem, PropName, &pValue );
//cout << Value << endl;
            break;
 
         case vaFalse:
         case vaTrue:
            i = ( (int) *pForm->buff == vaTrue );
             //buff++;
//cout  << ((i) ? ".T." : ".F.") << endl;
            hb_itemPutL( &pValue, i );
            wxObjSetProp( pItem, PropName, &pValue );
            break;  
             
         case vaSet:                         
            pForm->buff = ReadSet( pForm->buff, Value, &len, 255 );
//cout << "[" << Value << "]" << endl;
            hb_itemPutCL( &pValue, Value, len );
            wxObjSetProp( pItem, PropName, &pValue );
            break;
            
         case vaUTF8String:
            pForm->buff = ReadString( pForm->buff+4, * (int *) pForm->buff, Value, &len, 255 );
            hb_itemPutCL( &pValue, Value, len );
            wxObjSetProp( pItem, PropName, &pValue );
//cout << '"' << Value << '"' << endl;
            break;
            
         default:
            //cout << "Error: unsuportted type: " << (char)type << " / " << type << endl;
            pForm->buff = NULL; 
            break;                
      }            
   }
   /*
    * O segundo passo agora ‚ convertermos os objetos filhos deste.
    * 08/09/2008 - 10:36:36
    */
   while (pForm->buff)
   { 
//cout << "A: " << (int) *buff     << " / " << ClsName << endl;   
      if (pForm->buff != pForm->end && *pForm->buff == '\0')
         pForm->buff++;
   
      if (pForm->buff == pForm->end) return NULL;
   
//cout << "B: " << (int) *buff     << " / " << ClsName << endl;   
      if (*pForm->buff != '\0')
      {
         pTemp = RestoreObj( pForm, ClsName );
HB_TRACE( HB_TR_DEBUG, ("Add OBJ..: %s em %p", ClsName, pItem));
         wxObjSetProp( pItem, ClsName, pTemp );
         
//cout << "D: " << buff     << " / " << ClsName << endl;
         if (pForm->buff && *pForm->buff == '\0')
         {
            pForm->buff++;
            break;
         }
//cout << "E: " << buff     << " / " << ClsName << endl;
      }
      else {
         pForm->buff++;      
//cout << "C: " << (int) *buff     << " / " << ClsName << endl;   
         break;
      }      
   }
   /***/
//   if (buff && buff != end && *buff == '\0')
//      buff++;

//cout << spc << "end of " << ClsName << endl;
   return pItem;
} 

/*
 * Implementação geral das interfaces em HB para as rotinas criadas acima.s
 * 06/10/2008 - 21:29:17
 */
int wxFormParseFromBuffer( FORM_DATA *pForm )
{
   char rc_sign[]  = { 255, 10, 0 };  
   char dfm_sign[] = {  84, 80, 70, 48 };  

   HB_TRACE( HB_TR_DEBUG, ("wxFormParseFromBuffer(%p)", pForm ));

   if (pForm->Length < 10L)
      return 1;
   
   pForm->buff[pForm->Length] = '\0';
   pForm->orig = pForm->buff;
   pForm->end  = pForm->buff + pForm->Length;    

   /*
    * Aqui verificamos se ele ‚ um FORM BINARIO puro, BINARIO com assinatura  
    * adicional ou um texto puro.
    * 07/09/2008 - 15:26:24
    */
   if (strncmp( pForm->buff, rc_sign, 3 ) == 0)
   {
      //Pular N bytes at‚ achar a assinatura do DFM!!!
      pForm->buff += 3;
      
      while (isalnum( (int) *pForm->buff ))
          pForm->buff++;
          
      pForm->Length -= (pForm->buff - pForm->orig);
          
      if (pForm->Length<12)
         return 2;
                        
      pForm->buff += 7;
   }

   // É um FORM binario???
   if (strncmp( pForm->buff, dfm_sign, 4 ) != 0)
      return 3;
   
   pForm->buff += 4;   
   pForm->pItem = RestoreObj( pForm, NULL );   
   return 0;
}

/*
 *
 * 06/10/2008 - 22:16:16
 */
HB_FUNC( WXFORMPARSEFROMBUFFER )
{
   FORM_DATA Form;
       
   hb_ret();
   
   /* Tem parametro valido? */
   if (!ISCHAR(1))
      return;
      
   /* Ajusta os campos corretos */
   Form.buff   = hb_parc(1);
   Form.Length = hb_parclen(1);   
   Form.pItem  = NULL;

   /* Deserializamos o form */
   wxFormParseFromBuffer( &Form );
   
   /* Retornamos o item e liberamos a memoria */
HB_TRACE( HB_TR_DEBUG, ("   Form.pItem --> %p", Form.pItem ));
   if ( Form.pItem )
   {   
      hb_itemReturnForward( Form.pItem );
      hb_itemRelease( Form.pItem );
   }          
   return;
}
