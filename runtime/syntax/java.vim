" Vim syntax file
" Language:	Java
" Maintainer:	Claudio Fleiner <claudio@fleiner.com>
" URL:		https://github.com/fleiner/vim/blob/master/runtime/syntax/java.vim
" Last Change:	2022 Sep 30

" Please check :help java.vim for comments on some of the options available.

" quit when a syntax file was already loaded
if !exists("main_syntax")
  if exists("b:current_syntax")
    finish
  endif
  " we define it here so that included files can test for it
  let main_syntax = 'java'
endif

let s:cpo_save = &cpo
set cpo&vim

" Admit the ASCII dollar sign to keyword characters (JLS-17, $3.8).
execute 'syntax iskeyword '.&iskeyword.',$'

" some characters that cannot be in a java program (outside a string)
syn match javaError "[\\@`]"
syn match javaError "<<<\|\.\.\|=>\|||=\|&&=\|\*\/"

" FIXME: A dangling syntax group? See javaVarArg.
syn match javaOK "\.\.\."

" use separate name so that it can be deleted in javacc.vim
syn match   javaError2 "#\|=<"
hi def link javaError2 javaError

" keyword definitions
syn keyword javaExternal	native package
syn match   javaExternal	"\<import\>\%(\s\+static\>\)\?"
syn keyword javaError		goto const
syn keyword javaConditional	if else switch
syn keyword javaRepeat		while for do
syn keyword javaBoolean		true false
syn keyword javaConstant	null
syn keyword javaTypedef		this super
syn keyword javaOperator	var new instanceof
" Since the yield statement, which could take a parenthesised operand,
" and _qualified_ yield methods get along within the switch block
" (JLS-17, $3.8), it seems futile to make a region definition for this
" block; instead look for the _yield_ word alone, and if found,
" backtrack (arbitrarily) 80 bytes, at most, on the matched line and,
" if necessary, on the line before that (h: \@<=), trying to match
" neither a method reference nor a qualified method invocation.
syn match   javaOperator	"\%(\%(::\|\.\)[[:space:]\n]*\)\@80<!\<yield\>"
syn keyword javaType		boolean char byte short int long float double
syn keyword javaType		void
syn keyword javaStatement	return
syn keyword javaStorageClass	static synchronized transient volatile strictfp serializable
syn keyword javaExceptions	throw try catch finally
syn keyword javaAssert		assert
syn keyword javaMethodDecl	throws
syn keyword javaClassDecl	extends implements interface permits
" to differentiate the keyword class from MyClass.class we use a match here
syn match   javaTypedef		"\.\s*\<class\>"ms=s+1
syn keyword javaClassDecl	enum record
syn match   javaClassDecl	"^class\>"
syn match   javaClassDecl	"[^.]\s*\<class\>"ms=s+1
syn match   javaAnnotation	"@\%(\K\k*\.\)*\K\k*\>"
syn region  javaAnnotation	transparent matchgroup=javaAnnotationStart start=/@\%(\K\k*\.\)*\K\k*(/ end=/)/ skip=/\/\*.\{-}\*\/\|\/\/.*$/ contains=javaAnnotation,javaBlock,javaString,javaBoolean,javaNumber,javaTypedef,javaComment,javaLineComment
syn match   javaClassDecl	"@interface\>"
syn keyword javaBranch		break continue nextgroup=javaUserLabelRef skipwhite
syn match   javaUserLabelRef	"\k\+" contained
syn match   javaVarArg		"\.\.\."
syn keyword javaScopeDecl	public protected private
syn keyword javaConceptKind	abstract final sealed
syn match   javaConceptKind	"\<non-sealed\>"
syn match   javaConceptKind	"\<default\>\%(\s*\%(:\|->\)\)\@!"

let s:selectable_regexp_engine = !(v:version < 704)
let s:module_info_cur_buf = fnamemodify(bufname("%"), ":t") =~ '^module-info\%(\.class\>\)\@!'
lockvar s:selectable_regexp_engine s:module_info_cur_buf

" Java modules (since Java 9, for "module-info.java" file)
if s:module_info_cur_buf
  syn keyword javaModuleStorageClass	module transitive
  syn keyword javaModuleStmt		open requires exports opens uses provides
  syn keyword javaModuleExternal	to with
  syn cluster javaTop add=javaModuleStorageClass,javaModuleStmt,javaModuleExternal
endif

