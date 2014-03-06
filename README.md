lua4ht
======

This is package for direct generating html code with `tex4ht` and `lualatex`, 
without need to process the dvi file with `tex4ht` command.

Details
-------


Normally, when compiling LaTeX file with `htlatex` or similar script from the
`tex4ht` bundle, `tex4ht.sty` file is included by the script. 
`tex4ht.sty` and commands defined in `.4ht` files insert `\special{t4ht...}`
 instructions to the output file. This output file is then processes with 
`tex4ht` command, `html` files are generated at this stage. As last step, `t4ht`
is called, which is used to generate `css` file and to run various conversion
commands, like `dvi` to `png` for math.

This package aims at removing need to use `tex4ht` command. Main reason for this
is that `tex4ht` doesn't support fonts without `tfm` table, which means that
`opentype` and `truetype` fonts used by `fontspec` package cannot be used.

At this moment, this is just a proof of concept, don't expect perfect results.
`tex4ht` support adding css information about used fonts, so font shape, weight,
size and other information is preserved. `lua4ht` doesn't support this at the
moment, only html tags requested by `\HCode` or `\Tag` commands are used.

Example
-------

    \documentclass{article}
    \usepackage{lua4ht}
    \usepackage{fontspec}
    \begin{document}
    Příliš \textit{žluťoučký} kůň úpěl ďábělské 
    ódy\footnote{Some text in a footnote}
    
    \begin{enumerate}
    \item Items in enumerated list
    \item another item
    \end{enumerate}
    
    \[\frac{a + b}{\sin{c}}\]
    \end{document}

To compile this document, use:

    dvilualatex sample
    dvilualatex sample
    dvilualatex sample
    t4ht sample

Generated document `sample.html`

    <?xml version="1.0" encoding="utf-8" ?> 
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" 
    "http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd" > 
    <html xmlns="http://www.w3.org/1999/xhtml"  
    > 
    <head><title></title> 
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" /> 
    <meta name="generator" content="TeX4ht (http://www.cse.ohio-state.edu/~gurari/TeX4ht/)" /> 
    <meta name="originator" content="TeX4ht (http://www.cse.ohio-state.edu/~gurari/TeX4ht/)" /> 
    <!-- xhtml,charset=utf-8,mathml,new-accents --> 
    <meta name="src" content="sample.tex" /> 
    <meta name="date" content="2014-03-06 12:41:00" /> 
    <link rel="stylesheet" type="text/css" href="sample.css" /> 
    </head><body 
    > <!--l. 6--><p class="noindent" >Příliš žluťoučký kůň úpěl ďábělské ódy<span class="footnote-mark"><a 
    href="sample2.html#fn1x0"><sup class="textsuperscript">1</sup></a></span><a 
     id="x1-2f1"></a>   </p><ol  class="enumerate1" > <li 
      class="enumerate" id="x1-4x1">Items in enumerated list </li> <li 
      class="enumerate" id="x1-6x2">another item</li></ol> <div class="par-math-display"><!--l. 13--><math 
     xmlns="http://www.w3.org/1998/Math/MathML"  
    display="block" ><mrow 
    ><mfrac><mrow 
    >a+b</mrow> <mrow 
    >sin<!--nolimits-->c</mrow></mfrac> </mrow></math></div> <!--l. 13--><p class="nopar" ></p> 
    </body></html> 
 
File with footnote text, `sample2.html`:

    <?xml version="1.0" encoding="utf-8" ?> 
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN" 
    "http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd" > 
    <html xmlns="http://www.w3.org/1999/xhtml"  
    > 
    <head><title></title> 
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" /> 
    <meta name="generator" content="TeX4ht (http://www.cse.ohio-state.edu/~gurari/TeX4ht/)" /> 
    <meta name="originator" content="TeX4ht (http://www.cse.ohio-state.edu/~gurari/TeX4ht/)" /> 
    <!-- xhtml,charset=utf-8,mathml,new-accents --> 
    <meta name="src" content="sample.tex" /> 
    <meta name="date" content="2014-03-06 12:41:00" /> 
    <link rel="stylesheet" type="text/css" href="sample.css" /> 
    </head><body 
    ><div class="footnote-text"> <!--l. 6--><p class="indent" > <span class="footnote-mark"><a 
     id="fn1x0"> <sup class="textsuperscript">1</sup></a></span>Some text in a footnote</p></div>  
    </body></html> 
 
As you can see, diacritics are preserved, but no styling of characters is 
provided, as `příliš \textit{žluťoučký}` s converted to `příliš žluťoučký`.

How it works
------------

`pre_output_filter` callback is used to traverse TeX nodes. `whatsit` nodes 
produced by `\special` commands are parsed in order to get html codes, 
names of output files, etc. At this moments, only few features are supported, 
for list of all possible specials see [section backend specials](http://michal-h21.github.io/mktex4ht/mktex4ht4.html).
