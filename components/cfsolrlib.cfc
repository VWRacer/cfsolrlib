<cfscript>
	// solr defaults
	THIS.host = "localhost";
	THIS.port = 8983;
	THIS.path = "/solr";
	THIS.coreName = "collection1";
	THIS.solrURL = "http://#THIS.host#:#THIS.port##THIS.path#";
	THIS.queueSize = 100;
	THIS.threadCount = 5;
	THIS.username = "";
	THIS.password = "";
	THIS.isAccessAuthenticated = false;
	THIS.dataImportRequestHandler = "";
	
	// java defaults
	THIS.javaLoaderInstance = "";
</cfscript>


<cffunction name="init" access="public" output="false" returntype="CFSolrLib">
	<cfargument name="javaloaderInstance" required="true" hint="An instance of JavaLoader." />
	<cfargument name="host" required="true" type="string" default="localhost" hint="Solr Server host" />
	<cfargument name="username" required="false" type="string" hint="HTTP Basic Authentication Username" />
	<cfargument name="password" required="false" type="string" hint="HTTP Basic Authentication Password" />
	<cfargument name="port" required="false" type="numeric" default="8983" hint="Port Solr server is running on" />
	<cfargument name="path" required="false" type="string" default="/solr" hint="Path to solr instance" />
	<cfargument name="coreName" required="false" type="string" default="collection1" hint="Solr core name (required in Solr 5)" />
	<cfargument name="queueSize" required="false" type="numeric" default="100" hint="The buffer size before the documents are sent to the server">
	<cfargument name="threadCount" required="false" type="numeric" default="5" hint="The number of background threads used to empty the queue">
	<cfargument name="binaryEnabled" required="false" type="boolean" default="true" hint="Should we use the faster binary data transfer format?">
	<cfargument name="dataImportRequestHandler" required="false" type="string" default="/dataimport" hint="Data import request handler. Data Import Handler (DIH) only." />
	
	<cfset var BinaryRequestWriter = "" />
	
	<cfset THIS.javaLoaderInstance = ARGUMENTS.javaloaderInstance />
	<cfset THIS.host = ARGUMENTS.host />
	<cfset THIS.port = ARGUMENTS.port />
	<cfset THIS.path = ARGUMENTS.path />
	<cfset THIS.coreName = ARGUMENTS.coreName />
	<cfset THIS.solrURL = "http://#THIS.host#:#THIS.port##THIS.path#" />
	<cfset THIS.queueSize = ARGUMENTS.queueSize />
	<cfset THIS.threadCount = ARGUMENTS.threadCount />
	<cfset THIS.dataImportRequestHandler = ARGUMENTS.dataImportRequestHandler />
	
	<cfscript>
	// create an update server instance
	THIS.solrUpdateServer = THIS.javaLoaderInstance.create("org.apache.solr.client.solrj.impl.ConcurrentUpdateSolrClient").init("#THIS.solrURL#/#THIS.coreName#",THIS.queueSize,THIS.threadCount);
	
	// create a query server instance
	THIS.solrQueryServer = THIS.javaLoaderInstance.create("org.apache.solr.client.solrj.impl.HttpSolrClient").init("#THIS.solrURL#/#THIS.coreName#");
	
	if ( structKeyExists(arguments, "username") ) {
		THIS.username = arguments.username;
	}
	if ( structKeyExists(arguments, "password") ) {
		THIS.password = arguments.password;
	}
	
	if ( structKeyExists(arguments, "username") and structKeyExists(arguments, "password") ) {
		THIS.isAccessAuthenticated = true;
		// set up basic authentication
		THIS.javaLoaderInstance.create("org.apache.solr.client.solrj.impl.HttpClientUtil")
			.setBasicAuth(
				THIS.solrQueryServer.getHttpClient(),
				arguments.username,
				arguments.password
			);		
	}
	
	// enable binary
	if (ARGUMENTS.binaryEnabled) {
		BinaryRequestWriter = THIS.javaLoaderInstance.create("org.apache.solr.client.solrj.impl.BinaryRequestWriter");
		THIS.solrUpdateServer.setRequestWriter(BinaryRequestWriter.init()); // comment this out if you didn't enable binary
		THIS.solrQueryServer.setRequestWriter(BinaryRequestWriter.init()); // comment this out if you didn't enable binary
	}
	</cfscript>

	<cfreturn this/>
