xquery version "3.0";
            
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(:~
 : Content Negotiation 
 : Evaluate Accept header and resource suffix to serve appropriate media type
 :
 : @return 'html' or 'xml' (json could easily be added)
~:)
declare function local:media-type() as xs:string {
    let $suffix := substring-after($exist:resource, '.')
    let $accepted-content-types := tokenize(normalize-space(request:get-header('accept')), ',\s?')
    return
        (: explicit suffix takes precedence :)
        if(matches($suffix, '^x?html?$')) then 'html'
        else if(matches($suffix, '^x[mq]l$')) then 'xml'
        
        (: Accept header follows if no suffix is given :)
        else if($accepted-content-types[1] = ('text/html', 'application/xhtml+xml')) then 'html'
        else if($accepted-content-types[1] = ('application/xml', 'application/tei+xml')) then 'xml'
        
        (: if nothing matches fall back to xml :)
        else 'xml'
};

(:
 : ******************************
 : Controller forwards start here
 : ******************************
 :)

(: 
 : redirect to index page if no resource is given 
 :)
if (matches($exist:path, '^/?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<redirect url="index.{local:media-type()}">
    	   <cache-control cache="yes"/>
    	</redirect>
    </dispatch>

(: 
 : forward 'index' with any or empty suffix to codesharing.xql
 : media type gets evaluated by local:media-type()
 :)
else if (matches($exist:path, '^/index(\.\w+)?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{$exist:controller}/modules/codesharing.xql">
    	  <add-parameter name="outputType" value="{local:media-type()}"/>
    	</forward>
    </dispatch>

(: 
 : everything is passed through, especially the data collection 
 :)
else 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
    