" Fancy parameterised types (JLS-17, $4.5).
"
" Note that false positives may elsewhere occur whenever an identifier
" is butted against a less-than operator.
" E.g., cf. (X<Y) with (X < Y).
if exists("java_highlight_generics")
  syn keyword javaWildcardBound contained extends super
  hi def link javaWildcardBound Question
  hi def link javaGenericsStart Identifier

  " Consider array creation expressions of reifiable types.
  syn region  javaDimExpr contained transparent matchgroup=javaGenericsStart start="\[" end="\]" nextgroup=javaDimExpr skipwhite skipnl

  if s:selectable_regexp_engine
    " Request the new regexp engine for [:upper:].
    "
    " Parameterised types are delegated to javaGenerics and are not
    " matched with javaTypeArgument.
    syn match  javaTypeArgument contained "\%#=2?\|\%(\<\%(b\%(oolean\|yte\)\|char\|short\|int\|long\|float\|double\)\[\]\|\%(\<\K\k*\>\.\)*\<[$_[:upper:]]\k*\>\)\%(\[\]\)*"
    syn region javaGenerics transparent matchgroup=javaGenericsStart start=/\%#=2\%(\<\K\k*\>\.\)*\<[$_[:upper:]]\k*\><\%([[:space:]\n]*\%([?@]\|\<\%(b\%(oolean\|yte\)\|char\|short\|int\|long\|float\|double\)\[\]\|\%(\<\K\k*\>\.\)*\<[$_[:upper:]]\k*\>\)\)\@=/ end=/>/ contains=javaGenerics,javaAnnotation,javaTypeArgument,javaWildcardBound,javaType,@javaClasses nextgroup=javaDimExpr skipwhite skipnl
  else
    syn match  javaTypeArgument contained "?\|\%(\<\%(b\%(oolean\|yte\)\|char\|short\|int\|long\|float\|double\)\[\]\|\%(\<\K\k*\>\.\)*\<[^a-z0-9]\k*\>\)\%(\[\]\)*"
    syn region javaGenerics transparent matchgroup=javaGenericsStart start=/\%(\<\K\k*\>\.\)*\<[^a-z0-9]\k*\><\%([[:space:]\n]*\%([?@]\|\<\%(b\%(oolean\|yte\)\|char\|short\|int\|long\|float\|double\)\[\]\|\%(\<\K\k*\>\.\)*\<[^a-z0-9]\k*\>\)\)\@=/ end=/>/ contains=javaGenerics,javaAnnotation,javaTypeArgument,javaWildcardBound,javaType,@javaClasses nextgroup=javaDimExpr skipwhite skipnl
  endif

  syn cluster javaTop add=javaGenerics
endif

if exists("java_highlight_java_lang_ids")
  let java_highlight_all = 1