</cffunction>

<cffunction name="checkForCore" access="public" output="false" hint="Multicore method. Checks for existance of a Solr core by name">
	<cfargument name="coreName" type="string" required="true" hint="Solr core name" />
    
    <cfscript>
		var coreRequest = new http();
		LOCAL.coreRequest.setMethod("get");
		LOCAL.coreRequest.setURL("#THIS.solrURL#/#THIS.coreName#/admin/ping");
		var pingResponse = LOCAL.coreRequest.send().getPrefix().statusCode;
		var coreCheckResponse = structNew();
		if (LOCAL.pingResponse eq "200 OK"){
			LOCAL.coreCheckResponse.success = true;
			LOCAL.coreCheckResponse.statusCode = LOCAL.pingResponse;
			return LOCAL.coreCheckResponse;
		}else{
			LOCAL.coreCheckResponse.success = false;
			LOCAL.coreCheckResponse.statusCode = LOCAL.pingResponse;
			return LOCAL.coreCheckResponse;
		}
	</cfscript>
</cffunction>

<cffunction name="createNewCore" access="public" output="false" hint="Multicore method. Creates new Solr core" returntype="struct">
	<cfargument name="coreName" type="string" required="true" hint="New Solr core name" />
    <cfargument name="instanceDir" type="string" required="true" hint="Location of folder containing config and schema files" />
    <cfargument name="dataDir" type="string" required="true" hint="Required as of Solr 4.6. Location to store core's index data" />
    <cfargument name="configName" type="string" required="false" hint="Name of config file" />
    <cfargument name="schemaName" type="string" required="false" hint="Name of schema file" />
    
    <cfscript>
		var URLString = "#THIS.host#:#THIS.port#/solr/admin/cores?action=CREATE&name=#ARGUMENTS.coreName#&instanceDir=#ARGUMENTS.instanceDir#&dataDir=#ARGUMENTS.dataDir#";
		if (structKeyExists(ARGUMENTS, "configName")){
			LOCAL.URLString = "#LOCAL.URLString#&config=#ARGUMENTS.configName#";
		}
		if (structKeyExists(ARGUMENTS, "schemaName")){
			LOCAL.URLString = "#LOCAL.URLString#&schema=#ARGUMENTS.schemaName#";
		}
		var newCoreRequest = new http();
		LOCAL.newCoreRequest.setMethod("get");
		LOCAL.newCoreRequest.setURL("#URLString#");
		var response = LOCAL.newCoreRequest.send().getPrefix();
		var coreCreationResponse = structNew();
		if (LOCAL.response.statusCode eq "200 OK"){
			LOCAL.coreCreationResponse.success = true;
			return LOCAL.coreCreationResponse;
		}else{
			LOCAL.coreCreationResponse.success = false;
			LOCAL.coreCreationResponse.message = LOCAL.response.ErrorDetail;
			return LOCAL.coreCreationResponse;
		}
	</cfscript>
</cffunction>

