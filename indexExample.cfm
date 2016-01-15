<cfset REQUEST.sampleSolrInstance = createObject("component","components.cfsolrlib").init(APPLICATION.javaloader,"localhost","8983","/solr") />

<cfset REQUEST.sampleSolrInstance.resetIndex() />

<cfquery name="REQUEST.getArt" datasource="cfartgallery">
	SELECT artID, artname, description, firstName, lastName, isSold
	FROM art
		LEFT JOIN artists
			ON art.artistId = artists.artistId
</cfquery>

<cfscript>
	// example for indexing content from a database
	for (i=1;i LTE REQUEST.getArt.recordcount;i=i+1) {
		REQUEST.thisDoc = arrayNew(1);
		REQUEST.thisDoc = REQUEST.sampleSolrInstance.addField(REQUEST.thisDoc,"id",REQUEST.getArt.artID[i]);
		REQUEST.thisDoc = REQUEST.sampleSolrInstance.addField(REQUEST.thisDoc,"title",REQUEST.getArt.artname[i]);
		REQUEST.thisDoc = REQUEST.sampleSolrInstance.addField(REQUEST.thisDoc,"cat",trim(REQUEST.getArt.description[i]));
		thisFullname = trim(REQUEST.getArt.firstName[i]&" "&REQUEST.getArt.lastName[i]);
		REQUEST.thisDoc = REQUEST.sampleSolrInstance.addField(REQUEST.thisDoc,"author",thisFullname);
		REQUEST.thisDoc = REQUEST.sampleSolrInstance.addField(REQUEST.thisDoc,"availability_s",iif(REQUEST.getArt.isSold[i] EQ 1,DE("Sold"),DE("Available")));
		REQUEST.sampleSolrInstance.add(REQUEST.thisDoc);
	}
	
	// example for indexing content from a rich file
	REQUEST.myFile = expandPath("NRRcreditsbyartist.pdf");
	
	// To Parse File Content with Tika on the ColdFusion Side
	REQUEST.fileObject = application.tika.parseToString(createObject("java","java.io.File").init(REQUEST.myFile));
	
	REQUEST.thisFile = arrayNew(1);
	REQUEST.thisFile = REQUEST.sampleSolrInstance.addField(REQUEST.thisFile,"text",REQUEST.fileObject);
	REQUEST.thisFile = REQUEST.sampleSolrInstance.addField(REQUEST.thisFile,"id","file-1");
	REQUEST.thisFile = REQUEST.sampleSolrInstance.addField(REQUEST.thisFile,"title","File Title");
	REQUEST.sampleSolrInstance.add(REQUEST.thisFile);
	
	// To Stream File to Solr
	REQUEST.fmap = structNew();
	REQUEST.fmap["title"] = "title";
	REQUEST.fmap["content"] = "text";
	REQUEST.sampleSolrInstance.addFile("file-2",REQUEST.myFile,REQUEST.fmap,true,"attr_");
	
	REQUEST.sampleSolrInstance.commit(); // do a final commit of our changes
	REQUEST.sampleSolrInstance.optimize(); // since we're all done, optimize the index
	
	//this section builds the autosuggest dictionary. Solr now requires the core name in the path.  It is defined in a param tag for this example.

	param REQUEST.coreName = "collection1";
	REQUEST.h = new http();
	REQUEST.h.setMethod("get");
	REQUEST.h.setURL("http://localhost:8983/solr/#REQUEST.coreName#/suggest?spellcheck.build=true");
	REQUEST.h.send();
</cfscript>

<html>
	<head>
		<title>CFSolrLib 4.0 | Indexing example</title>
	</head>
	<body>
		<h2>Indexing</h2>
		
		<p>Done. There's nothing to output, you'll want to look at the CF source.</p>
		<p><a href="index.cfm">Return Home</a></p>
	</body>
</html>