endif
if exists("java_highlight_all") || exists("java_highlight_java") || exists("java_highlight_java_lang")
  " java.lang.*
  "
  " The keywords of javaR_JavaLang, javaC_JavaLang, javaE_JavaLang,
  " and javaX_JavaLang are sub-grouped according to the Java version
  " of their introduction, and sub-group keywords (that is, class
  " names) are arranged in alphabetical order, so that future newer
  " keywords can be pre-sorted and appended without disturbing
  " the current keyword placement. The below _match_es follow suit.

  " FIXME: A dangling syntax group? See javaC_JavaLang.
  syn match javaLangClass "\<System\>"
  syn keyword javaR_JavaLang ArithmeticException ArrayIndexOutOfBoundsException ArrayStoreException ClassCastException IllegalArgumentException IllegalMonitorStateException IllegalThreadStateException IndexOutOfBoundsException NegativeArraySizeException NullPointerException NumberFormatException RuntimeException SecurityException StringIndexOutOfBoundsException IllegalStateException UnsupportedOperationException EnumConstantNotPresentException TypeNotPresentException IllegalCallerException LayerInstantiationException WrongThreadException
  syn cluster javaTop add=javaR_JavaLang
  syn cluster javaClasses add=javaR_JavaLang
  hi def link javaR_JavaLang javaR_Java
  " Member enumerations:
  syn match   javaC_JavaLang "\%(\<Thread\.\)\@<=\<State\>"
  syn match   javaC_JavaLang "\%(\<Character\.\)\@<=\<UnicodeScript\>"
  syn match   javaC_JavaLang "\%(\<ProcessBuilder\.Redirect\.\)\@<=\<Type\>"
  syn match   javaC_JavaLang "\%(\<StackWalker\.\)\@<=\<Option\>"
  syn match   javaC_JavaLang "\%(\<System\.Logger\.\)\@<=\<Level\>"
  " Member classes:
  syn match   javaC_JavaLang "\%(\<Character\.\)\@<=\<Subset\>"
  syn match   javaC_JavaLang "\%(\<Character\.\)\@<=\<UnicodeBlock\>"
  syn match   javaC_JavaLang "\%(\<ProcessBuilder\.\)\@<=\<Redirect\>"
  syn match   javaC_JavaLang "\%(\<ModuleLayer\.\)\@<=\<Controller\>"
  syn match   javaC_JavaLang "\%(\<Runtime\.\)\@<=\<Version\>"
  syn match   javaC_JavaLang "\%(\<System\.\)\@<=\<LoggerFinder\>"
  syn keyword javaC_JavaLang Boolean Character ClassLoader Compiler Double Float Integer Long Math Number Object Process Runtime SecurityManager String StringBuffer Thread ThreadGroup Byte Short Void Package RuntimePermission StrictMath StackTraceElement ProcessBuilder StringBuilder Module ModuleLayer StackWalker Record
  syn match   javaC_JavaLang "\<System\>"	" See javaDebug.

  if !exists("java_highlight_generics")
    " The non-interface parameterised names of java.lang members.
    syn match   javaC_JavaLang "\%(\<Enum\.\)\@<=\<EnumDesc\>"
    syn keyword javaC_JavaLang Class InheritableThreadLocal ThreadLocal Enum ClassValue
  endif

  syn cluster javaTop add=javaC_JavaLang
  syn cluster javaClasses add=javaC_JavaLang
  hi def link javaC_JavaLang javaC_Java
  syn keyword javaE_JavaLang AbstractMethodError ClassCircularityError ClassFormatError Error IllegalAccessError IncompatibleClassChangeError InstantiationError InternalError LinkageError NoClassDefFoundError NoSuchFieldError NoSuchMethodError OutOfMemoryError StackOverflowError ThreadDeath UnknownError UnsatisfiedLinkError VerifyError VirtualMachineError ExceptionInInitializerError UnsupportedClassVersionError AssertionError BootstrapMethodError
  syn cluster javaTop add=javaE_JavaLang
  syn cluster javaClasses add=javaE_JavaLang
  hi def link javaE_JavaLang javaE_Java
  syn keyword javaX_JavaLang ClassNotFoundException CloneNotSupportedException Exception IllegalAccessException InstantiationException InterruptedException NoSuchMethodException Throwable NoSuchFieldException ReflectiveOperationException
  syn cluster javaTop add=javaX_JavaLang
  syn cluster javaClasses add=javaX_JavaLang
  hi def link javaX_JavaLang javaX_Java

  hi def link javaR_Java	javaR_
  hi def link javaC_Java	javaC_
  hi def link javaE_Java	javaE_
  hi def link javaX_Java	javaX_
  hi def link javaX_		javaExceptions
  hi def link javaR_		javaExceptions
  hi def link javaE_		javaExceptions
  hi def link javaC_		javaConstant

  syn keyword javaLangObject getClass notify notifyAll wait

  " To allow for zero-width matching, lower priority for the following
  " names of overridable methods by preferring _match_ to _keyword_
  " (:h syn-priority; also, see method declarations in the source file
  " of java.lang.Object, with the g:java_highlight_functions variable
  " set to 'signature'):
  syn match javaLangObject "\<clone\>"
  syn match javaLangObject "\<equals\>"
  syn match javaLangObject "\<finalize\>"
  syn match javaLangObject "\<hashCode\>"
  syn match javaLangObject "\<toString\>"
  hi def link javaLangObject javaConstant
  syn cluster javaTop add=javaLangObject
endif

if filereadable(expand("<sfile>:p:h")."/javaid.vim")
  source <sfile>:p:h/javaid.vim
endif

if exists("java_space_errors")
  if !exists("java_no_trail_space_error")
    syn match	javaSpaceError	"\s\+$"
  endif
  if !exists("java_no_tab_space_error")
    syn match	javaSpaceError	" \+\t"me=e-1
  endif
endif

syn match   javaUserLabel	"^\s*\<\K\k*\>\%(\<default\>\)\@<!\s*:"he=e-1
syn region  javaLabelRegion	transparent matchgroup=javaLabel start="\<case\>" matchgroup=NONE end=":" end="->" contains=javaNumber,javaCharacter,javaString,javaConstant,@javaClasses
syn region  javaLabelRegion	transparent matchgroup=javaLabel start="\<default\>\%(\s*\%(:\|->\)\)\@=" matchgroup=NONE end=":" end="->" oneline

" Highlighting C++ keywords as errors removed, too many people find it
" annoying.  Was: if !exists("java_allow_cpp_keywords")

" The following cluster contains all java groups except the contained ones
syn cluster javaTop add=javaExternal,javaError,javaError,javaBranch,javaLabelRegion,javaConditional,javaRepeat,javaBoolean,javaConstant,javaTypedef,javaOperator,javaType,javaType,javaStatement,javaStorageClass,javaAssert,javaExceptions,javaMethodDecl,javaClassDecl,javaClassDecl,javaClassDecl,javaScopeDecl,javaConceptKind,javaError,javaError2,javaUserLabel,javaLangObject,javaAnnotation,javaVarArg,javaBlock

" Comments
syn keyword javaTodo		   contained TODO FIXME XXX
if exists("java_comment_strings")
  syn region  javaCommentString    contained start=+"+ end=+"+ end=+$+ end=+\*/+me=s-1,he=s-1 contains=javaSpecial,javaCommentStar,javaSpecialChar,@Spell
  syn region  javaComment2String   contained start=+"+ end=+$\|"+ contains=javaSpecial,javaSpecialChar,@Spell
  syn match   javaCommentCharacter contained "'\\[^']\{1,6\}'" contains=javaSpecialChar
  syn match   javaCommentCharacter contained "'\\''" contains=javaSpecialChar
  syn match   javaCommentCharacter contained "'[^\\]'"
  syn cluster javaCommentSpecial   add=javaCommentString,javaCommentCharacter,javaNumber
  syn cluster javaCommentSpecial2  add=javaComment2String,javaCommentCharacter,javaNumber
