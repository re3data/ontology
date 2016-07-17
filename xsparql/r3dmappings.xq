module namespace re3mappings="http://www.re3data.org/xsparql/r3dmappings" ;

declare namespace r3d="http://www.re3data.org/schema/3-0/";
declare namespace lvont="http://lexvo.org/ontology#";
declare namespace xsparql="http://xsparql.deri.org/demo/xquery/sparql-functions.xquery";
declare namespace sparql="http://xsparql.deri.org/demo/xquery/sparql-functions.xquery";
declare namespace r3parse="http://www.re3data.org/vocab/parse#";
declare namespace r3instt="http://www.re3data.org/vocab/instt#";
declare namespace r3respt="http://www.re3data.org/vocab/respt#";
declare namespace r3polty="http://www.re3data.org/vocab/polty#";
declare namespace r3accty="http://www.re3data.org/vocab/accty#";
declare namespace r3accre="http://www.re3data.org/vocab/accre#";
declare namespace r3apity="http://www.re3data.org/vocab/apity#";
declare namespace r3ciref="http://www.re3data.org/vocab/ciref#";
declare namespace r3pidsys="http://www.re3data.org/vocab/pidsys#";
declare namespace r3aidsys="http://www.re3data.org/vocab/aidsys#";

(: get namespace uri of prefixed uri string :)
declare function re3mappings:resolve-prefixed-uri ( $n as xs:string )  {
    let $zw1 := fn:substring($n, 0, string-length(substring-before($n, ":"))+2)
    return if(fn:index-of(("r3d:", "r3parse:", "r3instt:", "r3respt:", "r3polty:", "r3accty:", "r3accre:", "r3apity:", "r3ciref:", "r3pidsys:", "r3aidsys:", "lvont:"), $zw1) > 0) then 
		fn:concat(fn:namespace-uri(element {fn:concat($zw1, "x")} {""}), fn:substring($n, string-length(substring-before($n, ":"))+2))
	else
		$n
};

declare function re3mappings:capitalize-first( $arg as xs:string? )  as xs:string? {

   fn:concat(fn:upper-case(fn:substring($arg,1,1)), fn:lower-case(fn:substring($arg,2)))
} ;

