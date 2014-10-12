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
xquery version "3.0";

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

(: This is a list of elements that should only be returned one at a time because 
  they're typically very large. Modify at will, depending on your documents and 
  server capacity. Root TEI elements are not returned by default; your site should 
  already provide access to TEI documents in XML format. :)
declare variable $cs:largeElements := ('teiHeader', 'text', 'front', 'back', 'body');

(: Set this variable to a string which identifies your project. :)
declare variable $cs:projectName := 'The Map of Early Modern London';

(: If you want to provide access to the protocol description document,
   set this variable appropriately. :)
declare variable $cs:protocolDescUrl := 'codesharing_protocol.xhtml';

(: Set this variable to a suitable string. :)
declare variable $cs:noResultsFound := 'No results found.';

(: Set this string to a useful explanation of the site and the API itself. :)
declare variable $cs:identification := concat('TEI CodeSharing service, running on ', $cs:projectName, '.');

(: TEI has many ways to specify document types. This default implementation assumes that the 
   document types are enumerated in a tei:taxonomy element with a specific @xml:id. :)
declare variable $cs:documentTypeTaxonomyId := 'molDocumentTypes';
