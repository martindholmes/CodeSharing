xquery version "3.0";
(: 
Copyright Martin Holmes. 
Dual-licensed under CC-by and BSD2 licences 
$Date$
$Id$
:)

(:
    This is an implementation of the TEI CodeSharing API. It provides access to code samples 
    from the project database, in the form of <egXML> elements in the TEI Examples namespace.
    This implementation serializes the results as TEI XML with the TEI mime type.
    
    This is open-source software written by Martin Holmes at the University of Victoria 
    Humanities Computing and Media Centre. It is available under the Mozilla Public Licence
    version 1.1.
    
    This library depends on the accompanying module codesharing_config.xql, which contains
    some variables that need to be set on a project basis.
    
    This library is written for the eXist XML database version 3.0. To run it with another 
    XQuery processor, changes would obviously have to be made to the code.
:)

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace teix="http://www.tei-c.org/ns/Examples";
declare namespace exist = "http://exist.sourceforge.net/NS/exist"; 
declare namespace local="http://hcmc.uvic.ca/ns/local";
declare namespace transform="http://exist-db.org/xquery/transform";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace ft="http://exist-db.org/xquery/lucene";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace cs ="http://hcmc.uvic.ca/namespaces/exist/codesharing" at "codesharing_config.xql";

(: This should be set to application/tei+xml, but that makes Firefox open a fresh tab, which is annoying. :)
declare option exist:serialize "method=xml media-type=application/xml encoding=utf-8 indent=yes expand-xincludes=no";

(: For debugging only; optimizer should be on. :)
(:declare option exist:optimize "enable=no";:)

(: ------------------------------------------------------------------------------:)
(: OTHER VARIABLES RETRIEVED OR CALCULATED FROM INPUT PARAMETERS.                :)
(: ------------------------------------------------------------------------------:)

(: Are we producing XML or HTML? :)
declare variable $local:inputOutputType := request:get-parameter('outputType', 'xml');
declare variable $local:outputType := if (matches($local:inputOutputType, '^((xml)|(html))$')) then $local:inputOutputType else 'xml';

(: The URL we came in on, without the query string. :)
(: Note: we make this a relative URL, otherwise various 
  problems can occur when the form re-submits to itself. :)
declare variable $local:url := tokenize(request:get-uri(), '/')[position() = last()];

(: We need to sanitize inputs as well as we can. We can do this 
   by regexes and attempted casts to XML Schema datatypes. :)

(: The from variable holds the number to start from when paging through results. :)
declare variable $local:from := xs:integer(request:get-parameter('from', '1'));

(: If the verb parameter is missing, we default to 'identify', which should supply enough info 
  for a user to figure out what they should be asking for. :)
declare variable $local:verb := request:get-parameter('verb', 'identify');

(: The user may be interested only in specific namespaces. We default to TEI, naturally. :)
declare variable $local:inputNamespace := if ($local:verb != 'listNamespaces') then request:get-parameter('namespace', 'http://www.tei-c.org/ns/1.0') else '';
declare variable $local:namespace := if ($local:inputNamespace castable as xs:anyURI and matches($local:inputNamespace, '^[a-zA-Z]+://')) then $local:inputNamespace else '';
declare variable $local:namespaceDeclaration := if ($local:namespace = '') then '' else concat("declare namespace temp='", $local:namespace, "'; ");
(: If the verb is getExamples, then we need to know the element and/or attribute name and value. :)
declare variable $local:inputElementName := if ($local:verb = 'getExamples') then request:get-parameter('elementName', '') else '';
declare variable $local:elementName := if ($local:inputElementName castable as xs:NCName) then $local:inputElementName else '';
declare variable $local:inputAttributeName := if ($local:verb = 'getExamples') then request:get-parameter('attributeName', '') else '';
declare variable $local:attributeName := if ($local:inputAttributeName castable as xs:NCName) then $local:inputAttributeName else '';
(: This is a bit harder to sanitize; we'll assume, though, that 
   in order to break out of the string value, a quote or entity 
   will need to be injected, so we will escape them all. :)
declare variable $local:attributeValue := if ($local:verb = 'getExamples') then local:sanitizeString(request:get-parameter('attributeValue', '')) else '';