endif
syn region  javaComment		matchgroup=javaCommentStart start="/\*" end="\*/" contains=@javaCommentSpecial,javaTodo,javaCommentError,javaSpaceError,@Spell fold
syn match   javaCommentStar	contained "^\s*\*[^/]"me=e-1
syn match   javaCommentStar	contained "^\s*\*$"
syn match   javaLineComment	"//.*" contains=@javaCommentSpecial2,javaTodo,javaCommentMarkupTag,javaSpaceError,@Spell
syn match   javaCommentMarkupTag contained "@\%(end\|highlight\|link\|replace\|start\)\>" nextgroup=javaCommentMarkupTagAttr skipwhite
syn match   javaCommentMarkupTagAttr contained "\<region\>" nextgroup=javaCommentMarkupTagAttr skipwhite
syn region  javaCommentMarkupTagAttr contained transparent matchgroup=htmlArg start=/\<\%(re\%(gex\|gion\|placement\)\|substring\|t\%(arget\|ype\)\)\%(\s*=\)\@=/ matchgroup=htmlString end=/\%(=\s*\)\@<=\%("[^"]\+"\|'[^']\+'\|\%([.-]\|\k\)\+\)/ nextgroup=javaCommentMarkupTagAttr skipwhite oneline
hi def link javaCommentMarkupTagAttr htmlArg
hi def link javaCommentString	javaString
hi def link javaComment2String	javaString
hi def link javaCommentCharacter javaCharacter
syn match   javaCommentError	contained "/\*"me=e-1 display
hi def link javaCommentError	javaError
hi def link javaCommentStart	javaComment

syn cluster javaTop add=javaComment,javaLineComment

if !exists("java_ignore_javadoc") && main_syntax != 'jsp'
  syntax case ignore
  " syntax coloring for javadoc comments (HTML)
  syntax include @javaHtml syntax/html.vim
  unlet b:current_syntax
  " HTML enables spell checking for all text that is not in a syntax item. This
  " is wrong for Java (all identifiers would be spell-checked), so it's undone
  " here.
  syntax spell default

  syn region javaDocComment	start="/\*\*" end="\*/" keepend contains=javaCommentTitle,@javaHtml,javaDocTags,javaDocSeeTag,javaDocCodeTag,javaDocSnippetTag,javaTodo,javaCommentError,javaSpaceError,@Spell fold
  syn region javaCommentTitle	contained matchgroup=javaDocComment start="/\*\*" matchgroup=javaCommentTitle keepend end="\.$" end="\.[ \t\r<&]"me=e-1 end="[^{]@"me=s-2,he=s-1 end="\*/"me=s-1,he=s-1 contains=@javaHtml,javaCommentStar,javaTodo,javaCommentError,javaSpaceError,@Spell,javaDocTags,javaDocSeeTag,javaDocCodeTag,javaDocSnippetTag
  syn region javaDocTags	contained start="{@\%(li\%(teral\|nk\%(plain\)\=\)\|inherit[Dd]oc\|doc[rR]oot\|value\)\>" end="}"
  syn match  javaDocParam	contained "\s\S\+"
  syn match  javaDocTags	contained "@\%(param\|exception\|throws\|since\)\s\+\S\+" contains=javaDocParam
  syn match  javaDocTags	contained "@\%(version\|author\|return\|deprecated\|serial\%(Field\|Data\)\=\)\>"
  syn region javaDocSeeTag	contained matchgroup=javaDocTags start="@see\s\+" matchgroup=NONE end="\_."re=e-1 contains=javaDocSeeTagParam
  syn match  javaDocSeeTagParam	contained @"\_[^"]\+"\|<a\s\+\_.\{-}</a>\|\%(\k\|\.\)*\%(#\k\+\%((\_[^)]*)\)\=\)\=@ extend
  syn region javaCodeSkipBlock	contained transparent start="{\%(@code\>\)\@!" end="}" contains=javaCodeSkipBlock,javaDocCodeTag
  syn region javaDocCodeTag	contained start="{@code\>" end="}" contains=javaDocCodeTag,javaCodeSkipBlock
  syn region javaDocSnippetTagAttr contained transparent matchgroup=htmlArg start=/\<\%(class\|file\|id\|lang\|region\)\%(\s*=\)\@=/ matchgroup=htmlString end=/:$/ end=/\%(=\s*\)\@<=\%("[^"]\+"\|'[^']\+'\|\%([.-]\|\k\)\+\)/ nextgroup=javaDocSnippetTagAttr skipwhite skipnl
  syn region javaSnippetSkipBlock contained transparent start="{\%(@snippet\>\)\@!" end="}" contains=javaSnippetSkipBlock,javaDocSnippetTag,javaCommentMarkupTag
  syn region javaDocSnippetTag	contained start="{@snippet\>" end="}" contains=javaDocSnippetTag,javaSnippetSkipBlock,javaDocSnippetTagAttr,javaCommentMarkupTag
  syntax case match