<cffunction name="search" access="public" output="false" hint="Search for documents in the Solr index">
	<cfargument name="q" type="string" required="true" hint="Your query string" />
	<cfargument name="start" type="numeric" required="false" default="0" hint="Offset for results, starting with 0" />
	<cfargument name="rows" type="numeric" required="false" default="20" hint="Number of rows you want returned" />
    <cfargument name="highlightingField" type="string" required="false" hint="Name of the field used for the highlighting result" />
	<cfargument name="params" type="struct" required="false" default="#structNew()#" hint="A struct of data to add as params. The struct key will be used as the param name, and the value as the param's value. If you need to pass in multiple values, make the value an array of values." />
	<cfargument name="facetFields" type="array" required="false" default="#arrayNew(1)#" hint="An array of fields to facet." />
	<cfargument name="facetMinCount" type="numeric" required="false" default="1" hint="Minimum number of results to return a facet." />
	<cfargument name="facetFilters" type="array" required="false" default="#arrayNew(1)#" hint="An array of facet filters." />
	<cfset var thisQuery = THIS.javaLoaderInstance.create("org.apache.solr.client.solrj.SolrQuery").init(ARGUMENTS.q).setStart(ARGUMENTS.start).setRows(ARGUMENTS.rows) />
	<cfset var thisParam = "" />
	<cfset var response = "" />
	<cfset var ret = structNew() />
	<cfset var thisKey = "" />
	<cfset var tempArray = [] />
	<cfset var suggestions = "" />
	<cfset var thisSuggestion = "" />
	<cfset var iSuggestion = "" />
	<cfset var currentResult = {} />

	<cfif NOT arrayIsEmpty(ARGUMENTS.facetFields)>
		<cfset LOCAL.thisQuery.setFacet(true)>
		<cfset LOCAL.thisQuery.addFacetField(javaCast("string[]",ARGUMENTS.facetFields))>
		<cfset LOCAL.thisQuery.setFacetMinCount(ARGUMENTS.facetMinCount)>
	</cfif>

	<cfif NOT arrayIsEmpty(ARGUMENTS.facetFilters)>
		<cfset LOCAL.thisQuery.addFilterQuery(javaCast("string[]",ARGUMENTS.facetFilters))>
	</cfif>
	
	<cfif structKeyExists(arguments.params, "group") and arguments.params.group is true >
	<!--- Grouped query results are in a completely different format from standard
		queries; however, adding the following params produces a standard format.
		* https://wiki.apache.org/solr/FieldCollapsing
		* http://lucene.472066.n3.nabble.com/SolrQuery-API-for-adding-group-filter-tp2921539p2923180.html
	 --->
		<cfset arguments.params["group.format"] = "simple" />
		<cfset arguments.params["group.main"] = true />
	</cfif>
	
	<cfloop list="#structKeyList(ARGUMENTS.params)#" index="thisKey">
		<cfif isArray(ARGUMENTS.params[thisKey])>
			<cfset LOCAL.thisQuery.setParam(thisKey,javaCast("string[]",ARGUMENTS.params[thisKey])) />
		<cfelseif isBoolean(ARGUMENTS.params[thisKey]) AND NOT isNumeric(ARGUMENTS.params[thisKey])>
			<cfset LOCAL.thisQuery.setParam(thisKey,ARGUMENTS.params[thisKey]) />
		<cfelse>
			<cfset var tempArray = arrayNew(1) />
			<cfset arrayAppend(LOCAL.tempArray,ARGUMENTS.params[thisKey]) />
			<cfset LOCAL.thisQuery.setParam(thisKey,javaCast("string[]",LOCAL.tempArray)) />
		</cfif>
	</cfloop>
	
	<!--- we do this instead of making the user call java functions, to work around a CF bug --->
	<cfset var response = THIS.solrQueryServer.query(LOCAL.thisQuery) />
	<cfset var ret = structNew() />
    <cfset LOCAL.ret.results = LOCAL.response.getResults() / >
	<cfset LOCAL.ret.totalResults = LOCAL.response.getResults().getNumFound() / >
    <cfset LOCAL.ret.qTime = LOCAL.response.getQTime() />
	
	<!--- Spellchecker Response --->
	<cfif NOT isNull(LOCAL.response.getSpellCheckResponse())>
		<cfset var suggestions = LOCAL.response.getSpellCheckResponse().getSuggestions() />
		<cfset LOCAL.ret.collatedSuggestion = LOCAL.response.getSpellCheckResponse().getCollatedResult() />
		<cfset LOCAL.ret.spellCheck = arrayNew(1) />
		<cfloop array="#LOCAL.suggestions#" index="iSuggestion">
			<cfset var thisSuggestion = structNew() />
			<cfset LOCAL.thisSuggestion.token = iSuggestion.getToken() />
			<cfset LOCAL.thisSuggestion.startOffset = iSuggestion.getStartOffset() />
			<cfset LOCAL.thisSuggestion.endOffset = iSuggestion.getEndOffset() />
			<cfset LOCAL.thisSuggestion.suggestions = arrayNew(1) />
			<cfloop array="#iSuggestion.getSuggestions()#" index="iSuggestion">
				<cfset arrayAppend(LOCAL.thisSuggestion.suggestions,iSuggestion) />
			</cfloop>
			<cfset arrayAppend(LOCAL.ret.spellCheck,LOCAL.thisSuggestion) />
		</cfloop>
	</cfif>
    
	<!--- Highlighting Response --->
	<cfif NOT isNull(LOCAL.response.getHighlighting()) AND structKeyExists(ARGUMENTS,"highlightingField")>
    	<cfloop array="#LOCAL.ret.results#" index="currentResult">
        	<cfset currentResult.highlightingResult = LOCAL.response.getHighlighting().get("#currentResult.get('id')#").get("#ARGUMENTS.highlightingField#") />
        </cfloop>
    </cfif>

    <!--- Faceting Response --->
    <cfif NOT isNull(LOCAL.response.getFacetFields())>
		<cfset LOCAL.ret.facetFields = arrayNew(1)>
		<cfset LOCAL.ret.facetFields = LOCAL.response.getFacetFields()>
	</cfif>
    <cfreturn duplicate(LOCAL.ret) /> <!--- duplicate clears out the case-sensitive structure --->
