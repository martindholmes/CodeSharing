<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
  xmlns:hcmc="http://hcmc.uvic.ca/ns" 
  xmlns:exist="http://exist.sourceforge.net/NS/exist"
  xmlns:teix="http://www.tei-c.org/ns/Examples"
  exclude-result-prefixes="xs xd xhtml hcmc exist teix" 
  version="2.0" 
  xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> February 21, 2013</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This stylesheet renders the TEI output from 
              codesharing.xql into an XHTML5 page with a form. </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output encoding="UTF-8" method="xhtml" exclude-result-prefixes="#all" indent="no" doctype-system="about:legacy-compat"
    cdata-section-elements="script"/>
  
  
  <xsl:preserve-space elements="*"/>

<!-- All the parameters we need are included as data in the TEI input stream. -->
  
  
  <xsl:template match="/">
    <!--<xsl:text disable-output-escaping='yes'>
      &lt;!DOCTYPE html>
    </xsl:text>-->
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta charset="UTF-8"/> 
        <title><xsl:value-of select="TEI/teiHeader/fileDesc/titleStmt/title[1]"/></title>
        <script type="text/ecmascript">
            <xsl:comment>
            /* This function ensures that a return keypress in a textbox
               submits the form. */
               
            function submitOnReturn(e){
              if (e.keyCode == 13){
                return document.getElementById('codeSharingForm').submit();
              }
              else{
                return false;
              }
            }
            </xsl:comment>
        </script>
        
        <style type="text/css">
          <xsl:comment>
            
            /* Main style settings. */
           body{
              background-image: linear-gradient(top, rgb(200,200,200) 1%, rgb(255,255,255) 69%);
              background-image: -o-linear-gradient(top, rgb(200,200,200) 1%, rgb(255,255,255) 69%);
              background-image: -moz-linear-gradient(top, rgb(200,200,200) 1%, rgb(255,255,255) 69%);
              background-image: -webkit-linear-gradient(top, rgb(200,200,200) 1%, rgb(255,255,255) 69%);
              background-image: -ms-linear-gradient(top, rgb(200,200,200) 1%, rgb(255,255,255) 69%);
              
              background-image: -webkit-gradient(
              	linear,
              	left top,
              	left bottom,
              	color-stop(0.01, rgb(200,200,200)),
              	color-stop(0.69, rgb(255,255,255))
              );
              margin-left: 10%;
              margin-right: 10%;
              font-family: verdana, garamond, sans-serif;
           }
            
           h2, h3{
              text-align: center;
           }
           
           
            h4{
               background-color: #dddddd;
               border-color: #f0f0f0 #999999 #999999 #f0f0f0;
               border-style: solid;
               border-width: 2px;
               color: #000000;
               margin: 0;
               padding: 5px;
               text-align: left;
            }
           
           div {
              border-color: #000000;
              border-style: solid;
              border-width: 1px;
              margin-top: 2em;
              background-color: #ffffff;
           }
           
           div.results>div{
              border-width: 0;
           }
           
           div p{
             margin: 0.5em;
           }
           
           div.back{
              font-size: 75%;
              text-align: center;
              border-width: 0;
           }
           
           button, input, select{
              background-color: #d0d0d0;
           }
           
           label{
              display: inline-block;
              width: 10em;
           }
           
           span.hint{
             font-size: 80%;
             color: #a0a0a0;
           }
           
           button, input, select, label{
              margin-bottom: 0.25em;
              margin-top: 0.25em;
           }
           
           input[type=text], select{
             min-width: 18em;
           }
            
           /* Handling of example XML code embedded in pages. */
           
           div.egXML{
            display: block;
            padding: 0.5em;
            border-width: 1px 0px 0px 0px;
            border-style: solid;
            margin-top: 0.25em;
            margin-bottom: 0.25em;
            overflow: auto;
           }
           
           div.sourceDocLink{
            text-align: right;
            font-size: 80%;
            color: #990000;
            border-style: none;
           }
           
           .xmlTag, .xmlAttName, .xmlAttVal, .egXML{
             font-family: monospace;
           }
           
           .xmlTag, .xmlAttName, .xmlAttVal{
             font-weight: bold;
           }
           
           .xmlTag{
             color: #000099;
           }
           
           .xmlAttName{
             color: #f5844c;
           }
           
           .xmlAttVal{
             color: #993300;
           }
           
           .xmlComment{
             color: #009900;
           }
           
         
          </xsl:comment>
        </style>
      </head>
      <body>
        <xsl:apply-templates select="TEI/text/front"/> 
        <xsl:apply-templates select="TEI/text/body"/>
        <xsl:apply-templates select="TEI/text/back"/>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template match="front">
    <h2><xsl:value-of select="descendant::*[@xml:id='cs_project']/text()"/></h2>
    <h3>CodeSharing service</h3>
    
    <form id="codeSharingForm" accept-charset="UTF-8" action="{descendant::*[@xml:id='cs_url']/text()}" 
      method="get" enctype="application/x-www-form-urlencoded">
      <div>
        <h4>Search for code samples</h4>
        <p><label for="verb">What do you want to do? (verb)</label> 
        <select id="verb" name="verb">
          <option value="getExamples">
            <xsl:if test="descendant::*[@xml:id='cs_verb']/text() = 'getExamples'">
              <xsl:attribute name="selected">selected</xsl:attribute>
            </xsl:if>
            get examples</option>
          <option value="listElements">
            <xsl:if test="descendant::*[@xml:id='cs_verb']/text() = 'listElements'">
              <xsl:attribute name="selected">selected</xsl:attribute>
            </xsl:if>
            list all elements</option>
          <option value="listAttributes">
            <xsl:if test="descendant::*[@xml:id='cs_verb']/text() = 'listAttributes'">
              <xsl:attribute name="selected">selected</xsl:attribute>
            </xsl:if>
            list all attributes</option>
          <option value="listDocumentTypes">
            <xsl:if test="descendant::*[@xml:id='cs_verb']/text() = 'listDocumentTypes'">
              <xsl:attribute name="selected">selected</xsl:attribute>
            </xsl:if>
            list all document types</option>
          <option value="listNamespaces">
            <xsl:if test="descendant::*[@xml:id='cs_verb']/text() = 'listNamespaces'">
              <xsl:attribute name="selected">selected</xsl:attribute>
            </xsl:if>
            list all namespaces</option>
        </select>
        </p>
        
        <p>
          <label for="elementName">Element name</label> <input type="text" id="elementName" name="elementName" onkeypress="submitOnReturn(event)">
            <xsl:attribute name="value" select="descendant::*[@xml:id='cs_elementName']/text()"/>
          </input><br/>
          <label for="wrapped">Wrap element in parent</label> <input value="true" type="checkbox" id="wrapped" name="wrapped" onkeypress="submitOnReturn(event)"><xsl:if test="descendant::*[@xml:id='cs_wrapped']/text()='true'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if></input><br/>
          <label for="attributeName">Attribute name</label> <input type="text" id="attributeName" name="attributeName" onkeypress="submitOnReturn(event)">
            <xsl:attribute name="value" select="descendant::*[@xml:id='cs_attributeName']/text()"/>
          </input><br/>
          <label for="attributeValue">Attribute value</label> <input type="text" id="attributeValue" name="attributeValue" onkeypress="submitOnReturn(event)">
            <xsl:attribute name="value" select="descendant::*[@xml:id='cs_attributeValue']/text()"/>
          </input><br/>
          <label for="documentType">Document type</label> <input type="text" id="documentType" name="documentType" onkeypress="submitOnReturn(event)">
            <xsl:attribute name="value" select="descendant::*[@xml:id='cs_documentType']/text()"/>
          </input><br/>
          <label for="namespace">Namespace</label> <input type="text" id="namespace" name="namespace" onkeypress="submitOnReturn(event)">
            <xsl:attribute name="value" select="descendant::*[@xml:id='cs_namespace']/text()"/>
          </input><button onclick="document.getElementById('namespace').value = 'http://www.tei-c.org/ns/1.0'; return false;" title="Insert the TEI namespace.">← TEI</button><br/>
        </p>
        
        <p>
          <label for="maxItemsPerPage">Results per page</label>
          <select id="maxItemsPerPage" name="maxItemsPerPage">
            <xsl:variable name="currInstances" select="xs:integer(descendant::*[@xml:id='cs_maxItemsPerPage']/text())"/>
            <option value="1">
              <xsl:if test="$currInstances = 1">
                <xsl:attribute name="selected">selected</xsl:attribute>
              </xsl:if>
              1 (limit for huge elements)
            </option>
            <option value="3">
              <xsl:if test="$currInstances = 3">
                <xsl:attribute name="selected">selected</xsl:attribute>
              </xsl:if>
              3 (limit for large elements)
            </option>
            <xsl:variable name="lowInstances" select="xs:integer(descendant::*[@xml:id='cs_defaultMaxItemsPerPage']/text())"/>
            <xsl:variable name="highInstances" select="xs:integer(descendant::*[@xml:id='cs_absoluteMaxItemsPerPage']/text())"/>
            
            <xsl:for-each select="$lowInstances to $highInstances">
              <xsl:if test=". mod 10 = 0">
                <option value="{.}">
                  <xsl:if test=". = $currInstances">
                    <xsl:attribute name="selected">selected</xsl:attribute>
                  </xsl:if>
                  <xsl:value-of select="."/></option>
              </xsl:if>
            </xsl:for-each>
          </select>
        </p>
        
        <p><input type="submit" value="Submit"/></p>
      </div>
    </form>
  </xsl:template>
  
  <xsl:template match="body">
    <xsl:variable name="navButtons">
      <p>
      <xsl:if test="string-length(/TEI/text/front/descendant::*[@xml:id='cs_prevUrl']/text()) gt 0">
        <button onclick="location='{/TEI/text/front/descendant::*[@xml:id='cs_prevUrl']/text()}'">Previous (<xsl:value-of select="xs:integer(/TEI/text/front/descendant::*[@xml:id='cs_from']/text()) - xs:integer(/TEI/text/front/descendant::*[@xml:id='cs_maxItemsPerPage']/text())"/> - <xsl:value-of select="xs:integer(/TEI/text/front/descendant::*[@xml:id='cs_from']/text()) - 1"/>)</button>
      </xsl:if>
      <xsl:if test="string-length(/TEI/text/front/descendant::*[@xml:id='cs_nextUrl']/text()) gt 0">
        <button onclick="location='{/TEI/text/front/descendant::*[@xml:id='cs_nextUrl']/text()}'">Next (<xsl:value-of select="xs:integer(/TEI/text/front/descendant::*[@xml:id='cs_from']/text()) + xs:integer(/TEI/text/front/descendant::*[@xml:id='cs_maxItemsPerPage']/text())"/> - <xsl:value-of select="min((xs:integer(/TEI/text/front/descendant::*[@xml:id='cs_from']/text()) + (2 * xs:integer(/TEI/text/front/descendant::*[@xml:id='cs_maxItemsPerPage']/text())) - 1, xs:integer(/TEI/text/front/descendant::*[@xml:id='cs_totalInstances']/text())))"/> of <xsl:value-of select="/TEI/text/front/descendant::*[@xml:id='cs_totalInstances']/text()"/>)</button>
      </xsl:if>
      </p>
    </xsl:variable>
    
    <div class="results">
      <h4>Results</h4>
    <xsl:copy-of select="$navButtons"/>
    <xsl:apply-templates/>
    <xsl:copy-of select="$navButtons"/>
    </div>
  </xsl:template>
  
  <xsl:template match="list">
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>
  
  <xsl:template match="list/item">
    <li><xsl:apply-templates/></li>
  </xsl:template>
  
  <xsl:template match="ptr">
    <a href="{@target}"><xsl:value-of select="@target"/></a>
  </xsl:template>

  <xsl:template match="div">
    <div><xsl:apply-templates/></div>
  </xsl:template>
  
  <xsl:template match="back/div">
    <div class="back"><xsl:apply-templates/></div>
  </xsl:template>

  <xsl:template match="p">
    <p><xsl:apply-templates/></p>
  </xsl:template>
  
  <xsl:template match="ref">
    <a href="{@target}"><xsl:apply-templates/></a>
  </xsl:template>
  
  <xsl:template match="name">
    <strong><xsl:apply-templates/></strong>
  </xsl:template>
  