endif

" match the special comment /**/
syn match   javaComment		"/\*\*/"

" Strings and constants
syn match   javaSpecialError	 contained "\\."
syn match   javaSpecialCharError contained "[^']"
syn match   javaSpecialChar	 contained "\\\([4-9]\d\|[0-3]\d\d\|[\"\\'bstnfr]\|u\x\{4\}\)"
syn region  javaString		start=+"+ end=+"+ end=+$+ contains=javaSpecialChar,javaSpecialError,@Spell
syn region  javaString		start=+"""[ \t\x0c\r]*$+hs=e+1 end=+"""+he=s-1 contains=javaSpecialChar,javaSpecialError,javaTextBlockError,@Spell
syn match   javaTextBlockError	+"""\s*"""+
" next line disabled, it can cause a crash for a long line
"syn match  javaStringError	+"\([^"\\]\|\\.\)*$+
syn match   javaCharacter	"'[^']*'" contains=javaSpecialChar,javaSpecialCharError
syn match   javaCharacter	"'\\''" contains=javaSpecialChar
syn match   javaCharacter	"'[^\\]'"
syn match   javaNumber		"\<\(0[bB][0-1]\+\|0[0-7]*\|0[xX]\x\+\|\d\(\d\|_\d\)*\)[lL]\=\>"
syn match   javaNumber		"\(\<\d\(\d\|_\d\)*\.\(\d\(\d\|_\d\)*\)\=\|\.\d\(\d\|_\d\)*\)\([eE][-+]\=\d\(\d\|_\d\)*\)\=[fFdD]\="
syn match   javaNumber		"\<\d\(\d\|_\d\)*[eE][-+]\=\d\(\d\|_\d\)*[fFdD]\=\>"
syn match   javaNumber		"\<\d\(\d\|_\d\)*\([eE][-+]\=\d\(\d\|_\d\)*\)\=[fFdD]\>"

" Unicode characters
syn match   javaSpecial "\\u\d\{4\}"

syn cluster javaTop add=javaString,javaCharacter,javaNumber,javaSpecial,javaStringError,javaTextBlockError

if exists("java_highlight_functions")
  syn match   javaMethodReference "::\%(:\)\@!"
  hi def link javaMethodReference PreProc
  syn cluster javaTop add=javaMethodReference
  syn cluster javaFuncParams contains=javaAnnotation,@javaClasses,javaGenerics,javaType,javaVarArg,javaComment,javaLineComment

  if java_highlight_functions == "indent"
    syn cluster javaFuncParams add=javaScopeDecl,javaConceptKind,javaStorageClass,javaExternal
    syn match   javaFuncDef "^\%(\t\| \{8\}\)\K\%(\k\|[ .<>\[\]]\)*([^-+*/]*)" contains=@javaFuncParams
    syn region  javaFuncDef start=+^\%(\t\| \{8\}\)\K\%(\k\|[ .<>\[\]]\)*([^-+*/]*,\s*+ end=+)+ contains=@javaFuncParams
    syn match   javaFuncDef "^  \K\%(\k\|[ .<>\[\]]\)*([^-+*/]*)" contains=@javaFuncParams
    syn region  javaFuncDef start=+^  \K\%(\k\|[ .<>\[\]]\)*([^-+*/]*,\s*+ end=+)+ contains=@javaFuncParams
  elseif java_highlight_functions == "signature"
    " Match method signatures of arbitrarily indented camelCasedName
    " method declarations: their names and the parameter list parens.
    syn keyword javaParamModifier contained final
    syn cluster javaFuncParams add=javaParamModifier
    hi def link javaParamModifier javaConceptKind
    hi def link javaFuncDefStart javaFuncDef

    if s:selectable_regexp_engine
      " Request the new regexp engine for [:upper:] and [:lower:].
      syn region javaFuncDef transparent matchgroup=javaFuncDefStart start=/\%#=2\%(^\s\+\%(\%(@\%(\K\k*\.\)*\K\k*\>\)\s\+\)*\%(p\%(ublic\|rotected\|rivate\)\s\+\)\=\%(\%(abstract\|default\)\s\+\|\%(\%(final\|native\|s\%(tatic\|trictfp\|ynchronized\)\)\s\+\)*\)\=\%(<.*[[:space:]-]\@<!>\s\+\)\=\%(void\|\%(b\%(oolean\|yte\)\|char\|short\|int\|long\|float\|double\|\%(\<\K\k*\>\.\)*\<[$_[:upper:]]\k*\>\%(<[^(){}]*[[:space:]-]\@<!>\)\=\)\%(\[\]\)*\)\s\+\)\@<=\<[$_[:lower:]]\k*\>\s*(/ end=/)/ skip=/@\%(\K\k*\.\)*\K\k*(.\{-})\+\|=.\{-})\+\|\%(["})]\s*\)\+)\+\|\/\*.\{-}\*\/\|\/\/.*$/ keepend contains=@javaFuncParams
    else
      syn region javaFuncDef transparent matchgroup=javaFuncDefStart start=/\%(^\s\+\%(\%(@\%(\K\k*\.\)*\K\k*\>\)\s\+\)*\%(p\%(ublic\|rotected\|rivate\)\s\+\)\=\%(\%(abstract\|default\)\s\+\|\%(\%(final\|native\|s\%(tatic\|trictfp\|ynchronized\)\)\s\+\)*\)\=\%(<.*[[:space:]-]\@<!>\s\+\)\=\%(void\|\%(b\%(oolean\|yte\)\|char\|short\|int\|long\|float\|double\|\%(\<\K\k*\>\.\)*\<[^a-z0-9]\k*\>\%(<[^(){}]*[[:space:]-]\@<!>\)\=\)\%(\[\]\)*\)\s\+\)\@<=\<[^A-Z0-9]\k*\>\s*(/ end=/)/ skip=/@\%(\K\k*\.\)*\K\k*(.\{-})\+\|=.\{-})\+\|\%(["})]\s*\)\+)\+\|\/\*.\{-}\*\/\|\/\/.*$/ keepend contains=@javaFuncParams
    endif
  else
    " Match arbitrarily indented camelCasedName method declarations.
    syn cluster javaFuncParams add=javaScopeDecl,javaConceptKind,javaStorageClass,javaExternal

    if s:selectable_regexp_engine
      " Request the new regexp engine for [:upper:] and [:lower:].
      syn region javaFuncDef start=/\%#=2^\s\+\%(\%(@\%(\K\k*\.\)*\K\k*\>\)\s\+\)*\%(p\%(ublic\|rotected\|rivate\)\s\+\)\=\%(\%(abstract\|default\)\s\+\|\%(\%(final\|native\|s\%(tatic\|trictfp\|ynchronized\)\)\s\+\)*\)\=\%(<.*[[:space:]-]\@<!>\s\+\)\=\%(void\|\%(b\%(oolean\|yte\)\|char\|short\|int\|long\|float\|double\|\%(\<\K\k*\>\.\)*\<[$_[:upper:]]\k*\>\%(<[^(){}]*[[:space:]-]\@<!>\)\=\)\%(\[\]\)*\)\s\+\<[$_[:lower:]]\k*\>\s*(/ end=/)/ skip=/@\%(\K\k*\.\)*\K\k*(.\{-})\+\|=.\{-})\+\|\%(["})]\s*\)\+)\+\|\/\*.\{-}\*\/\|\/\/.*$/ keepend contains=@javaFuncParams
    else
      " XXX: \C\<[^a-z0-9]\k*\> rejects "type", but matches "τύπος".
      " XXX: \C\<[^A-Z0-9]\k*\> rejects "Method", but matches "Μέθοδος".
      syn region javaFuncDef start=/^\s\+\%(\%(@\%(\K\k*\.\)*\K\k*\>\)\s\+\)*\%(p\%(ublic\|rotected\|rivate\)\s\+\)\=\%(\%(abstract\|default\)\s\+\|\%(\%(final\|native\|s\%(tatic\|trictfp\|ynchronized\)\)\s\+\)*\)\=\%(<.*[[:space:]-]\@<!>\s\+\)\=\%(void\|\%(b\%(oolean\|yte\)\|char\|short\|int\|long\|float\|double\|\%(\<\K\k*\>\.\)*\<[^a-z0-9]\k*\>\%(<[^(){}]*[[:space:]-]\@<!>\)\=\)\%(\[\]\)*\)\s\+\<[^A-Z0-9]\k*\>\s*(/ end=/)/ skip=/@\%(\K\k*\.\)*\K\k*(.\{-})\+\|=.\{-})\+\|\%(["})]\s*\)\+)\+\|\/\*.\{-}\*\/\|\/\/.*$/ keepend contains=@javaFuncParams
    endif
  endif

  syn cluster javaTop add=javaFuncDef,javaBlockOther
  syn match   javaBlockOther "[{}]"
  syn region  javaBlock matchgroup=javaBlockStart start="\%(^\|^\S[^:]\+\)\@<!{" end="}" transparent fold
  hi def link javaBlockStart javaFuncDef
  hi def link javaBlockOther javaBlockStart
else
  syn region  javaBlock start="\%(^\|^\S[^:]\+\)\@<!{" end="}" transparent fold
endif

if exists("java_highlight_debug")
  " Strings and constants
  syn match   javaDebugSpecial		contained "\\\d\d\d\|\\."
  syn region  javaDebugString		contained start=+"+ end=+"+ contains=javaDebugSpecial
  syn region  javaDebugString		contained start=+"""[ \t\x0c\r]*$+hs=e+1 end=+"""+he=s-1 contains=javaDebugSpecial,javaDebugTextBlockError
  syn match   javaDebugStringError	contained +"\([^"\\]\|\\.\)*$+
  syn match   javaDebugTextBlockError	contained +"""\s*"""+
  syn match   javaDebugCharacter	contained "'[^\\]'"
  syn match   javaDebugSpecialCharacter	contained "'\\.'"
  syn match   javaDebugSpecialCharacter	contained "'\\''"
  syn match   javaDebugNumber		contained "\<\(0[0-7]*\|0[xX]\x\+\|\d\+\)[lL]\=\>"
  syn match   javaDebugNumber		contained "\(\<\d\+\.\d*\|\.\d\+\)\([eE][-+]\=\d\+\)\=[fFdD]\="
  syn match   javaDebugNumber		contained "\<\d\+[eE][-+]\=\d\+[fFdD]\=\>"
  syn match   javaDebugNumber		contained "\<\d\+\([eE][-+]\=\d\+\)\=[fFdD]\>"
  syn keyword javaDebugBoolean		contained true false
  syn keyword javaDebugType		contained null this super
  syn region  javaDebugParen		contained start=+(+ end=+)+ contains=javaDebug.*,javaDebugParen

  " to make this work you must define the highlighting for these groups
  syn match javaDebug "\<System\.\%(out\|err\)\.print\%(ln\)\=\s*("me=e-1 contains=javaDebug.* nextgroup=javaDebugParen
  syn match javaDebug "\<p\s*("me=e-1 contains=javaDebug.* nextgroup=javaDebugParen
  syn match javaDebug "\<\K\k*\.printStackTrace\s*("me=e-1 contains=javaDebug.* nextgroup=javaDebugParen
  syn match javaDebug "\<trace[SL]\=\s*("me=e-1 contains=javaDebug.* nextgroup=javaDebugParen

  syn cluster javaTop add=javaDebug

  hi def link javaDebug			Debug
  hi def link javaDebugString		DebugString
  hi def link javaDebugStringError	javaError
  hi def link javaDebugTextBlockError	javaError
  hi def link javaDebugType		DebugType
  hi def link javaDebugBoolean		DebugBoolean
  hi def link javaDebugNumber		Debug
  hi def link javaDebugSpecial		DebugSpecial
  hi def link javaDebugSpecialCharacter	DebugSpecial
  hi def link javaDebugCharacter	DebugString
  hi def link javaDebugParen		Debug

  hi def link DebugString		String
  hi def link DebugSpecial		Special
  hi def link DebugBoolean		Boolean
  hi def link DebugType			Type
endif

if exists("java_mark_braces_in_parens_as_errors")
  " FIXME: A dangling syntax group? Which group does contain it?
  syn match javaInParen		contained "[{}]"
  hi def link javaInParen	javaError
  syn cluster javaTop add=javaInParen
endif

" catch errors caused by wrong parenthesis
syn region  javaParenT	transparent matchgroup=javaParen  start="(" end=")" contains=@javaTop,javaParenT1
syn region  javaParenT1 transparent matchgroup=javaParen1 start="(" end=")" contains=@javaTop,javaParenT2 contained
syn region  javaParenT2 transparent matchgroup=javaParen2 start="(" end=")" contains=@javaTop,javaParenT  contained
syn match   javaParenError	")"
" catch errors caused by wrong square parenthesis
syn region  javaParenT	transparent matchgroup=javaParen  start="\[" end="\]" contains=@javaTop,javaParenT1
syn region  javaParenT1 transparent matchgroup=javaParen1 start="\[" end="\]" contains=@javaTop,javaParenT2 contained
syn region  javaParenT2 transparent matchgroup=javaParen2 start="\[" end="\]" contains=@javaTop,javaParenT  contained
syn match   javaParenError	"\]"

hi def link javaParenError	javaError

if exists("java_highlight_functions")
  " Make ()-matching definitions after the parenthesis error catcher.
  if java_highlight_functions == "signature"
    syn keyword javaParamModifier contained final
    hi def link javaParamModifier javaConceptKind
    syn keyword javaLambdaVarType contained var
    hi def link javaLambdaVarType javaOperator

    " Note that here and elsewhere a single-line token is used for \z,
    " with other tokens repeated as necessary, to overcome the lack of
    " support for multi-line matching with \z.
    "
    " Match:	([@A [@B ...] final] var a[, var b, ...]) ->
    "		| ([@A [@B ...] final] T a[, T b, ...]) ->
    " As general and befitting the supported list of formal parameters
    " of a lambda expression as the following pattern is, it would
    " still fail to match an expression with an interspersed comment
    " or with a parameterised lambda parameter type written across
    " multiple lines.
    syn region  javaLambdaDef1 transparent matchgroup=javaLambdaDef start=/\k\@4<!(\%([[:space:]\n]*\%(\%(@\%(\K\k*\.\)*\K\k*\>\%((\_.\{-1,})\)\{-,1}[[:space:]\n]\+\)*\%(final[[:space:]\n]\+\)\=\%(\<\K\k*\>\.\)*\<\K\k*\>\%(<[^(){}]*[[:space:]-]\@<!>\)\=\%(\%(\%(\[\]\)\+\|\.\.\.\)\)\=[[:space:]\n]\+\<\K\k*\>\%(\[\]\)*\%(,[[:space:]\n]*\)\=\)\+)[[:space:]\n]*\z(->\)\)\@=/ end=/)[[:space:]\n]*\z1/ contains=javaAnnotation,javaParamModifier,javaLambdaVarType,javaType,@javaClasses,javaGenerics,javaVarArg
    " Match:	() ->
    "		| (a[, b, ...]) ->
    syn region  javaLambdaDef2 transparent matchgroup=javaLambdaDef start=/\k\@4<!(\%([[:space:]\n]*\%(\<\K\k*\>\%(,[[:space:]\n]*\)\=\)*)[[:space:]\n]*\z(->\)\)\@=/ end=/)[[:space:]\n]*\z1/
    " Match:	a ->
    syn region  javaLambdaDef3 transparent start=/\<\K\k*\>\%(\<default\>\)\@<!\%([[:space:]\n]*\z(->\)\)\@=/ matchgroup=javaLambdaDef end=/\z1/
    syn cluster javaTop add=javaLambdaDef1,javaLambdaDef2,javaLambdaDef3
  else
    syn match   javaLambdaDef "\<\K\k*\>\%(\<default\>\)\@<!\s*->"
    syn match   javaLambdaDef "\k\@4<!(\%(\k\|[[:space:]<>?\[\]@,.]\)*)\s*->"
    syn cluster javaTop add=javaLambdaDef
  endif
