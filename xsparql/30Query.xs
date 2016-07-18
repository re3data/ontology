import module namespace re3mappings = "http://www.re3data.org/xsparql/r3dmappings" at "file:///C:/Users/Chile/Documents/GitHub/ontology/xsparql/r3dmappings.xq" ; 
import module namespace functx = "http://www.functx.com" at "file:///C:/Users/Chile/Documents/GitHub/ontology/xsparql/functXquery.xq" ; 

declare namespace r3d="http://www.re3data.org/schema/3-0/";
declare namespace r3dfunc="http://www.re3data.org/functions/";
declare namespace r3parse="http://www.re3data.org/vocab/parse#";
declare namespace r3instt="http://www.re3data.org/vocab/instt#";
declare namespace r3respt="http://www.re3data.org/vocab/respt#";
declare namespace r3dfg="http://www.re3data.org/vocab/dfg#";
declare namespace lvont="http://lexvo.org/ontology#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace owl = "http://www.w3.org/2002/07/owl#";
declare namespace dc = "http://purl.org/dc/terms/";
declare namespace xsd =  "http://www.w3.org/2001/XMLSchema#";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace org="http://www.w3.org/ns/org#";
declare namespace skos="http://www.w3.org/2004/02/skos/core#";
declare namespace datacite = "http://purl.org/spar/datacite/";
declare namespace sparql="http://xsparql.deri.org/demo/xquery/sparql-functions.xquery";
declare namespace litre =  "http://www.essepuntato.it/2010/06/literalreification/";