</cffunction>

<cffunction name="getAutoSuggestResults" access="remote" returntype="any" output="false" hint="Gets suggester results for provided search term.">
    <cfargument name="term" type="string" required="no">
        <cfif Len(trim(ARGUMENTS.term)) gt 0>
        	<!--- Remove any leading spaces in the search term --->
			<cfset ARGUMENTS.term = "#trim(ARGUMENTS.term)#">
			<cfscript>
                var suggestionRequest = new http();
                LOCAL.suggestionRequest.setMethod("get");
                LOCAL.suggestionRequest.setURL("#THIS.solrURL#/#THIS.coreName#/suggest?q=#ARGUMENTS.term#");
                var suggestResponse = LOCAL.suggestionRequest.send().getPrefix().Filecontent;
                if (isXML(LOCAL.suggestResponse)){
					var XMLResponse = XMLParse(LOCAL.suggestResponse);
					var wordList = "";
					if (ArrayLen(LOCAL.XMLResponse.response.lst) gt 1 AND structKeyExists(LOCAL.XMLResponse.response.lst[2].lst, "lst")){
						var wordCount = ArrayLen(LOCAL.XMLResponse.response.lst[2].lst.lst);
						For (j=1;j LTE LOCAL.wordCount; j=j+1){
							if(j eq LOCAL.wordCount){
								var resultCount = XMLResponse.response.lst[2].lst.lst[j].int[1].XmlText;
								var resultList = arrayNew(1);
								For (i=1;i LTE LOCAL.resultCount; i=i+1){
									arrayAppend(LOCAL.resultList, LOCAL.wordList & LOCAL.XMLResponse.response.lst[2].lst.lst[j].arr.str[i].XmlText);
								}
							}else{
								LOCAL.wordList = LOCAL.wordList & LOCAL.XMLResponse.response.lst[2].lst.lst[j].XMLAttributes.name & " ";
							}
						}
						//sort results aphabetically
						if (ArrayLen(LOCAL.resultList)){
							ArraySort(LOCAL.resultList,"textnocase","asc");
						}
					}else{
						LOCAL.resultList = "";
					}
                }else{
                    LOCAL.resultList = "";
                }
            </cfscript>
        <cfelse>
        	<cfset LOCAL.resultList = "">
        </cfif>
        <cfreturn LOCAL.resultList />
</cffunction>

<cffunction name="queryParam" access="public" output="false" returnType="array" hint="Creates a name/value pair and appends it to the array. This is a helper method for adding to your index.">
	<cfargument name="paramArray" required="true" type="array" hint="An array to add your document field to." />
	<cfargument name="name" required="true" type="string" hint="Name of your field." />
	<cfargument name="value" required="true" type="any" hint="Value of your field." />
	
	<cfset var thisField = structNew() />
	<cfset LOCAL.thisField.name = ARGUMENTS.name />
	<cfset LOCAL.thisField.value = ARGUMENTS.value />
	
	<cfset arrayAppend(ARGUMENTS.paramArray,LOCAL.thisField) />
	
	<cfreturn ARGUMENTS.paramArray />
</cffunction>

<cffunction name="add" access="public" output="false" hint="Add a document to the Solr index">
	<cfargument name="doc" type="array" required="true" hint="An array of field objects, with name, value, and an optional boost attribute. {name:""Some Name"",value:""Some Value""[,boost:5]}" />
	<cfargument name="docBoost" type="numeric" required="false" hint="Value of boost for this document." />
	
	<cfset var thisDoc = THIS.javaLoaderInstance.create("org.apache.solr.common.SolrInputDocument").init() />
	<cfset var thisParam = "" />
	<cfif isDefined("ARGUMENTS.docBoost")>
		<cfset LOCAL.thisDoc.setDocumentBoost(ARGUMENTS.docBoost) />
	</cfif>
	
	<cfloop array="#ARGUMENTS.doc#" index="thisParam">
		<cfif isDefined("thisParam.boost")>
			<cfset LOCAL.thisDoc.addField(thisParam.name,thisParam.value,thisParam.boost) />
		<cfelse>
			<cfset LOCAL.thisDoc.addField(thisParam.name,thisParam.value) />
		</cfif>
	</cfloop>
	
	<cfreturn THIS.solrUpdateServer.add(LOCAL.thisDoc) />