<!-- This section covers handling of documentation elements such as tag and 
      attribute names, and example XML code. -->
  
<!-- Handling of inline code elements. -->
  <xsl:template match="code">
    <code>
      <xsl:apply-templates select="@* | * | text()"/>
    </code>
  </xsl:template>
  
<!-- <gi> elements specify tag names, and should be embellished with angle brackets. -->
  <xsl:template match="gi"><code class="xmlTag">&lt;<xsl:value-of select="."/>&gt;</code></xsl:template>
  
  <!-- <att> elements specify attribute names, and should be prefixed with @. -->
  <xsl:template match="att"><code class="xmlAttName">@<xsl:value-of select="."/></code></xsl:template>
  
  <!-- <val> elements specify attribute values, and should be quoted. -->
  <xsl:template match="val"><code class="xmlAttVal">"<xsl:value-of select="."/>"</code></xsl:template>
  
<!-- Handling of <egXML> elements in the TEI example namespace. -->
  <xsl:template match="teix:egXML[not(ancestor::teix:egXML)]">
    <div class="egXML">
<!-- We need to add the initial space before the first element.     -->
<!-- Still unable to make this look right, whatever I do. Needs more work. 
      The initial space is always too big. -->
      <!--<xsl:if test="(child::* | child::text())[1][self::text()]">
       <xsl:value-of select="replace(replace(child::text()[1], '[ \t]', '&#160;'), '[\r\n]', '')"/>
      </xsl:if>-->
      <xsl:if test="(child::* | child::text())[1][self::text()]">
        <xsl:variable name="lastTextSpace" select="tokenize(child::text()[last()], '[\r\n]')[last()]"/>
        <xsl:if test="matches($lastTextSpace, '^\s+$')"><span class="space"><xsl:value-of select="replace($lastTextSpace, '[ \t]', '&#160;')"/></span></xsl:if>
      </xsl:if>
      <xsl:apply-templates/>
    <xsl:if test="@source">
      <div class="sourceDocLink">
      <a href="{@source}"><xsl:value-of select="@source"/></a>
      </div>
    </xsl:if>
    </div>
  </xsl:template>
  