(:The wrapped setting determines whether the hits will be returned in the context of their parent element. :)
declare variable $local:wrapped := if (request:get-parameter('wrapped', 'false') = 'true') then true() else false();

(: The user's preferred number of returns, which is overridden by the above absolute limit.
   We also impose absolute limits on specific elements that can be excessively large. :)
declare variable $local:userMaxItemsPerPage := xs:integer(request:get-parameter('maxItemsPerPage', $cs:defaultMaxItemsPerPage));
declare variable $local:maxItemsPerPage := cs:refineMaxItemsPerPage($local:userMaxItemsPerPage, $local:elementName, $local:wrapped);

(:The documentType filters the results according to a specific document type.:)
declare variable $local:documentType := if ($local:verb = 'getExamples') then local:sanitizeString(normalize-space(request:get-parameter('documentType', ''))) else '';

(: We'll retrieve the examples irrespective of what the verb is, so that they are 
accessible globally for counting and navigation through the list. :)
declare variable $local:egs := local:getEgs();
declare variable $local:totalInstances := count($local:egs);

(: Now we know how many examples there are, we can calculate the next item for paging. :)
declare variable $local:next := if (($local:from + $local:maxItemsPerPage) le count($local:egs)) then $local:from + $local:maxItemsPerPage else 0;
(: We can also calculate a previous page link. :)
declare variable $local:prev := if (($local:from - $local:maxItemsPerPage) ge 1) then $local:from - $local:maxItemsPerPage else 0;

(: These variables are used to create paging links for working through example lists. :)
declare variable $local:query := request:get-query-string();
declare variable $local:currParams := if (matches($local:query, 'from=[\d]+')) then $local:query else concat($local:query, '&amp;from=1');
declare variable $local:nextParams := if ($local:next gt 0) then replace($local:currParams, 'from=[\d]+', concat('from=', $local:next)) else "";
declare variable $local:prevParams := if ($local:prev gt 0) then replace($local:currParams, 'from=[\d]+', concat('from=', $local:prev)) else ""; 

(: Actual complete links for paging. :)
declare variable $local:nextUrl := if (string-length($local:nextParams) gt 0) then concat($local:url, '?', $local:nextParams) else "";
declare variable $local:prevUrl := if (string-length($local:prevParams) gt 0) then concat($local:url, '?', $local:prevParams) else "";

(: ------------------------------------------------------------------------------:)
(: FUNCTIONS THAT DO ALL THE ACTUAL WORK.                                        :)
(: ------------------------------------------------------------------------------:)

