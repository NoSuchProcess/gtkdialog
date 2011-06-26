%{
/*
** $Id: lexer.l,v 1.2 2004/11/20 20:01:25 root Exp root $
** $Log: lexer.l,v $
** Revision 1.2  2004/11/20 20:01:25  root
** - Log entries.
**
*/
#define YY_INPUT(buf,result,max_size) \
    { \
    int c = getnextchar(); \
    result = (c == EOF) ? YY_NULL : (buf[0] = c, 1); \
    }


#include <string.h>
#include <gtk/gtk.h>

#include "gtkdialog.h"
#include "attributes.h"
#include "gtkdialog_parser.h"

static gchar *process_string(gchar *str);

extern int linenumber;
gchar *Token;

%}

%x EMBEDDED
%x ST_TAG_ATTR ST_QUOTED_TAGATTR
%x ST_STRING ST_QUOTED_STRING

%%

	#ifdef DEBUG
		g_message("%s(): Start", __func__);
	#endif

">"       				{ Token=">"; return(yytext[0]); 			}
<*>$[ \t\n]* 				{ Token="indent chars"; 				}

	/*
	 * Attributes.
	 */
<ST_TAG_ATTR>[-a-zA-Z_]+ {
	#ifdef DEBUG 
	g_message(" -> TAG_ATTR_NAME: '%s'", yytext);
	#endif
	Token="tag attribute name";
	gtkdialog_lval.cval=strdup(yytext);
	return TAG_ATTR_NAME;
}


<ST_TAG_ATTR>= 				{
					  #ifdef DEBUG 
					  g_message(" -> spec char: '%s'", yytext);
					  #endif
					  Token="=";
					  return '=';
												}
<ST_TAG_ATTR>\> 			{
					  #ifdef DEBUG 
					  g_message(" -> spec char: '%s'", yytext);
					  #endif
					  Token=">";
					  BEGIN(0);
					  return '>';
												}

<ST_TAG_ATTR>\" 			{
					  Token = "double quote";
					  BEGIN(ST_QUOTED_TAGATTR);				}
					  
<ST_QUOTED_TAGATTR>[^\\"]+		{
					  Token = "string";
					  yymore();						}

<ST_QUOTED_TAGATTR>("\\\"")		{
					  Token = "string";
					  yymore();						}
					  
<ST_QUOTED_TAGATTR>\"			{
					  Token = yytext;
					  gtkdialog_lval.cval = g_strdup(yytext);
					  gtkdialog_lval.cval[strlen(gtkdialog_lval.cval) - 1] = '\0';
					  BEGIN(ST_TAG_ATTR);
					  return STRING;
					  							}






	/*
	 * The elements of the embedded imperative language.
	 */
\<show\/\> { 
	Token="<show/>"; 
	return SHOW_WIDGETS;
}

\<command[ ]+assignment[ ]*=[ ]*\"  {
	Token="<command>";    
	BEGIN(EMBEDDED);
	return COMM;
}

\<if[ ]+condition[ ]*=[ ]*\"  {
	Token="<if>";    
	BEGIN(EMBEDDED);
	return IF;           
}

\<while[ ]+condition[ ]*=[ ]*\"  {
	Token="<while>";    
	BEGIN(EMBEDDED);
	return WHILE;
}

<EMBEDDED>[-+*/<>=:] {
	Token = "operator";
	return yytext[0];
}

<EMBEDDED>[a-zA-Z-]+ {
	Token = "variable";
	gtkdialog_lval.cval = g_strdup(yytext);
	return EMB_VARIABLE;
}

<EMBEDDED>[0-9,.]+ {
	Token = "number";
	gtkdialog_lval.cval = g_strdup(yytext);
	return EMB_NUMBER;
}

<EMBEDDED>\" { 
	BEGIN(0);
}

"</command>" { 
	Token="</if>"; 
	return ENDCOMM;
}

"</if>" { 
	Token="</if>"; 
	return ENDIF;
}

"</while>" { 
	Token="</while>"; 
	return EWHILE;
}


	/*
	 * The widget tags.
	 */