<!-- Escaping all tags and attributes within the teix (examples) namespace except for 
the containing egXML. -->
<!-- This is very messy because of the need to avoid extraneous spaces in the output. -->
  <xsl:template match="teix:*[not(local-name(.) = 'egXML')]|teix:egXML[ancestor::teix:egXML]"><!-- Opening tag, including any attributes. --><span class="xmlTag">&lt;<xsl:value-of select="name()"/></span><xsl:for-each select="@*"><span class="xmlAttName"><xsl:text> </xsl:text><xsl:value-of select="name()"/>=</span><span class="xmlAttVal">"<xsl:value-of select="."/>"</span></xsl:for-each><xsl:choose><xsl:when test="hcmc:isSelfClosing(local-name())"><span class="xmlTag">/&gt;</span></xsl:when><xsl:otherwise><span class="xmlTag">&gt;</span><xsl:apply-templates select="* | text() | comment()"/><span class="xmlTag">&lt;/<xsl:value-of select="local-name()"/>&gt;</span></xsl:otherwise></xsl:choose></xsl:template>
  
  <xsl:template match="teix:*/text()[not(parent::teix:egXML)]">
    <span class="space"><xsl:analyze-string select="." regex="[\r\n]">
      <xsl:matching-substring><br/></xsl:matching-substring>
      <xsl:non-matching-substring><xsl:value-of select="replace(., '[ \t]', '&#160;')"/></xsl:non-matching-substring>
    </xsl:analyze-string></span></xsl:template>
  