</cffunction>

<cffunction name="addField" access="public" output="false" returnType="array" hint="Creates a field object and appends it to the array. This is a helper method for adding to your index.">
	<cfargument name="documentArray" required="true" type="array" hint="An array to add your document field to." />
	<cfargument name="name" required="true" type="string" hint="Name of your field." />
	<cfargument name="value" required="true" hint="Value of your field." />
	<cfargument name="boost" required="false" type="numeric" hint="An array to add your document field to." />
	
	<cfset var thisField = structNew() />
	<cfset LOCAL.thisField.name = ARGUMENTS.name />
	<cfset LOCAL.thisField.value = ARGUMENTS.value />
	<cfif isDefined("ARGUMENTS.boost")>
		<cfset LOCAL.thisField.boost = ARGUMENTS.boost />
	</cfif>
	
	<cfset arrayAppend(ARGUMENTS.documentArray,LOCAL.thisField) />
	
	<cfreturn ARGUMENTS.documentArray />
</cffunction>

<cffunction name="addFile" access="public" output="false" hint="Creates a field object for appending to an array. This is a helper method for adding to your index.">
	<cfargument name="id" required="true" hint="The unique ID of the document" />
	<cfargument name="file" required="true" type="string" hint="path to the document to be added" />
	<cfargument name="fmap" required="false" type="struct" hint="The mappings of document metadata fields to index fields." />
	<cfargument name="saveMetadata" required="false" type="boolean" default="true" hint="Store non-mapped metadata in dynamic fields" />
	<cfargument name="metadataPrefix" required="false" type="string" default="attr_" hint="Metadata dynamic field prefix" />
	<cfargument name="literalData" required="false" type="struct" hint="A struct of data to add as literal fields. The struct key will be used as the field name, and the value as the field's value. NOTE: You cannot have a literal field with the same name as a metadata field.  Solr will throw an error if you attempt to override metadata with a literal field" />
	<cfargument name="boost" required="false" type="struct" hint="A struct of boost values.  The struct key will be the field name to boost, and its value is the numeric boost value" />
	<cfargument name="idFieldName" required="false" type="string" default="id" hint="The name of the unique id field in the Solr schema" />
	<cfset var docRequest = THIS.javaLoaderInstance.create("org.apache.solr.client.solrj.request.ContentStreamUpdateRequest").init("/update/extract") />
    <cfset var thisKey = "" />
	<cfset LOCAL.docRequest.addFile(createObject("java","java.io.File").init(ARGUMENTS.file),"application/octet-stream") />
	<cfset LOCAL.docRequest.setParam("literal.#arguments.idFieldName#",ARGUMENTS.id) />
	<cfif ARGUMENTS.saveMetadata>
		<cfset LOCAL.docRequest.setParam("uprefix",metadataPrefix) />
	</cfif>
	<cfif isDefined("ARGUMENTS.fmap")>
		<cfloop list="#structKeyList(ARGUMENTS.fmap)#" index="thisKey">
			<cfset LOCAL.docRequest.setParam("fmap.#thisKey#",ARGUMENTS.fmap[thisKey]) />
		</cfloop>
	</cfif>
	<cfif isDefined("ARGUMENTS.boost")>
		<cfloop list="#structKeyList(ARGUMENTS.boost)#" index="thisKey">
			<cfset LOCAL.docRequest.setParam("boost.#thisKey#",ARGUMENTS.boost[thisKey]) />
		</cfloop>
	</cfif>
	<cfif isDefined("ARGUMENTS.literalData")>
		<cfloop list="#structKeyList(ARGUMENTS.literalData)#" index="thisKey">
			<cfset LOCAL.docRequest.setParam("literal.#thisKey#",ARGUMENTS.literalData[thisKey]) />
		</cfloop>
	</cfif>
	
	<cfreturn THIS.solrUpdateServer.request(LOCAL.docRequest) />
