import module namespace re3mappings = "http://www.re3data.org/xsparql/r3dmappings" at "file:///C:/Users/Chile/Documents/GitHub/ontology/xsparql/r3dmappings.xq" ; 

declare namespace r3d="http://www.re3data.org/schema/3-0/";
declare namespace r3dfunc="http://www.re3data.org/functions/";
declare namespace lvont="http://lexvo.org/ontology#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace owl = "http://www.w3.org/2002/07/owl#";
declare namespace dc = "http://purl.org/dc/terms/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace datacite = "http://purl.org/spar/datacite/";
declare namespace sparql="http://xsparql.deri.org/demo/xquery/sparql-functions.xquery";
declare namespace litre =  "http://www.essepuntato.it/2010/06/literalreification/";

(: get namespace uri of prefixed uri string :)
declare function r3dfunc:resolve-prefixed-uri ( $n as xs:string )  {
    let $zw1 := fn:substring($n, 0, string-length(substring-before($n, ":"))+2)
    return if(fn:index-of(("r3d:", "r3dfunc:", "lvont:"), $zw1) > 0) then 
		fn:concat(fn:namespace-uri(element {fn:concat($zw1, "x")} {""}), fn:substring($n, string-length(substring-before($n, ":"))+2))
	else
		$n
};

(: create identifier :)
declare function r3dfunc:insert-identifier ( $uri as xs:string, $prop as xs:string, $scheme as xs:string, $stmt as xs:string, $ref as xs:string ) {
	let $scheme := fn:replace(fn:replace(fn:lower-case($scheme),'\s+$',''),'^\s+','')
	let $zw := if(0 > fn:index-of(("viaf","ark", "arxiv", "bibcode", "dia", "ean13", "eissn", "fundref", "handle", "infouri", "isbn", "isni", "issn", "istc", "jst", "lissn", "lsid", "nihmsid", "nii", "openid", "orcid", "pii", "pmcid", "pmid", "purl", "researcherid", "sici", "upc", "uri", "url", "urn", "doi"), $scheme)) then
			fn:error(QName("", $scheme), "resource identifier scheme is not available in the datacite ontology. Please create a new identifier scheme and adjust the query!", "") else()
	let $urii := sparql:createURI(fn:concat($uri, "?identifier=", $scheme))
	let $refTriple := for $r in $ref
		where (fn:string-length($r) > 0 and fn:starts-with($r, "http"))
		construct{ $urii	dc:references	{sparql:createURI($ref)} .}
	construct {
		$uri  			r3d:{$prop}					$urii .
		$urii  			a   						datacite:ResourceIdentifier ;
						litre:hasLiteralValue		{sparql:createLiteral($stmt, "", "")} ;
						datacite:usesIdentifierScheme   datacite:{$scheme} .
		{$refTriple}  
	}	
};

declare function r3dfunc:insert-lexvo-language ( $alpha3 as xs:string, $uri as xs:string ) {
	let $lang := re3mappings:get-language ( $alpha3 )
	let $urii := sparql:createURI($lang[1])
	construct {
		$uri 	r3d:repositoryLanguage	$urii .		
		$urii 	a  					lvont:Language ;
				skos:prefLabel  	{sparql:createLiteral($lang[2], "en", "")} ;
				lvont:code-a2		{sparql:createLiteral($lang[3], "", "")} ;
				lvont:code-a3		{sparql:createLiteral($lang[4], "", "")} .
	}	
	
};

declare function r3dfunc:insert-reference-doc ( $uri as xs:string, $refDocCount as xs:integer, $prop as xs:string, $title as xs:string, $descr as xs:string, $updated as xs:string, $ref as xs:string ) {
	let $urii := sparql:createURI(fn:concat($uri, "?refdoc=", fn:string($refDocCount)))
	let $descr := for $r in $descr
		construct{ $urii	dc:description	{sparql:createLiteral($r, "en", "")} .}
	let $updated := for $r in $updated
		construct{ $urii	dc:modified		{sparql:createLiteral($r, "", "xsd:date")} .}
	let $ref := for $r in $ref
		where (fn:string-length($r) > 0 and fn:starts-with($r, "http"))
		construct{ $urii	dc:referencs	{sparql:createURI($r)} .}
	construct {
		$uri 	r3d:{$prop}	$urii .		
		$urii 	a  					r3d:ReferenceDocument ;
				dc:title  			{sparql:createLiteral($title, "en", "")} .
		{fn:distinct-values(
		(	$descr, $updated, $ref	)
		)}	
	}	
};