<!-- We also need to process XML comments. -->
  <xsl:template match="teix:*/comment()">
    <span class="xmlComment">&lt;!-- <xsl:value-of select="."/> --&gt;</span><xsl:text>
</xsl:text>
  </xsl:template>

<!-- This function identifies tags which are typically used in self-closing mode, so that 
  they can be rendered in the same way in the output. -->
  <xsl:function name="hcmc:isSelfClosing" as="xs:boolean">
    <xsl:param name="tagName"/>
    <xsl:value-of select="$tagName = ('lb', 'pb', 'cb')"/>
  </xsl:function>
    
    <!-- 
    This function takes a string as input, and replaces all single and double 
    quotes with their numeric escapes, so that the string is safe to use in 
    attribute values.
    
  -->
  <xsl:function name="hcmc:escape-quotes" as="xs:string">
    <!-- Incoming parameters -->
    <xsl:param name="inString" as="xs:string" />
    <xsl:variable name="singlesDone" select="replace($inString, '''', '&amp;#x0027;')" />
    <xsl:variable name="output" select="replace($singlesDone, '&quot;', '&amp;#x0022;')" />
    <xsl:sequence select="$output" />
  </xsl:function>
  
  <!-- 
    This function takes a string as input, and replaces all double 
    quotes with their backslash escapes, so that the string is safe to use in 
    attribute values.
    
  -->
  <xsl:function name="hcmc:backslash-double-quotes" as="xs:string">
    <!-- Incoming parameters -->
    <xsl:param name="inString" as="xs:string" />
    <xsl:variable name="output" select="replace($inString, '&quot;', '\\&quot;')" />
    <xsl:sequence select="$output" />
  </xsl:function>

  
  
  
</xsl:stylesheet>