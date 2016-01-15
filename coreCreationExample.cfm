<cfset REQUEST.sampleSolrInstance = createObject("component","components.cfsolrlib").init(APPLICATION.javaloader,"localhost","8983","/solr") />

<cfif structKeyExists(form,"coreSubmit")>
	<cfset REQUEST.coreResponse = REQUEST.sampleSolrInstance.checkForCore("#form.coreName#")/>
    <cfif REQUEST.coreResponse.success eq false>
    	<cfset REQUEST.newCoreResponse = REQUEST.sampleSolrInstance.createNewCore("#form.coreName#","collection1","collection1")/>
    </cfif>
</cfif>

<html>
	<head>
		<title>CFSolrLib 4.0 | Core creation example</title>
	</head>
	<body>
    	<h2>Create Solr Core Example</h2>
		<p>This will check for the existance of a core and create the core if it does not exist.<br />
        </p>
		<form action="" method="POST">
			New Core Name: <input name="coreName" type="text" /><br />
            <input type="submit" name="coreSubmit" value="Create Core" /><br />
		</form>
		<p>
        <cfoutput>
        <cfif structKeyExists(REQUEST,"coreResponse")>
        	Core Exists: #REQUEST.coreResponse.success#<br />
            Status Code: #REQUEST.coreResponse.statusCode#<br />
            <cfif REQUEST.coreResponse.success eq true>
            	Core Exists. No new core created.<br />
            </cfif>
            <br />
        </cfif>
        
        <cfif structKeyExists(REQUEST,"newCoreResponse")>
        	Core Creation Attempt Success: #REQUEST.newCoreResponse.success#<br />
            <cfif REQUEST.newCoreResponse.success eq false>
            	Error Message: #REQUEST.newCoreResponse.message#<br />
            </cfif>
        	<br />
        </cfif>
        </cfoutput>
	</body>
</html>