(: This is the main function that produces all the results. 

    @return a sequence of element()s retrieved or constructed based on the 
                  variables containing the external input parameters.
:)
declare function local:processVerb() as element()*{
  switch ($local:verb)
(: Listing the distinct values of element names in the target namespace. 
  Thanks to Jens Østergaard Petersen for a good suggestion for 
  optimizing this. :)
    case 'listElements' return
      try{
        let $q := 
          if ($local:namespace = '') then concat("distinct-values(collection('", $cs:rootCol, "')//*[namespace-uri()='']/local-name())")
          else concat("distinct-values(collection('", $cs:rootCol, "')//temp:*/local-name())"),
        $gis := util:eval(concat($local:namespaceDeclaration, $q))
        return
        if (count($gis) gt 1) then
         <list>
         {for $gi in $gis
         order by $gi
         return <item><gi>{$gi}</gi></item>}
         </list>
        else
          <p>{$cs:noResultsFound}</p>
      }
      catch * {<p>{$cs:noResultsFound}</p>}
      
(:  Listing attributes is quite messy. We want two types of attribute, those which are explicitly in the namespace
    we're interested in, and those which are unprefixed [i.e. no-namespace] children of elements 
    in the namespace we're interested in. We do it this way because that's what most people would
    intuitively expect. If I specify the TEI namespace, I'd expect to get the TEI attributes back, even though
    strictly speaking that would be wrong. :)
    
   case 'listAttributes' return
    try{
      let $q := 
        if ($local:namespace = '') then concat("distinct-values(collection('", $cs:rootCol, "')//*/@*[namespace-uri() = '']/name())")
        else concat("distinct-values((collection('", $cs:rootCol, "')//*/@temp:*/name(), collection('", $cs:rootCol, "')//temp:*/@*[namespace-uri()='']/name()))"),
      $atts := util:eval(concat($local:namespaceDeclaration, $q))
      return if (count($atts) gt 0) then
      (:if (collection($cs:rootCol)//node()/@*[namespace-uri() = $namespace] or collection($cs:rootCol)//node()[namespace-uri() = $namespace]/@*[namespace-uri() = ""]) then:)
        <list>
        {
        for $att in $atts
        order by $att
        return 
        if (string-length($att) gt 0) then 
          <item><att>{$att}</att></item>
        else 
          ()
        }
        </list>
      else
        <p>{$cs:noResultsFound}</p>
       }
      catch * {<p>{$cs:noResultsFound}</p>}
      
(: Listing namespaces appears to be quite straightforward, although the reserved 
   xml-prefix namespace doesn't seem to be returned for some reason. :)
   case 'listNamespaces' return
    try{
      if (collection($cs:rootCol)//node()) then
        <list>
        {for $ns in distinct-values(collection($cs:rootCol)//(*|@*)/namespace-uri())
        order by $ns
        return 
        if (string-length($ns) gt 0) then
          <item><ptr target="{$ns}"/></item>
          else
          <item>[empty namespace]</item>
        }
        </list>
      else
        <p>{$cs:noResultsFound}</p>
       }
      catch * {<p>{$cs:noResultsFound}</p>}
      
(: Listing the document types will typically vary from project to project, since there are so many ways 
   of encoding or deriving such information from TEI encoding. This example implementation uses the 
   TEI textClass/catRef/@target attribute, and expects to find the category descriptions in a taxonomy
   with the @xml:id defined in the configuration file. This is very TEI-specific, and in this respect it rather 
   contrasts with the generic nature of the other verb parameters. :)
    case 'listDocumentTypes' return
    try{
      let $docTypeList := cs:getDocumentTypeList()
      return
      if ($docTypeList) then
       $docTypeList
      else
        <p>{$cs:noResultsFound}</p>
     }
      catch * {<p>{$cs:noResultsFound}</p>}
      
(: If the verb is getExamples, then we process and render all the examples we already
  retrieved. :)
   case 'getExamples' return 
    local:renderCodeSamples($local:egs)
   default return ()
};

(: This function retrieves a set of nodes which match the input parameters. 

    @return a sequence of element()s retrieved from the document collection
                  based on the input parameters.
:)
declare function local:getEgs() as element()*{
      if ($local:verb != 'getExamples') then () 
      else
        let $doctypePredicate := if ($local:documentType) then cs:getDocumentTypeFilterPredicate($local:documentType) else ""
        return
      try {
        if (string-length($local:elementName) gt 0 and string-length($local:attributeName) gt 0) then
  (: Attributes in the context of an element.   :)
        if (string-length($local:attributeValue) gt 0) then
  (: An attribute value is specified. :)
          let $q := concat("collection('", $cs:rootCol, "')//tei:TEI", $doctypePredicate, "//*:", $local:elementName, "[namespace-uri() = '", $local:namespace, "'][@", $local:attributeName, "='", $local:attributeValue, "']")
          return util:eval($q)
        else
  (: An attribute value is not specified. :)
          let $q := concat("collection('", $cs:rootCol, "')//tei:TEI", $doctypePredicate, "//*:", $local:elementName, "[namespace-uri() = '", $local:namespace, "'][@", $local:attributeName, "]")
          return util:eval($q)
        else
          if  (string-length($local:elementName) gt 0) then
  (: Element is named but not attribute, although a value may still be supplied for attribute.       :)
            if (string-length($local:attributeValue) gt 0) then
  (: There's an attribute value but no name for it.        :)
              let $q := concat("collection('", $cs:rootCol, "')//tei:TEI", $doctypePredicate, "//*:", $local:elementName, "[namespace-uri() = '", $local:namespace, "'][@*='", $local:attributeValue, "']")
              return util:eval($q)
            else
  (: There's just an element name. Easy one. :)
              let $q := concat("collection('", $cs:rootCol, "')//tei:TEI", $doctypePredicate, "//*:", $local:elementName, "[namespace-uri() = '", $local:namespace, "']")
              return util:eval($q)
          else 
            if (string-length($local:attributeName) gt 0) then
  (: Attributes irrespective of their parent element. :)
  (: In this case, we have to retrieve in no namespace as well as in the specified
     namespace. This is designed to produce intuitive results 
     as well as results which are strictly speaking correct. :)
              if (string-length($local:attributeValue) gt 0) then
  (: An attribute value is specified. :)
                let $q := concat("collection('", $cs:rootCol, "')//tei:TEI", $doctypePredicate, "//*[@*:", $local:attributeName, "[.='", $local:attributeValue, "' and (namespace-uri() = '' or namespace-uri() = '", $local:namespace, "')]]")
                return util:eval($q)
              else
  (: An attribute value is not specified. :)
              let $q := concat("collection('", $cs:rootCol, "')//tei:TEI", $doctypePredicate, "//*[@*:", $local:attributeName, "[namespace-uri() = '' or namespace-uri() = '", $local:namespace, "']]")
                return util:eval($q)
            else
              if (string-length($local:attributeValue) gt 0) then 
  (: An attribute value and nothing else has been specified. :)
                  let $q := concat("collection('", $cs:rootCol, "')//tei:TEI", $doctypePredicate, "//*[@*[.='", $local:attributeValue, "' and (namespace-uri() = '' or namespace-uri() = '", $local:namespace, "')]]")
                return util:eval($q)
              else
              ()
           }
           catch * {()}
};

(: This renders a set of example nodes into a div full of <egXML> elements. 
    
    @param $egs code samples as a sequence of node()s.
    @return a sequence of <egXML> elements, each containing an example
                 converted to the Examples namespace.

:)
declare function local:renderCodeSamples($egs as node()*) as element()*{
  let $lastItem := min((count($egs), $local:from + $local:maxItemsPerPage - 1))
  return
    if (count($egs) gt 0) then
      <div>
       {
      for $i in $local:from to $lastItem
        return
          if ($local:wrapped = true()) then
            local:toEgXML($egs[$i]/parent::*)
          else
            local:toEgXML($egs[$i])
      }
      </div>
    else
      <p>{$cs:noResultsFound}</p>
};

(: This function wraps an element in the <egXML> parent 
   and calls a function to change its namespace to the 
   TEI Examples namespace. Thanks to Michael Joyce for 
   a patch here which allows for TEI elements that don't
   have @xml:ids.
   
   @param $el the element to be wrapped in <egXML>, and whose namespace is to be changed.
   @return an <egXML> element in the Examples namespace and containing a copy of 
                 $el with the same local-name, but switched to the Examples namespace.
                 
   :)
declare function local:toEgXML($el as element()) as element()*{
    let $source :=
            (:if(root($el)/*[1]/@xml:id) then 
                root($el)/*[1]/@xml:id
            else
                util:document-name(root($el)):)
            document-uri(root($el))
  return 
      <egXML xmlns="http://www.tei-c.org/ns/Examples" source="/exist/rest{$source}">
      {local:toExampleNamespace($el)}
      </egXML>
};

(: This function is called recursively to change the namespace of elements
   to the TEI Examples namespace. 
   
   @param $el the element whose namespace is to be changed as element().
   @return a copy of the element with the same local-name but in the Examples 
                namespace, as element().
   
   :)
declare function local:toExampleNamespace($el as element()) as element()*{
  element {QName("http://www.tei-c.org/ns/Examples", $el/local-name())}
  {$el/@*,
  for $child in $el/(*|text()) 
  (:return if ($child/self::text()) then $child else:)
  return if ($child instance of text()) then $child else
  local:toExampleNamespace($child)}
};

(: This function is borrowed with thanks from Eric van der Vlist, 
   http://www.balisage.net/Proceedings/vol7/print/Vlist02/BalisageVol7-Vlist02.html
   
   @param $text the input string as xs:string.
   @return xs:string with the ampersands, apostrophes and quotes escaped.
   
   :)
declare function local:sanitizeString($text as xs:string) as xs:string {
  let $s := replace(replace($text, '&amp;', '&amp;amp;'), '''', '&amp;apos;')
  return replace($s, '"', '&amp;quot;')
};


(: ------------------------------------------------------------------------------:)
(: THE OUTPUT DOCUMENT, WHICH IS TEI XML.                                        :)
(: ------------------------------------------------------------------------------:)

let $doc := 
<TEI xmlns="http://www.tei-c.org/ns/1.0" version="5.0">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>TEI Code Samples from {$cs:projectName}</title>
            </titleStmt>
            <publicationStmt>
                <p>These code samples are provided by {$cs:projectName}, through the 
                TEI CodeSharing API.</p>
            </publicationStmt>
            <sourceDesc>
                <p>Born-digital code examples.</p>
            </sourceDesc>
        </fileDesc>
    </teiHeader>
    <text>
    <front>
      <!-- The front matter consists of lots of values and variables 
          from the input parameters, or calculated based on the
          input and the query. @xml:id values are prefixed with 
          "cs_" for "CodeSharing". 
          
          The specification mandates that elements with the following
          @xml:ids exist in the <front> of the document:
          
          cs_project
          cs_verb
          cs_namespace
          cs_elementName
          cs_attributeName
          cs_attributeValue
          cs_wrapped
          cs_totalInstances
          cs_nextUrl
          
          All other values are optional, but will be documented in the specification.
          
          This library can be slightly streamlined by the removal of the optional values
          in the output, but they can be handy for debugging and for enhanced functionality.
          
          -->
      <div>
        <p>Input values and calculated variables:
          <list>
            <label>project</label> <item xml:id="cs_project">{$cs:projectName}</item>
            <label>verb</label> <item xml:id="cs_verb">{$local:verb}</item>
            <label>namespace</label> <item xml:id="cs_namespace">{$local:namespace}</item>
            <label>elementName</label> <item xml:id="cs_elementName">{$local:elementName}</item>
            <label>attributeName</label> <item xml:id="cs_attributeName">{$local:attributeName}</item>
            <label>attributeValue</label> <item xml:id="cs_attributeValue">{$local:attributeValue}</item>
            <label>documentType</label> <item xml:id="cs_documentType">{$local:documentType}</item>
            <label>wrapped</label> <item xml:id="cs_wrapped">{$local:wrapped}</item>
            <label>defaultMaxItemsPerPage</label> <item xml:id="cs_defaultMaxItemsPerPage">{$cs:defaultMaxItemsPerPage}</item>
            <label>absoluteMaxItemsPerPage</label> <item xml:id="cs_absoluteMaxItemsPerPage">{$cs:absoluteMaxItemsPerPage}</item>
            <label>maxItemsPerPage</label> <item xml:id="cs_maxItemsPerPage">{$local:maxItemsPerPage}</item>
            <label>totalInstances</label> <item xml:id="cs_totalInstances">{$local:totalInstances}</item>
            <label>from</label> <item xml:id="cs_from">{$local:from}</item>
            <label>next</label> <item xml:id="cs_next">{$local:next}</item>
            <label>currParams</label> <item xml:id="cs_currParams">{$local:currParams}</item>
            <label>nextParams</label> <item xml:id="cs_nextParams">{$local:nextParams}</item>
            <label>prevParams</label> <item xml:id="cs_prevParams">{$local:prevParams}</item>
            <label>url</label> <item xml:id="cs_url">{$local:url}</item>
            <label>nextUrl</label> <item xml:id="cs_nextUrl">{$local:nextUrl}</item>
            <label>prevUrl</label> <item xml:id="cs_prevUrl">{$local:prevUrl}</item>
          </list>
        </p>
      </div>
    </front>
    <body>
    
    <!-- 
    The body of the file consists of a <div> containing a series of
    <egXML> elements, each containing one instance of the 
    element resulting from the request; or it may consist of a list
    of element names, attribute names, or namespace URIs.
    -->
    
      {local:processVerb()}
    </body>
    
    <back>
      <div>
        <p>{$cs:identification}</p>
        <p><ref target="{$cs:protocolDescUrl}">More information</ref></p>
      </div>
    </back>
    
    </text>
</TEI>
    
return if ($local:outputType = 'xml') then 
  $doc
else 
  let $opt := util:declare-option('exist:serialize', 'method=html5 media-type=text/html') 
  return
  transform:transform($doc, doc("codesharing.xsl"), ())