</cffunction>

<cffunction name="deleteByID" access="public" output="false" hint="Delete a document from the index by ID">
	<cfargument name="id" type="string" required="true" hint="ID of object to delete.">
	<cfargument name="idFieldName" type="string" required="false" default="id" hint="The solr unique id field name" />
	
	<cfset THIS.solrUpdateServer.deleteByQuery(ARGUMENTS.idFieldName & ":" & ARGUMENTS.id) />
</cffunction>

<cffunction name="deleteByQuery" access="public" output="false" hint="Delete a document from the index by Query">
	<cfargument name="q" type="string" required="true" hint="Query string to delete objects with.">
	
	<cfset THIS.solrUpdateServer.deleteByQuery(ARGUMENTS.q) />
</cffunction>
<!--- addFileToSchema for use with managed schema --->
<cffunction name="addFieldToSchema" access="public" output="false" hint="Adds a new field to the schema using the REST API. Managed schema must be set up in Solr Config to use this method.">
	<cfargument name="fieldName" type="string" required="true" hint="Name of field to add to the Solr schema." />
	<cfargument name="fieldParams" type="string" required="true" hint="New field parameters in JSON format." />

	<cfscript>
		var schemaRequest = new http();
		LOCAL.schemaRequest.setMethod("put");
		LOCAL.schemaRequest.setURL("#THIS.host#:#THIS.port#/solr/schema/fields/#ARGUMENTS.fieldName#");
		LOCAL.schemaRequest.clearParams();
		LOCAL.schemaRequest.addParam(type="body",name="body",value='#ARGUMENTS.fieldParams#');
		var response = LOCAL.schemaRequest.send().getPrefix();
	</cfscript>

	<cfreturn LOCAL.response />
</cffunction>
<!--- addCopyFieldToSchema for use with managed schema --->
<cffunction name="addCopyFieldToSchema" access="public" output="false" hint="Adds copyfiled to Solr schema using REST API. Managed schema must be set up in Solr Config to use this method.">
	<cfargument name="sourceField" type="string" required="true" hint="Source field to copy from" />
	<cfargument name="destinationField" type="string" required="true" hint="Destination field to copy to" />

	<cfscript>
		var schemaRequest = new http();
		LOCAL.schemaRequest.setMethod("put");
		LOCAL.schemaRequest.setURL("#THIS.host#:#THIS.port#/solr/schema/copyfields");
		LOCAL.schemaRequest.clearParams();
		LOCAL.schemaRequest.addParam(type="body",name="body",value='[{"source":"#ARGUMENTS.sourceField#","dest":"#ARGUMENTS.destinationField#"}]');
		var response = LOCAL.schemaRequest.send().getPrefix();
	</cfscript>

	<cfreturn LOCAL.response />
</cffunction>

<cffunction name="resetIndex" access="public" output="false" hint="Clear out the index.">
	<cfset THIS.deleteByQuery("*:*") />
	<cfset THIS.commit() />
	<cfset THIS.optimize() />
</cffunction>

<cffunction name="rollback" access="public" output="false" hint="Roll back all pending changes to the index">
	<cfset THIS.solrUpdateServer.rollback() />
</cffunction>

<cffunction name="commit" access="public" output="false" hint="Commit all pending changes to the index">
	<cfset THIS.solrUpdateServer.commit() />
</cffunction>

<cffunction name="optimize" access="public" output="false" hint="Commit all pending changes to the index">
	<cfset THIS.solrUpdateServer.optimize() />
</cffunction>

<!---
	Developed against Solr 4.3
	See http://wiki.apache.org/solr/DataImportHandler#commands for argument explanations."