endif

if !exists("java_minlines")
  let java_minlines = 10
endif

" Note that variations of a /*/ balanced comment, e.g., /*/*/, /*//*/,
" /* /*/, /*  /*/, etc., may have their rightmost /*/ part accepted
" as a comment start by ':syntax sync ccomment'; consider alternatives
" to make synchronisation start further towards file's beginning by
" bumping up g:java_minlines or issuing ':syntax sync fromstart' or
" preferring &foldmethod set to 'syntax'.
exec "syn sync ccomment javaComment minlines=" . java_minlines

" The default highlighting.
hi def link javaLambdaDef		Function
hi def link javaFuncDef			Function
hi def link javaVarArg			Function
hi def link javaBranch			Conditional
hi def link javaUserLabelRef		javaUserLabel
hi def link javaLabel			Label
hi def link javaUserLabel		Label
hi def link javaConditional		Conditional
hi def link javaRepeat			Repeat
hi def link javaExceptions		Exception
hi def link javaAssert			Statement
hi def link javaStorageClass		StorageClass
hi def link javaMethodDecl		javaStorageClass
hi def link javaClassDecl		javaStorageClass
hi def link javaScopeDecl		javaStorageClass
hi def link javaConceptKind		NonText

hi def link javaBoolean			Boolean
hi def link javaSpecial			Special
hi def link javaSpecialError		Error
hi def link javaSpecialCharError	Error
hi def link javaString			String
hi def link javaCharacter		Character
hi def link javaSpecialChar		SpecialChar
hi def link javaNumber			Number
hi def link javaError			Error
hi def link javaStringError		Error
hi def link javaTextBlockError		Error
hi def link javaStatement		Statement
hi def link javaOperator		Operator
hi def link javaComment			Comment
hi def link javaDocComment		Comment
hi def link javaLineComment		Comment
hi def link javaConstant		Constant
hi def link javaTypedef			Typedef
hi def link javaTodo			Todo
hi def link javaAnnotation		PreProc
hi def link javaAnnotationStart		javaAnnotation

hi def link javaCommentTitle		SpecialComment
hi def link javaDocTags			Special
hi def link javaDocCodeTag		Special
hi def link javaDocSnippetTag		Special
hi def link javaDocParam		Function
hi def link javaDocSeeTagParam		Function
hi def link javaCommentStar		javaComment

hi def link javaType			Type
hi def link javaExternal		Include

hi def link htmlComment			Special
hi def link htmlCommentPart		Special
hi def link htmlArg			Type
hi def link htmlString			String
hi def link javaSpaceError		Error

if s:module_info_cur_buf
  hi def link javaModuleStorageClass	StorageClass
  hi def link javaModuleStmt		Statement
  hi def link javaModuleExternal	Include
endif

let b:current_syntax = "java"

if main_syntax == 'java'
  unlet main_syntax
endif

let b:spell_options = "contained"
let &cpo = s:cpo_save
unlet s:cpo_save s:module_info_cur_buf s:selectable_regexp_engine

" vim: ts=8