\<window\> { 
	Token="<window>"; 
	return(WINDOW);
}

\<window[ ]+ { 
	Token="<window>"; 
	BEGIN(ST_TAG_ATTR);
	return(PART_WINDOW);  		
}

\<\/window\> { 
	Token="</window>"; 
	return(EWINDOW);
}


\<notebook\> { 
	Token="<notebook>"; 
	return(NOTEBOOK);
}

\<\/notebook\> { 
	Token="</notebook>"; 
	return(ENOTEBOOK);
}

\<notebook[ ]+ { 
	Token="<notebook>";
	BEGIN(ST_TAG_ATTR);
	return(PART_NOTEBOOK);
}


\<vbox\> { 
	Token="<vbox>"; 
	return(VBOX);
}

\<vbox[ ]+ { 
	Token="<hbox>"; 
	BEGIN(ST_TAG_ATTR);
	return(PART_VBOX);
}

\<\/vbox\> { 
	Token="</vbox>"; 
	return(EVBOX);
}


\<hbox\> { 
	Token="<hbox>"; 
	return(HBOX);
}

\<hbox[ ]+ { 
	Token="<hbox>";
	BEGIN(ST_TAG_ATTR);
	return(PART_HBOX);
}

\<\/hbox\> { 
	Token="</hbox>"; 
	return(EHBOX);
}


\<frame\> { 
	Token="<frame>"; 
	gtkdialog_lval.cval = "";  
	return(FRAME); 	
}

\<frame\ [^\>]+\> {
	Token="<frame>";
	gtkdialog_lval.cval=strdup(&yytext[7]);  
	gtkdialog_lval.cval[strlen(gtkdialog_lval.cval)-1] = 0;
	return FRAME; 
}

\<\/frame\> { 
	Token="</frame>"; 
	return(EFRAME);
}


\<text\> { 
	Token="<text>"; 
	return(TEXT);
}

\<text[ ]+ { 
	Token="<text>"; 
	BEGIN(ST_TAG_ATTR);
	return(PART_TEXT);
}

\<\/text\> { 
	Token="</text>"; 
	return(ETEXT);
}


\<pixmap\> { 
	Token="<pixmap>"; 
	return(PIXMAP);
}

\<\/pixmap\> { 
	Token="</pixmap>"; 
	return(EPIXMAP); 
}

\<pixmap[ ]+ { 
	Token="<pixmap>"; 
	BEGIN(ST_TAG_ATTR);
	return(PART_PIXMAP);
}


\<entry\> { 
	Token="<entry>"; 
	return(ENTRY);
}

\<\/entry\> { 
	Token="</entry>"; 
	return(EENTRY);
}

\<entry[ ]+ { 
	Token="<entry>"; 
	BEGIN(ST_TAG_ATTR);
	return(PART_ENTRY);
}


\<edit\> { 
	Token="<edit>"; 
	return(EDIT);
}

\<edit[ ]+ { 
	Token="<entry>"; 
	BEGIN(ST_TAG_ATTR);
	return(PART_EDIT);
}

\<\/edit\> { 
	Token="</edit>"; 
	return(EEDIT);
}


\<tree\> { 
	Token="<tree>";  
	return  TREE;
}

\<tree[ ]+ { 
	Token="<tree>";  
	BEGIN(ST_TAG_ATTR);
	return PART_TREE;
}

\<\/tree\> {
	Token="</tree>"; 
	return ETREE;
}


\<chooser\> { 
	Token="<chooser>"; 
	return(CHOOSER);
}

\<\/chooser\> { 
	Token="</chooser>"; 
	return(ECHOOSER);
}

\<chooser[ ]+ { 
	Token="<chooser>";  
	BEGIN(ST_TAG_ATTR);
	return PART_CHOOSER;
}


\<button\> { 
	Token="<button>"; 
	return(BUTTON);
}

\<\/button\> { 
	Token="</button>"; 
	return(EBUTTON);
}

\<button[ ]+/([-a-zA-Z_]*=) { 
	//g_message("PART_BUTTON: '%s'", yytext);
	Token="<button>";  
	BEGIN(ST_TAG_ATTR);
	return PART_BUTTON;
}