--->
<cffunction name="dataImport" access="public" output="false" returntype="struct" hint="Perform data import operation." >
	<cfargument name="command" type="string" default="full-import" hint="(*full-import|delta-import|status|reload-config|abort)" />
	<cfargument name="requestHandler" type="string" default="#THIS.dataImportRequestHandler#" />
	
	<!--- response output options --->
	<cfargument name="wt" type="string" default="xml" hint="(*xml|json|python|ruby|php|csv) - It's not clear what affect (if any) a non-default value might have--this isn't well documented in Solr." />
	<cfargument name="indent" type="boolean" default="false" />
	<cfargument name="verbose" type="boolean" default="false" />
	
	<!--- for command=full-import or delta-import --->
	<cfargument name="entity" type="string" />
	<cfargument name="clean" type="boolean" default="true" />
	<cfargument name="commit" type="boolean" default="true" />
	<cfargument name="optimize" type="boolean" default="false" />
	<cfargument name="debug" type="boolean" default="false" />
	
	<cfscript>
	var tempArray = arrayNew(1);
	// create a query
	var solrQuery = THIS.javaLoaderInstance.create("org.apache.solr.client.solrj.SolrQuery") ;
	solrQuery.setRequestHandler(arguments.requestHandler);
	
	if ( structKeyExists(arguments, "command") ) {
		
		tempArray[1] = arguments.command;
		solrQuery.set( "command", tempArray );
		
		if ( listFind("full-import,delta-import", arguments.command) ) {

			if ( structKeyExists(arguments, "entity") ) {
				tempArray[1] = arguments.entity;
				solrQuery.set( "entity", tempArray );
			}
			if ( structKeyExists(arguments, "clean") ) {
				solrQuery.set( "clean", javaCast("boolean", arguments.clean) );
			}
			if ( structKeyExists(arguments, "commit") ) {
				solrQuery.set( "commit", javaCast("boolean", arguments.commit) );
			}
			if ( structKeyExists(arguments, "optimize") ) {
				solrQuery.set( "optimize", javaCast("boolean", arguments.optimize) );
			}
			if ( structKeyExists(arguments, "debug") ) {
				solrQuery.set( "debug", javaCast("boolean", arguments.debug) );
			}
		
		}
	}
	
	if ( structKeyExists(arguments, "wt") ) {
		tempArray[1] = arguments.wt;
		solrQuery.set( "wt", tempArray );
	}
	if ( structKeyExists(arguments, "indent") ) {
		solrQuery.set( "indent", javaCast("boolean", arguments.indent) );
	}
	if ( structKeyExists(arguments, "verbose") ) {
		solrQuery.set( "verbose", javaCast("boolean", arguments.verbose) );
	}
	
	// this result isn't that useful, as it doesn't really get the result
	// of *this* request, since the processing doesn't complete instantaneously. 
	return parseSolrNamedListType( THIS.solrQueryServer.query(solrQuery).getResponse() );

	</cfscript>
	
</cffunction>

<!--- Developed against Solr 4.3 --->
<cffunction name="parseSolrNamedListType" access="public" output="false" returntype="struct" hint="Converts a straight Solr Named List to something that's easier to work with. This is useful for Data Import Handler responses." >
	<cfargument name="varToParse" type="any" required="true" hint="Solr response to parse." />
	<cfscript>
	var i = 0;
	var outSct = {};
	var thisValueRaw = "";
	var thisValueProcessed = "";
	
	if ( isSolrNamedListType(arguments.varToParse) ) {
		
		for (i=0; i lt arguments.varToParse.size(); i=i+1) {
			try {
				thisValueRaw = arguments.varToParse.getVal(i);
				if ( isSolrNamedListType(thisValueRaw) ) { // do we need to call this function recursively? (these lists are often nested.)
					thisValueProcessed = parseSolrNamedListType(thisValueRaw);
				} else { // just a regular object (that cf knows how to work with)
					thisValueProcessed = thisValueRaw;
				}
				// build the structure to return
				outSct[arguments.varToParse.getName(i)] = thisValueProcessed;
			} catch (any e) {
				writeLog(
					type="information",
					text="Solr response parsing failed on: " &arguments.varToParse.getName(i) &"- " &thisValueRaw.toString() &" type: " &getMetaData(thisValueRaw).getName()
				);
			}
		}
		
	}
	
	return outSct;
	</cfscript>
</cffunction>

<!--- Developed against Solr 4.3 --->
<cffunction name="isSolrNamedListType" access="public" output="false" returntype="boolean" hint="Is the passed variable an instance of org.apache.solr.common.util.NamedList?" >
	<cfargument name="varToCheck" type="any" required="true" />
	<cfscript>
	return
		isObject(arguments.varToCheck)
		and listFind (
			"org.apache.solr.common.util.SimpleOrderedMap,org.apache.solr.common.util.NamedList",
			getMetaData(arguments.varToCheck).getName()
		)
	;	
	</cfscript>
</cffunction>
