<cfset THIS.name = "cfsolrlibDemo" />

<cffunction name="onApplicationStart">
	<cfscript>
		// load libraries needed for solrj
		var paths = arrayNew(1);
		arrayAppend(paths,expandPath("solrj-lib/solr-solrj-6.0.0.jar"));
		arrayAppend(paths,expandPath("solrj-lib/noggit-0.7.jar"));
		arrayAppend(paths,expandPath("solrj-lib/tika-app-1.2.jar"));
		arrayAppend(paths,expandPath("solrj-lib/httpcore-4.4.4.jar"));
		arrayAppend(paths,expandPath("solrj-lib/httpclient-4.5.2.jar"));
		arrayAppend(paths,expandPath("solrj-lib/httpmime-4.5.2.jar"));

		// create an application instance of JavaLoader
		APPLICATION.javaloader = createObject("component", "javaloader.JavaLoader").init(loadpaths=paths,  loadColdFusionClassPath=true);
		// setup tika
		APPLICATION.tika = APPLICATION.javaloader.create("org.apache.tika.Tika").init();

	</cfscript>
</cffunction>

<cffunction name="onRequestStart">
	<cfif structKeyExists(url, "reinit")>
    	<cfset onApplicationStart()>
    </cfif>
</cffunction>
