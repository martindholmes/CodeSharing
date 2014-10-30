xquery version "3.0";
(: 
Copyright Martin Holmes. 
Dual-licensed under CC-by and BSD2 licences 
$Date$
$Id$
:)

(:
    This is a configuration file for an implementation of the TEI CodeSharing API. 
    
    Set the variables in this file to suit your own project.
    
    The associated CodeSharing library provides access to code samples 
    from the project database, in the form of <egXML> elements in the TEI Examples namespace.
    This implementation serializes the results as TEI XML with the TEI mime type.
    
    This is open-source software written by Martin Holmes at the University of Victoria 
    Humanities Computing and Media Centre. It is available under the Mozilla Public Licence
    version 1.1.
:)

module namespace cs="http://hcmc.uvic.ca/namespaces/exist/codesharing";

declare namespace exist = "http://exist.sourceforge.net/NS/exist"; 

(: This should be set to application/tei+xml, but that makes Firefox open a fresh tab, which is annoying. :)
declare option exist:serialize "method=xml media-type=application/xml encoding=utf-8 indent=yes";

(: ---------------------------------------------------------------------------------------------------------------:)
(: USER SETTINGS YOU SHOULD EDIT TO SUIT YOUR PROJECT.                               :)
(: ---------------------------------------------------------------------------------------------------------------:)
(: Set this variable to point to the collection where you keep your TEI data. :)
declare variable $cs:rootCol := '/db/data/';

(: Set this variable to the absolute maximum number of items you want to return in 
  one operation, to avoid bringing your web application to its knees. :)
declare variable $cs:absoluteMaxItemsPerPage := 100;

(: Set this variable to a number which makes sense as a default value for paging
   of results. :)
declare variable $cs:defaultMaxItemsPerPage := 10;

(: This is a list of elements that should only be returned in smaller sets because 
  they're typically very large. Modify at will, depending on your documents and 
  server capacity. Root TEI elements are not returned by default; your site should 
  already provide access to TEI documents in XML format. :)
declare variable $cs:hugeElements    := ('teiHeader', 'text', 'front', 'back', 'body');
declare variable $cs:largeElements   := ('div', 'facsimile', 'listPerson', 'listBibl');
declare variable $cs:mediumElements   := ('p', 'ab');

(: Set this variable to a string which identifies your project. :)
declare variable $cs:projectName := 'The Map of Early Modern London';

(: If you want to provide access to the protocol description document,
   set this variable appropriately. :)
declare variable $cs:protocolDescUrl := 'data/codesharing_protocol.xhtml';

(: Set this variable to a suitable string. :)
declare variable $cs:noResultsFound := 'No results found.';

(: Set this string to a useful explanation of the site and the API itself. :)
declare variable $cs:identification := concat('TEI CodeSharing service by Martin Holmes, running on ', $cs:projectName, '.');

(: TEI has many ways to specify document types. This default implementation assumes that the 
   document types are enumerated in a tei:taxonomy element with a specific @xml:id. 
   If you have such a taxonomy, change the xml:id below to match it; otherwise, you could customize 
   the code in codesharing.xql which retrieves document types, and that which uses document
   type as a filter for examples. :)
declare variable $cs:documentTypeTaxonomyId := 'molDocumentTypes';

(: This function returns a more constrained value for the maximum items allowed in one result 
   set, based on tag name and whether the tag is to be returned "wrapped" in its parent element 
   or not. Customize this function to meet the needs of your project and server. 
   
   @param $requestedMaxItems number of items requested by user as xs:integer.
   @param $elementName the name of the element of which examples are being requested as xs:string.
   @param $wrapped whether or not the user has requested the element be returned in the context
                                   of its parent as xs:boolean.
   @return the number of examples that should be returned as xs:integer.
   
   :)
declare function cs:refineMaxItemsPerPage($requestedMaxItems as xs:integer, 
                                          $elementName as xs:string, 
                                          $wrapped as xs:boolean) as xs:integer{
        if ($elementName = $cs:hugeElements) then 1
        else
            if ($elementName = $cs:largeElements) then 
                if ($wrapped = true()) then 1
                    else 3
            else
                if ($elementName = $cs:mediumElements and $wrapped = true()) then 3
                else
                    $requestedMaxItems
};

(:~
 : creates URLs for a given element (called by codesharing.xql/local:toEgXML())
 : modify function to suit your own needs of linking to the according resources
 :
 : @param $el some TEI element found by a codesharing query
 : @return an URL 
~:)
declare function cs:link-to-resource($el as element()) as xs:string? {
    root($el)/*[1]/@xml:id || '.xml'
};