declare function re3mappings:get-country ( $alpha3 as xs:string )  {
	(: re3data special alpha3 strings: EEC, AAA :)
	let $alpha3 := fn:replace(fn:replace($alpha3,'\s+$',''),'^\s+','')
	let $alpha3 := if(fn:upper-case($alpha3) = "EEC") then "EUE" else fn:upper-case($alpha3)

	let $query := fn:encode-for-uri(fn:concat("
PREFIX lvont: <http://lexvo.org/ontology#>
SELECT *
FROM <http://lexvo.org/id>
WHERE{
?s a lvont:GeographicRegion.
?s rdfs:label ?label.
?s lvont:code-a2 ?a2.
?s lvont:code-a3 ?a3.
FILTER(str(?a3) = '", $alpha3, "')
FILTER(lang(?label) = 'en')
}"))
	let $url := fn:concat("http://localhost:8890/sparql?format=json&amp;query=", $query)
	let $ele := sparql:json-doc($url)//results/bindings[1]/arrayElement
	let $zw := ($ele/s/value/text(), $ele/label/value/text(), $ele/a2/value/text(), $ele/a3/value/text())
	return $zw
};

declare function re3mappings:get-language ( $alpha3 as xs:string )  {
	let $alpha3 := fn:replace(fn:replace((fn:lower-case($alpha3)),'\s+$',''),'^\s+','')
	let $query := fn:encode-for-uri(fn:concat("
PREFIX lvont: <http://lexvo.org/ontology#>
SELECT *
FROM <http://lexvo.org/id>
WHERE{
?lang a lvont:Language.
?lang skos:prefLabel ?label.
?lang lvont:iso639P3PCode ?p3.
OPTIONAL{?lang lvont:iso639P1Code ?p1.}
FILTER(str(?p3) = '", $alpha3, "')
}"))
	let $url := fn:concat("http://localhost:8890/sparql?format=json&amp;query=", $query)
	let $ele := sparql:json-doc($url)//results/bindings[1]/arrayElement
	let $zw := ($ele/lang/value/text(), $ele/label/value/text(), $ele/p1/value/text(), $ele/p3/value/text())
	return $zw
};

declare function re3mappings:get-iso639P1 ( $alpha3 as xs:string )  {
	let $alpha3 := fn:replace(fn:replace((fn:lower-case($alpha3)),'\s+$',''),'^\s+','')
	let $query := fn:encode-for-uri(fn:concat("
PREFIX lvont: <http://lexvo.org/ontology#>
SELECT ?p1
FROM <http://lexvo.org/id>
WHERE{
?lang a lvont:Language.
?lang lvont:iso639P3PCode ?p3.
?lang lvont:iso639P1Code ?p1.
FILTER(str(?p3) = '", $alpha3, "')
}"))
	let $url := fn:concat("http://localhost:8890/sparql?format=json&amp;query=", $query)
	let $ele := sparql:json-doc($url)//results/bindings[1]/arrayElement
	return $ele/p1/value/text()
};

declare function re3mappings:get-parse-type ($type as xs:string) {
	let $parse := (
		"StandardOfficeDocuments", "standard office documents",
		"NetworkbasedData", "networkbased data",
		"Databases", "databases",
		"Images", "images",
		"AudiovisualData", "audiovisual data",
		"StructuredGraphics", "structured graphics",
		"ScientificStatisticalData", "scientific and statistical data formats",
		"RawData", "raw data",
		"PlainText", "plain text",
		"StructuredText", "structured text",
		"ArchivedData", "archived data",
		"SoftwareApplications", "software applications",
		"SourceCode", "source code",
		"ConfigurationData", "configuration data",
		"OtherData", "other"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace((fn:lower-case($type)),'\s+$',''),'^\s+',''))
	return re3mappings:resolve-prefixed-uri(fn:concat("r3parse:", $parse[$ind -1]))
};

declare function re3mappings:get-responsibility-type ($type as xs:string) {
	let $parse := (
		"Funding", "funding",
		"General", "general",
		"Main", "main",
		"Sponsoring", "sponsoring",
		"Technical", "technical",
		"Commercial", "commercial",
		"NonProfit", "non-profit"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace((fn:lower-case($type)),'\s+$',''),'^\s+',''))
	let $ind := if($ind instance of xs:integer) then $ind else if(fn:count($ind) > 1) then $ind[2] else -1
	return if($ind > 1) then re3mappings:resolve-prefixed-uri(fn:concat("r3respt:", $parse[$ind -1])) else ()
};

declare function re3mappings:get-institution-type ($type as xs:string) {
	let $parse := (
		"Commercial", "commercial",
		"NonProfit", "non-profit"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace($type,'\s+$',''),'^\s+',''))
	let $ind := if($ind instance of xs:integer) then $ind else if(fn:count($ind) > 1) then $ind[2] else -1
	return if($ind > 1) then re3mappings:resolve-prefixed-uri(fn:concat("r3instt:", $parse[$ind -1])) else ()
};

declare function re3mappings:get-policy-type ($type as xs:string) {
	let $parse := (
		"AccessPolicy", "Access policy",
		"CollectionPolicy", "Collection policy",
		"DataPolicy", "Data policy",
		"MetadataPolicy", "Metadata policy",
		"PreservationPolicy", "Preservation policy",
		"SubmissionPolicy", "Submission policy",
		"TermsOfUse", "Terms of use",
		"UsagePolicy", "Usage policy",
		"QualityPolicy", "Quality policy"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace($type,'\s+$',''),'^\s+',''))
	return re3mappings:resolve-prefixed-uri(fn:concat("r3instt:", $parse[$ind -1]))
};

declare function re3mappings:get-access-type ($type as xs:string) {
	let $parse := (
		"Open", "open",
		"Embargoed", "embargoed",
		"Restricted", "restricted",
		"Closed", "closed"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace($type,'\s+$',''),'^\s+',''))
	let $ind := if($ind instance of xs:integer) then $ind else if(fn:count($ind) > 1) then $ind[2] else -1
	return if($ind > 1) then re3mappings:resolve-prefixed-uri(fn:concat("r3accty:", $parse[$ind -1])) else ()
};

declare function re3mappings:get-access-restriction ($type as xs:string) {
	let $parse := (
		"FeeRequired", "feeRequired", 
		"InstitutionalMembership", "institutional membership",
		"Registration", "registration",
		"Other", "other"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace($type,'\s+$',''),'^\s+',''))
	let $ind := if($ind instance of xs:integer) then $ind else if(fn:count($ind) > 1) then $ind[2] else -1
	return if($ind > 1) then re3mappings:resolve-prefixed-uri(fn:concat("r3accre:", $parse[$ind -1])) else ()
};