\<button\ ok\>      			{ Token="<button>"; return(BUTTONOK);  			}
\<button\ cancel\>  			{ Token="<button>"; return(BUTTONCANCEL);  		}
\<button\ help\>    			{ Token="<button>"; return(BUTTONHELP);  		}
\<button\ yes\>     			{ Token="<button>"; return(BUTTONYES);  		}
\<button\ no\>      			{ Token="<button>"; return(BUTTONNO);  			}

\<checkbox\>				{ Token="<checkbox>"; return(CHECKBOX);       		}
\<\/checkbox\>  			{ Token="</checkbox>"; return(ECHECKBOX);     		}
\<checkbox[ ]+  			{ Token="<chackbox>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_CHECKBOX);  				}

\<radiobutton\>    			{ Token="<radiobutton>"; return(RADIO);      		}
\<\/radiobutton\>  			{ Token="</radiobutton>"; return(ERADIO);    		}
\<radiobutton[ ]+  			{ Token="<radiobutton>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_RADIO);  					}

\<progressbar\>    			{ Token="<progressbar>"; return(PROGRESS);      	}
\<\/progressbar\>  			{ Token="</progressbar>"; return(EPROGRESS);    	}
\<progressbar[ ]+  			{ Token="<progressbar>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_PROGRESS);  				}


\<radio\>    				{ Token="<radio>"; return(RADIO);  			}
\<\/radio\>  				{ Token="</radio>"; return(ERADIO);  			}

\<gvim\>     				{ Token="<gvim>"; return(GVIM);  			}
\<\/gvim\>   				{ Token="</gvim>"; return(EGVIM);  			}

\<combobox\>    			{ Token="<combobox>"; return(COMBO);  	  		}
\<combobox[ ]+  			{ Token="<combobox>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_COMBO); 					}
\<\/combobox\>  			{ Token="</combobox>"; return(ECOMBO);    		}

\<list\>    				{ Token="<list>";  return(LIST);  			}
\<list[ ]+      			{ Token="<list>";  
					  BEGIN(ST_TAG_ATTR);
					  return(PART_LIST); 					}
\<\/list\>  				{ Token="</list>"; return(ELIST);  			}

\<table\>    				{ Token="<table>"; return(TABLE);  			}
\<\/table\>  				{ Token="</table>"; return(ETABLE);  			}

\<menubar\>    				{ Token="<menubar>"; return(MENUBAR);  			}
\<\/menubar\>  				{ Token="</menubar>"; return(EMENUBAR);			}

\<menu\>    				{ Token="<menu>"; return(MENU);  			}
\<\/menu\>  				{ Token="</menu>"; return(EMENU);			}

\<menuitem\>    			{ Token="<menuitem>"; return(MENUITEM);  		}
\<menuitem[ ]+  			{ Token="<menuitem>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_MENUITEM);  				}
\<\/menuitem\>  			{ Token="</menuitem>"; return(EMENUITEM);		}

\<separator\>    			{ Token="<separator>"; return(SEPARATOR);  		}
\<\/separator\>				{ Token="</separator>"; return(ESEPARATOR);		}

	/* Thunor: Newly supported widgets */
\<hseparator\>    			{ Token="<hseparator>"; return(HSEPARATOR); }
\<\/hseparator\>			{ Token="</hseparator>"; return(EHSEPARATOR); }
\<hseparator[ ]+  			{ Token="<hseparator>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_HSEPARATOR); }

\<vseparator\>    			{ Token="<vseparator>"; return(VSEPARATOR); }
\<\/vseparator\>			{ Token="</vseparator>"; return(EVSEPARATOR); }
\<vseparator[ ]+  			{ Token="<vseparator>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_VSEPARATOR); }







\<label\>    				{ Token="<label>"; return(LABEL);    			}
\<\/label\>  				{ Token="</label>"; return(ELABEL);  			}

\<item\>     				{ Token="<item>"; return(ITEM);      			}
\<\/item\>   				{ Token="</item>"; return(EITEM);    			}
\<item[ ]+   				{ Token="<item>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_ITEM); 					}

\<default\>      			{ Token="<default>"; return(DEFAULT);  			}
\<\/default\>    			{ Token="</default>"; return(EDEFAULT);  		}

\<visible\>      			{ Token="<visible>"; return(VISIBLE);  			}
\<\/visible\>    			{ Token="</visible>"; return(EVISIBLE);  		}

\<variable\>     			{ 
					  Token="<variable>"; 
					  return(VARIABLE); 					}
\<\/variable\>   			{ 
					  Token="</variable>"; 
					  return(EVARIABLE); 					}

\<height\>       			{ Token="<height>"; return(HEIGHT);  			}
\<\/height\>     			{ Token="</height>"; return(EHEIGHT);  			}

\<width\>        			{ Token="<width>"; return(WIDTH);   			}
\<\/width\>      			{ Token="</width>"; return(EWIDTH);   			}

\<input\>        			{ Token="<input>"; return(INPUT);   			}
\<\/input\>      			{ Token="</input>"; return(EINPUT);   			}
\<\input\ file\> 			{ Token="<input file>"; return(INPUTFILE);   		}
\<\input\ file[ ]+ 			{ Token="<input file>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_INPUTFILE);   				}
\<\input\ [ ]*   			{ Token="<input>"; 
					  BEGIN(ST_TAG_ATTR);
					  return(PART_INPUT);   				}

\<output\>        			{ Token="<output>"; return(OUTPUT);   			}
\<\/output\>      			{ Token="</output>"; return(EOUTPUT);   		}
\<\output\ file\> 			{ Token="<output>"; return(OUTPUTFILE);   		}

	/*
	** The definition of action tags.
	*/
\<action\> { 
	Token="<action>"; 
	return(ACTION);
}

\<action[ ]+ { 
	Token="<action>"; 
	BEGIN(ST_TAG_ATTR);
	return(PART_ACTION);
}

\<\/action\>  { 
	Token="</action>"; 
	return(EACTION);
}






\<\/[^> ]*\> { 
	Token=g_strdup(yytext); 
	gtkdialog_error("Unknown end tag.");  
}

\<[^> ]*\> { 
	Token=g_strdup(yytext); 
	gtkdialog_error("Unknown tag.");      
}
					
					/*
					 * The quoted string. It can contain anything, except
					 * unescaped double quote.
					 */
\"	  				{
					  Token = "double quote";
					  BEGIN(ST_QUOTED_STRING);				}
					  
<ST_QUOTED_STRING>[^\\"]+		{
					  yymore();						}

<ST_QUOTED_STRING>"\\\""		{
					  yymore();						}
					  
<ST_QUOTED_STRING>\"			{
					  Token = yytext;
					  gtkdialog_lval.cval = g_strdup(yytext);
					  gtkdialog_lval.cval[strlen(gtkdialog_lval.cval) - 1] = '\0';
					  BEGIN(0);
					  return STRING;
					  							}
												
					/*
					 * An unquoted string can contain anything except 
					 * unescaped '<'.
					 */
[^ \n\t\>\<\"][^\n\<\\]*  		{
					  Token = "string";
					  BEGIN(ST_STRING);
					  yymore();
												}
<ST_STRING>[^\n\<\\]+  			{
					  Token = "string";
					  yymore();
												}


<ST_STRING>"\\<"			{
					  yymore();
												}

<ST_STRING>\\.				{
					  yymore();
												}

<ST_STRING>"<"				{
					  gtkdialog_lval.cval = g_strdup(yytext);
					  gtkdialog_lval.cval[strlen(gtkdialog_lval.cval) - 1] = '\0';
					  unput('<');
					  BEGIN(0);
					  return STRING;
					  							}

												

<*>\n 					{
					  ++linenumber;
												}
<*>[\t ] 					{
					  /* */
												}

<*>.                                       {
					  /* we do nothing, this is a dropped char. */
												}
%%

static gchar *
process_string(gchar *str)
{
	//fprintf(stderr, "%s(): Input = '%s'\n", __func__, str);
	// FIXME: Well, this will come tomorrow...
	return g_strdup(str);
}