let $refDocCount := 0
(: get root element :)
let $repo := //r3d:re3data/r3d:repository[1]
(: create repository uri :)
let $uri := sparql:createURI(fn:concat("http://service.re3data.org/repository/", $repo/r3d:identifiers/r3d:re3data[1]/text()))
(: get title with lang-tag :)
let $title := sparql:createLiteral($repo/r3d:repositoryName/text(), re3mappings:get-alpha2(data($repo/r3d:repositoryName/@language)), "")
(: get description with lang tag :)
let $descr := sparql:createLiteral($repo/r3d:description/text(), re3mappings:get-alpha2(data($repo/r3d:description/@language)), "")
(: get remark with lang tag :)
let $remarks := sparql:createLiteral($repo/r3d:remarks/text(), "en", "")
(: get repo url :)
let $url := sparql:createURI($repo/r3d:repositoryUrl/text())
(: get missionStatementUrl :)
let $msurl := sparql:createURI($repo/r3d:missionStatementUrl/text())
(: gather repository date properties :)
let $entryDate := sparql:createLiteral($repo/r3d:entryDate/text(), "", "xsd:date")
let $lastUpdate := sparql:createLiteral($repo/r3d:lastUpdate/text(), "", "xsd:date")
let $startDate := sparql:createLiteral($repo/r3d:startDate/text(), "", "xsd:date")
let $closed := sparql:createLiteral($repo/r3d:endDate/r3d:closed/text(), "", "xsd:date")
let $offline := sparql:createLiteral($repo/r3d:endDate/r3d:offline/text(), "", "xsd:date")
(: get all additional names :)
let $additionalNames := for $name in $repo/r3d:additionalName
	construct{	$uri   dc:alternative  { sparql:createLiteral($name/text(), re3mappings:get-alpha2(data($name/@language)), "")} . }
(: create datacite identifier instances for all identifiers :)
let $repoIds := for $id in $repo/r3d:repositoryIdentifier
	return r3dfunc:insert-identifier ( $uri, "repositoryIdentifier", $id/r3d:repositoryIdentifierType/text(), $id/r3d:repositoryIdentifierValue/text(), $id/r3d:repositoryIdentifierValue/text() )
(: create datacite identifier instance for r3d:doi :)
let $doi := for $id in $repo/r3d:identifiers/r3d:doi
	return r3dfunc:insert-identifier ( $uri, "doi", "doii", $id/text(), $id/text() )
(: create datacite identifier instance for r3d:re3data :)
let $r3id := for $id in $repo/r3d:identifiers/r3d:re3data
	return r3dfunc:insert-identifier ( $uri, "uri", "uri", $id/text(), $uri )
(: obtain repo language entries, create lexvo language instances :)
let $repoLangs := for $lang in $repo/r3d:repositoryLanguage
	return r3dfunc:insert-lexvo-language($lang/text(), $uri)
(: create size ref document :)
let $refDocCount := $refDocCount +1
let $size := for $s in $repo/r3d:size
	return r3dfunc:insert-reference-doc ( $uri, $refDocCount, "size", "Size of the repository", $s/text(), data($s/@updated), "" )
(: gather keywords :)
let $keywords := for $kw in $repo/r3d:keyword
	construct{ $uri 	dc:subject 	{sparql:createLiteral($kw/text(), "", "")} . }
construct{	
	$uri 				a 								r3d:Repository ;
						dc:title						{$title} ;
						dc:description					{$descr} ;
						foaf:landingpage				$url ;
						r3d:entryDate					{$entryDate} ;
						r3d:startDate					{$startDate} ;
						r3d:lastUpdate					{$lastUpdate} ;
						r3d:closed						{$closed} ;
						r3d:offline						{$offline} ;
						r3d:missionStatementUrl			$msurl ;
						rdfs:comment					{$remarks} .
	
	{fn:distinct-values(
	(	$additionalNames, $repoIds, $doi, $r3id, $repoLangs, $size, $keywords	)
	)}				
}