declare function re3mappings:get-api-type ($type as xs:string) {
	let $parse := (
		"Ftp", "FTP",
		"NetCdf", "NetCDF",
		"OaiPmh", "OAI-PMH",
		"OpenDap", "OpenDAP",
		"Rest", "REST",
		"Soap", "SOAP",
		"Sparql", "SPARQL",
		"Sword", "SWORD",
		"Other", "other"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace($type,'\s+$',''),'^\s+',''))
	let $ind := if($ind instance of xs:integer) then $ind else if(fn:count($ind) > 1) then $ind[2] else -1
	return if($ind > 1) then re3mappings:resolve-prefixed-uri(fn:concat("r3apity:", $parse[$ind -1])) else ()
};

declare function re3mappings:get-citation-reference ($type as xs:string) {
	let $parse := (
		"DataCitationIndex", "Data Citation Index",
		"Scopus", "SCOPUS"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace($type,'\s+$',''),'^\s+',''))
	return re3mappings:resolve-prefixed-uri(fn:concat("r3ciref:", $parse[$ind -1]))
};

declare function re3mappings:get-aid-system ($type as xs:string) {
	let $parse := (
		"ResearcherId", "ResearcherID",
		"Naco", "NACO",
		"Viaf", "VIAF",
		"Isni", "ISNI",
		"Orcid","ORCID",
		"Scopus", "Scopus",
		"CrossRef", "CrossRef",
		"Nis", "NIS",
		"Lattes", "Lattes"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace($type,'\s+$',''),'^\s+',''))
	let $ind := if($ind instance of xs:integer) then $ind else if(fn:count($ind) > 1) then $ind[2] else -1
	return if($ind > 1) then re3mappings:resolve-prefixed-uri(fn:concat("r3aidsys:", $parse[$ind -1])) else ()
};

declare function re3mappings:get-pid-system ($type as xs:string) {
	let $parse := (
		"Ark", "ARK",
		"Doi", "DOI",
		"Handle", "Handle",
		"InfoUri", "INFO URI",
		"Istc", "ISTC",
		"IssnIsbn", "ISSN/ISBN",
		"Purl", "PURL",
		"OpenUrl", "OpenURL",
		"Uri", "URI",
		"Url", "URL",
		"Urn", "URN",
		"Uuid", "UUID",
		"Clarin", "CLARIN",
		"Dans", "DANS",
		"DataCite", "DATACITE",
		"PersId", "PersID",
		"Plin", "PLIN",
		"Ridir", "RIDIR",
		"Driver", "DRIVER",
		"KnowledgeExchangeId", "KnowledgeExchangeID"
	)
	let $ind := fn:index-of($parse, fn:replace(fn:replace($type,'\s+$',''),'^\s+',''))
	let $ind := if($ind instance of xs:integer) then $ind else if(fn:count($ind) > 1) then $ind[2] else -1
	return if($ind > 1) then re3mappings:resolve-prefixed-uri(fn:concat("r3pidsys:", $parse[$ind -1])) else ()
};

(: makeshift function, replace! :)
declare function re3mappings:get-dfg-subject ($name as xs:string) {
	let $parts := fn:tokenize($name, "\s")
	let $zw := for $p in $parts
		return re3mappings:capitalize-first($p)
	return fn:concat("r3dfg:", fn:string-join($zw, ""))
};