(: create identifier :)
declare function r3dfunc:insert-identifier ( $uri as xs:string, $prop as xs:string, $scheme as xs:string, $stmt as xs:string, $ref as xs:string ) {
	let $scheme := fn:replace(fn:replace(fn:lower-case($scheme),'\s+$',''),'^\s+','')
	let $zw := if(0 > fn:index-of(("viaf","ark", "arxiv", "bibcode", "dia", "ean13", "eissn", "fundref", "handle", "infouri", "isbn", "isni", "issn", "istc", "jst", "lissn", "lsid", "nihmsid", "nii", "openid", "orcid", "pii", "pmcid", "pmid", "purl", "researcherid", "sici", "upc", "uri", "url", "urn", "doi"), $scheme)) then
			fn:error(QName("", $scheme), "resource identifier scheme is not available in the datacite ontology. Please create a new identifier scheme and adjust the query!", "") else()
	let $urii := sparql:createURI(fn:concat($uri, "#identifier=", $scheme))
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

declare function r3dfunc:provide-boolean( $value as xs:string, $uri as xs:string, $prop as xs:string ) {
	let $prop := sparql:createURI($prop)
	let $value := fn:replace(fn:replace(fn:lower-case($value),'\s+$',''),'^\s+','')
	let $bool := if($value = 'yes') then sparql:createLiteral("true", "", "xsd:boolean")
			else
				if($value = 'no') then sparql:createLiteral("false", "", "xsd:boolean")
			else ()
	let $res := for $r in $bool 
		construct { $uri $prop $r .}	
	return $res
};

declare function r3dfunc:insert-lexvo-language ( $alpha3 as xs:string, $uri as xs:string ) {
	let $lang := re3mappings:get-language ( $alpha3 )
	let $urii := sparql:createURI($lang[1])
	construct {
		$uri 	r3d:repositoryLanguage	$urii .		
		$urii 	a  					lvont:Language ;
				dc:title			{sparql:createLiteral($lang[2], "en", "")} ;
				skos:prefLabel  	{sparql:createLiteral($lang[2], "en", "")} ;
				lvont:iso639P1Code	{sparql:createLiteral($lang[3], "", "")} ;
				lvont:iso639P3PCode	{sparql:createLiteral($lang[4], "", "")} .
	}	
	
};

declare function r3dfunc:insert-lexvo-region ( $alpha3 as xs:string, $uri as xs:string ) {
	let $country := re3mappings:get-country ( $alpha3 )
	let $reg := sparql:createURI($country[1])
	construct {
		$uri 	r3d:institutionCountry 		$reg	 .
		$reg 	a  					lvont:GeographicRegion ;
				dc:title	 		{sparql:createLiteral($country[2], "en", "")} ;
				skos:prefLabel 		{sparql:createLiteral($country[2], "en", "")} ;
				lvont:code-a2		{sparql:createLiteral($country[3], "", "")} ;
				lvont:code-a3		{sparql:createLiteral($country[4], "", "")} .
	}	
};

declare function r3dfunc:insert-reference-doc ( $uri as xs:string, $refDocCount as xs:integer, $prop as xs:string, $title as xs:string, $descr as xs:string, $updated, $ref ) {
	let $urii := sparql:createURI(fn:concat($uri, "#refdoc=", fn:string($refDocCount)))
	let $prop := sparql:createURI($prop)
	let $descr := for $r in $descr
		construct{ $urii	dc:description	{sparql:createLiteral($r, "en", "")} .}
	let $updated := for $r in $updated
		construct{ $urii	dc:modified		{sparql:createLiteral($r, "", "xsd:date")} .}
	let $ref := for $r in $ref
		where (fn:string-length($r) > 0 and fn:starts-with($r, "http"))
		construct{ $urii	dc:referencs	{sparql:createURI($r)} .}
	construct {
		$uri 	$prop	$urii .		
		$urii 	a  					r3d:ReferenceDocument ;
				dc:title  			{sparql:createLiteral($title, "en", "")} .
		{fn:distinct-values(
		(	$descr, $updated, $ref	)
		)}	
	}	
};

declare function r3dfunc:insert-api ( $api as node()*, $uri as xs:string, $count as xs:integer ) {
	let $urii := sparql:createURI(fn:concat($uri, "#api=", fn:string($count)))
	let $apiType := for $z in $api/r3d:apiType construct{ $urii r3d:apiType {sparql:createURI(re3mappings:get-api-type($z/text()))} .}
	let $url := for $z in $api/r3d:apiUrl construct{ $urii r3d:apiUrl {sparql:createURI($z/text())} .}
	let $doc := for $z in $api/r3d:apiDocumentation construct{ $urii r3d:apiDocumentation {sparql:createURI($z/text())} .}
	let $wsdl := for $z in $api/r3d:wsdlDocument construct{ $urii r3d:wsdlDocument {sparql:createURI($z/text())} .}

	construct {
		$uri 	r3d:api 			$urii .	
		$urii 	a  					r3d:Api .
		{fn:distinct-values(
		(	$apiType, $wsdl, $doc, $url  )
		)}	
	}	
};

declare function r3dfunc:insert-publication-support ( $repo as node(), $uri as xs:string ) {
	let $urii := sparql:createURI(fn:concat($uri, "#publicationSupport"))
	let $ciref := for $z in $repo/r3d:citationReference construct{ $urii r3d:citationReference {sparql:createURI(re3mappings:get-citation-reference($z/text()))} .}
	let $pidsys := for $z in $repo/r3d:pidSystem construct{ $urii r3d:pidSystem {sparql:createURI(re3mappings:get-pid-system($z/text()))} .}
	let $aidsys := for $z in $repo/r3d:aidSystem construct{ $urii r3d:aidSystem {sparql:createURI(re3mappings:get-aid-system($z/text()))} .}
	let $guidurl := for $z in $repo/r3d:citationGuidelineUrl construct{ $urii r3d:citationGuidelineUrl {sparql:createURI($z/text())} .}
	let $enpub := if($repo/r3d:enhancedPublication) then r3dfunc:provide-boolean( $repo/r3d:enhancedPublication/text(), $urii, "r3d:enhancedPublication" ) else ()

	construct {
		$uri 	r3d:publicationSupport 			$urii .	
		$urii 	a  					r3d:PublicationSupport .
		{fn:distinct-values(
		(	$ciref, $pidsys, $aidsys, $guidurl, $enpub  )
		)}	
	}	
};

declare function r3dfunc:insert-regulation ( $regu as node()*, $uri as xs:string, $prop as xs:string, $count as xs:integer ) {
	let $urii := sparql:createURI(fn:concat($uri, "#regulation=", fn:string($count)))
	let $prop := sparql:createURI($prop)
	let $type := if( $regu/r3d:policyType) then sparql:createURI("r3d:Policy")
			else 
				if( $regu/r3d:databaseAccessType or $regu/r3d:dataAccessType or $regu/r3d:dataUploadType ) then sparql:createURI("r3d:Access")
			else	sparql:createURI("r3d:License")
	let $policyType := for $z in $regu/r3d:policyType construct{ $urii r3d:policyType {sparql:createURI(re3mappings:get-policy-type($z/text()))} .}
	let $accessType := for $z in $regu/* where (fn:contains(fn:name($z), "AccessType")) construct{ $urii r3d:accessType {sparql:createURI(re3mappings:get-access-type($z/text()))} .}
	let $accessRes := for $z in $regu/* where (fn:contains(fn:name($z), "AccessRestriction")) construct{ $urii r3d:accessRestriction {sparql:createURI(re3mappings:get-access-restriction($z/text()))} .}
	let $name := for $z in $regu/* where (fn:contains(fn:name($z), "Name")) construct{ $urii dc:title {sparql:createLiteral($z/text(), "", "")} .}
	let $url := for $z in $regu/* where (fn:contains(fn:name($z), "Url")) construct{ $urii dc:references {sparql:createURI($z/text())} .}

	construct {
		
		$uri 	$prop  				$urii .	
		$urii 	a  					$type .
		{fn:distinct-values(
		(	$policyType, $accessType, $accessRes, $name, $url  )
		)}	
	}	
};

declare function r3dfunc:insert-agent ( $infos as node()*, $prop as xs:string, $uri as xs:string, $count as xs:integer ) {
	let $mailRegex := "[-a-z0-9~!$%^&amp;*_=+\}\{\\'\?]+(\.[-a-z0-9~!$%^&amp;*_=+\}\{\\'\?]+)*@([a-z0-9_][-a-z0-9_]*(\.[-a-z0-9_]+)*\.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(:[0-9]{1,5})?"
	let $urlRegex := "https?://(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}([-a-zA-Z0-9@:%_\+.~#?&amp;//=]*)"
	let $urii := sparql:createURI(fn:concat($uri, "#agent=", fn:string($count)))
	let $post := sparql:createURI(fn:concat($uri, "#post=", fn:string($count)))
	let $prop := sparql:createURI($prop)
	let $mail := for $r in $infos
		where (fn:matches($r/text(), fn:concat("^.*", $mailRegex, ".*$"),'i'))
		construct{ $urii	foaf:mbox 	{functx:get-matches($r/text(), $mailRegex)[1]} . }
	let $url := for $r in $infos
		where (fn:matches($r/text(), fn:concat("^.*", $urlRegex, ".*$"),'i'))
		construct{ $urii	foaf:homepage 	{functx:get-matches($r/text(), $urlRegex)[1]} . }

	let $source := for $r in $infos
		return $r/text()

	construct{

		$uri 	$prop	$post	.
		$post	{"org"}:{"heldBy"}	$urii	.
		$post	{"org"}:{"role"}	r3d:ContactRole	.
		$urii	a 		foaf:Agent ;
				dc:source	{fn:string-join($source, "; ")} .

		{fn:distinct-values(($mail, $url))}
	}
};

declare function r3dfunc:insert-responsibility ( $institution as node(), $instUri as xs:string ) {
	let $urii := sparql:createURI(fn:concat($instUri, "#responsibility"))
	let $respTypes := for $r in $institution/r3d:responsibilityType
		construct{ $urii r3d:responsibilityType {re3mappings:get-responsibility-type($r/text())} .  }
	let $start := for $r in $institution/r3d:responsibilityStartDate
		construct{ $urii r3d:responsibilityStartDate {sparql:createLiteral($r/text(), "", "xsd:date")} .  }
	let $end := for $r in $institution/r3d:responsibilityEndDate
		construct{ $urii r3d:responsibilityEndDate {sparql:createLiteral($r/text(), "", "xsd:date")} .  }
	construct{
		$instUri 	r3d:responsibility	$urii .
		$urii 		a 	r3d:Responsibility .
					
		{fn:distinct-values(($respTypes, $start, $end))}
	}
};

declare function r3dfunc:insert-institution ( $institution as node(), $uri as xs:string ) {

	(:  TODO: no Institution identifier! have to come up with a way to uniquely identify... :)
	let $urii := sparql:createURI(fn:concat("http://service.re3data.org/institution/", fn:encode-for-uri($institution/r3d:institutionName/text())))
	let $name := sparql:createLiteral($institution/r3d:institutionName/text(), re3mappings:get-iso639P1(data($institution/r3d:institutionName/@language)), "")
	(: get all additional names :)
	let $additionalInstNames := for $name in $institution/r3d:institutionAdditionalName
		construct{	$urii   dc:alternative  { sparql:createLiteral($name/text(), re3mappings:get-iso639P1(data($name/@language)), "")} . }
	let $country := r3dfunc:insert-lexvo-region ($institution/r3d:institutionCountry/text(), $uri)
	let $urls := for $u in $institution/r3d:institutionUrl
		construct{ $urii foaf:homepage	{sparql:createURI($u/text())} . }
	let $instType := for $t in $institution/r3d:institutionType
		construct{ $urii r3d:institutionType	{re3mappings:get-institution-type($t/text())} . }
	let $resp := r3dfunc:insert-responsibility($institution, $urii)
	(: create datacite identifier instances for all identifiers :)
	let $instIds := for $id in $institution/r3d:institutionIdentifier
		return r3dfunc:insert-identifier ( $urii, "institutionIdentifier", $id/r3d:institutionIdentifierType/text(), $id/r3d:institutionIdentifierValue/text(), $id/r3d:institutionIdentifierValue/text() )
	(: get the agent, TODO: solve the agent nameing (see last parameter...) :)
	let $contact := r3dfunc:insert-agent ( $institution/r3d:institutionContact, "r3d:institutionContact", $urii, 2 )
	construct {
		$uri 	r3d:institution		$urii .		
		$urii	a 	r3d:Institution ;
				dc:title {$name}	.

		{fn:distinct-values(($additionalInstNames, $country, $urls,	$resp, $instType, $instIds, $contact))}
	}
};

for $repo in //r3d:re3data/r3d:repository
	let $repp := $repo/*   (: repo children as iterable :)
	(: create repo uri :)
	let $uri := sparql:createURI(fn:concat("http://service.re3data.org/repository/", $repo/r3d:identifiers/r3d:re3data[1]/text()))
	(: r3d:repositoryName with lang-tag :)
	let $title := sparql:createLiteral($repo/r3d:repositoryName/text(), re3mappings:get-iso639P1(data($repo/r3d:repositoryName/@language)), "") 
	(: r3d:description with lang tag :)
	let $descr := for $p in $repo/r3d:description construct{ $uri dc:description {sparql:createLiteral($p/text(), re3mappings:get-iso639P1(data($p/@language)), "")} .}
	(: r3d:remarks :)
	let $remarks := for $p in $repo/r3d:remarks construct{ $uri rdfs:comment {sparql:createLiteral($p/text(), "en", "")} . }
	(: r3d:repositoryUrl :)
	let $url :=  for $p in $repo/r3d:repositoryUrl construct{ $uri foaf:landingpage {sparql:createURI($p/text())} .}
	(: r3d:missionStatementUrl :)
	let $msurl := for $z in $repo/r3d:missionStatementUrl construct{ $uri r3d:missionStatementUrl {sparql:createURI($z/text())} .}
	(: gather repository date properties :)
	let $entryDate := for $z in $repo/r3d:entryDate construct{$uri r3d:entryDate {sparql:createLiteral($z/text(), "", "xsd:date")} .}
	let $lastUpdate := for $z in $repo/r3d:lastUpdate construct{$uri r3d:lastUpdate {sparql:createLiteral($z/text(), "", "xsd:date")} .}
	let $startDate := for $z in $repo/r3d:startDate construct{$uri r3d:startDate {sparql:createLiteral($z/text(), "", "xsd:date")} .}
	let $closed := for $z in $repo/r3d:endDate/r3d:closed construct{$uri r3d:closed {sparql:createLiteral($z/text(), "", "xsd:date")} .}
	let $offline := for $z in $repo/r3d:endDate/r3d:offline construct{$uri r3d:offline {sparql:createLiteral($z/text(), "", "xsd:date")} .}
	(: r3d:additionalName :)
	let $additionalNames := for $name in $repo/r3d:additionalName construct{	$uri   dc:alternative  { sparql:createLiteral($name/text(), re3mappings:get-iso639P1(data($name/@language)), "")} . }
	(: r3d:repositoryIdentifier : create datacite identifier instances for all identifiers :)
	let $repoIds := for $id in $repo/r3d:repositoryIdentifier
		return r3dfunc:insert-identifier ( $uri, "repositoryIdentifier", $id/r3d:repositoryIdentifierType/text(), $id/r3d:repositoryIdentifierValue/text(), $id/r3d:repositoryIdentifierValue/text() )
	(: r3d:doi : create datacite identifier instance :)
	let $doi := for $id in $repo/r3d:identifiers/r3d:doi return r3dfunc:insert-identifier ( $uri, "doi", "doi", $id/text(), $id/text() )
	(: r3d:re3data : create datacite identifier instance :)
	let $r3id := for $id in $repo/r3d:identifiers/r3d:re3data return r3dfunc:insert-identifier ( $uri, "uri", "uri", $id/text(), $uri )
	(: r3d:repositoryLanguage : create lexvo language instances :)
	let $repoLangs := for $lang in $repo/r3d:repositoryLanguage	return r3dfunc:insert-lexvo-language($lang/text(), $uri)
	(: r3d:syndication, r3d:metadataStandard, r3d:certificate :)
	let $refDocs := for $pos in (1 to fn:count($repp))
		return if(fn:contains(fn:local-name($repp[$pos]), "certificate")) then
					r3dfunc:insert-reference-doc ( $uri, $pos, fn:name($repp[$pos]), $repp[$pos]/text(), "The certificate, seal or standard the repository complies with.", (), () )
			else
				if(fn:contains(fn:local-name($repp[$pos]), "metadataStandard")) then
					r3dfunc:insert-reference-doc ( $uri, $pos, fn:name($repp[$pos]), $repp[$pos]/r3d:metadataStandardName/text(), "The metadata standard the repository complies with.", (), $repp[$pos]/r3d:metadataStandardUrl/text() )
			else
				if(fn:contains(fn:local-name($repp[$pos]), "syndication")) then
					r3dfunc:insert-reference-doc ( $uri, $pos, fn:name($repp[$pos]), $repp[$pos]/r3d:syndicationType/text(), "The alerting service the repository offers", (), $repp[$pos]/r3d:syndicationUrl/text() )
			else ()
	(: r3d:keyword :)
	let $keywords := for $kw in $repo/r3d:keyword
		construct{ $uri 	dc:subject 	{sparql:createLiteral($kw/text(), "", "")} . }
	(: r3d:contentType TODO: only parse types for now :)
	let $contentTypes := for $ct in $repo/r3d:contentType
		construct{$uri 	r3d:contentType		{re3mappings:get-parse-type ( $ct )}}
	(: r3d:institution :)
	let $institution := for $i in $repo/r3d:institution	return r3dfunc:insert-institution ($i, $uri)
	(: r3d:repositoryContact TODO uri definition, see last parameter... :)
	let $contact := r3dfunc:insert-agent ($repo/r3d:repositoryContact, "r3d:repositoryContact", $uri, 1 ) 
	(: r3d:subject TODO the DFG subject are constructed by a makeshift function, which has to be replaced when taxonomy is ready :)
	let $subjects := for $s in $repo/r3d:subject construct{ $uri  r3d:subject 	{sparql:createURI(re3mappings:get-dfg-subject($s/r3d:subjectName/text()))} . }
	(: gather all regulations (policies/access/licenses)... :)
	let $regulations := for $pos in (1 to fn:count($repp))
		where (fn:contains(fn:local-name($repp[$pos]), "Access") or fn:contains(fn:local-name($repp[$pos]), "License") or fn:contains(fn:local-name($repp[$pos]), "Upload") or fn:contains(fn:local-name($repp[$pos]), "policy"))
		return r3dfunc:insert-regulation ( $repp[$pos], $uri, fn:name($repp[position()=$pos]), $pos )
	(: r3d:versioning :)
	let $vers := if($repo/r3d:versioning) then r3dfunc:provide-boolean( $repo/r3d:versioning/text(), $uri, "r3d:versioning" ) else ()
	(: r3d:software :)
	let $software := for $z in $repo/r3d:software construct{ $uri r3d:software	{$z/text()} . } 
	(: r3d:api :)
	let $apis := for $ind in (1 to fn:count($repo/r3d:api)) return r3dfunc:insert-api ( $repo/r3d:api[$ind], $uri, $ind )
	(: collect properties for publication support :)
	let $pubsup := r3dfunc:insert-publication-support ( $repo, $uri )
	(: r3d:metrics :)
	let $metrics := for $p in $repo/r3d:metrics construct{ $uri r3d:metrics {$repo/r3d:metrics/text()} . }
	(: r3d:qualityManagement :)
	let $qm := for $p in $repo/r3d:qualityManagement return r3dfunc:provide-boolean( $repo/r3d:qualityManagement/text(), $uri, "r3d:qualityManagement" )
	(: r3d:providerType TODO replace with actual method to get provider type uri!:)
	let $proty := for $p in $repo/r3d:providerType construct{ $uri r3d:providerType {sparql:createURI(fn:concat("r3proty:", re3mappings:capitalize-first( $p/text() )))} .}
	construct{	
		$uri 				a 								r3d:Repository ;
							dc:title						{$title} ;
							rdfs:label						{$title} .
			
		{fn:distinct-values(
		(	$descr, $additionalNames, $msurl, $repoIds, $doi, $r3id, $repoLangs, $refDocs, $keywords, $contentTypes, $institution, $contact, $subjects, 
			$url, $regulations, $vers, $software, $apis, $pubsup, $metrics, $qm, $remarks, $entryDate, $startDate, $lastUpdate, $closed, $offline, $proty)
		)}	
	}