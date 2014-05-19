<cfset REQUEST.sampleSolrInstance = createObject("component","components.cfsolrlib").init(APPLICATION.javaloader,"localhost","8983","/solr") />

<cfif structKeyExists(form,"schemaSubmit")>
    <cfif len(form.fieldName) AND len(form.fieldType)>
        <cfset REQUEST.fieldParams = '{"type":"#form.fieldType#"}'/>
	    <cfset REQUEST.schemaResponse = REQUEST.sampleSolrInstance.addFieldToSchema("#form.fieldName#",REQUEST.fieldParams)/>
        <cfset REQUEST.fieldResponseDetail = deserializeJSON(REQUEST.schemaResponse.Filecontent) />
    </cfif>
    <!---<cfif len(form.copyFieldSource) AND len(form.copyFieldDestination)>
        <cfset REQUEST.schemaResponse = REQUEST.sampleSolrInstance.addCopyFieldToSchema("#form.copyFieldSource#","#form.copyFieldDestination#")/>
        <cfset REQUEST.responseDetail = deserializeJSON(REQUEST.schemaResponse.Filecontent) />
    </cfif>--->
</cfif>

<html>
	<head>
		<title>CFSolrLib 3.0 | Schema REST API example</title>
	</head>
	<body>
    	<h2>Add New Field To Schema Example</h2>
		<p>This will add a new field to the Solr Schema using the REST API.<br />
        If the field already exists, it will return a message stating so.</p>
		<form action="" method="POST">
			New Field Name: <input name="fieldName" type="text" /><br />
            New Field Type: <input name="fieldType" type="text" /><br />
            <input type="submit" name="schemaSubmit" value="Add Field" /><br /><br>
            <!---New Copy Field Source: <input name="copyFieldSource" type="text" /><br />
            New Copy Field Destination: <input name="copyFieldDestination" type="text" /><br />
            <input type="submit" name="schemaSubmit" value="Add Copy Field" /><br />--->
		</form>
		<p>
        <cfoutput>
        <cfif structKeyExists(REQUEST, "fieldResponseDetail") > 
            <cfif REQUEST.fieldResponseDetail.responseHeader.status eq "0">
                New Field "#FORM.fieldName#" Successfully Added To Schema<br />
            <cfelse>
                New Field Not Added<br />
            	Error Message: #REQUEST.fieldResponseDetail.error.msg#<br />
            </cfif>
        </cfif>
        <!---<cfif structKeyExists(REQUEST, "copyFieldResponseDetail") > 
            <cfif REQUEST.copyFieldResponseDetail.responseHeader.status eq "0">
                New CopyField Successfully Added To Schema<br />
            <cfelse>
                New Field Not Added<br />
                Error Message: #REQUEST.copyFieldResponseDetail.error.msg#<br />
            </cfif>
        </cfif>--->
        <cfset REQUEST.currentFieldNames = new http()/>
        <cfset REQUEST.currentFieldNames.setMethod("GET")/>
        <cfset REQUEST.currentFieldNames.setURL("http://localhost:8983/solr/schema/fields")/>
        <cfset REQUEST.currentFieldNamesResponse = REQUEST.currentFieldNames.send().getPrefix()/>
        <cfset REQUEST.deserializedFieldNamesResponse = deserializeJSON(REQUEST.currentFieldNamesResponse.fileContent)/>
        <cfset REQUEST.currentCopyFields = new http()/>
        <cfset REQUEST.currentCopyFields.setMethod("GET")/>
        <cfset REQUEST.currentCopyFields.setURL("http://localhost:8983/solr/schema/copyfields")/>
        <cfset REQUEST.currentCopyFieldsResponse = REQUEST.currentCopyFields.send().getPrefix()/>
        <cfset REQUEST.deserializedCopyFieldsResponse = deserializeJSON(REQUEST.currentCopyFieldsResponse.fileContent)/>
        <table cellpadding="10">
            <tr>
                <td valign="top">
                    <center><h3>Existing Fields</h3></center>
                    <table cellpadding="5" border="1">
                        <tr>
                            <td align="center" bgcolor="gray">Field Name</td>
                            <td align="center" bgcolor="gray">Field Type</td>
                            <td align="center" bgcolor="gray">Indexed</td>
                            <td align="center" bgcolor="gray">Stored</td>
                        </tr>
                        <cfloop array="#REQUEST.deserializedFieldNamesResponse.fields#" index="currentField">
                            <tr>
                                <td>#currentField.name#</td>
                                <td>#currentField.type#</td>
                                <cfif structKeyExists(currentField,"indexed")>
                                    <td>#currentField.indexed#</td>
                                <cfelse>
                                    <td>&nbsp;</td>
                                </cfif>
                                <cfif structKeyExists(currentField,"stored")>
                                    <td>#currentField.stored#</td>
                                <cfelse>
                                    <td>&nbsp;</td>
                                </cfif>
                            </tr>
                        </cfloop>
                    </table>
                </td>
                <td valign="top">
                    <center><h3>Existing CopyFields</h3></center>
                    <table cellpadding="5" valign="top" border="1">
                        <tr>
                            <td align="center" bgcolor="gray">Field Source</td>
                            <td align="center" bgcolor="gray">Field Destination</td>
                        </tr>
                        <cfloop array="#REQUEST.deserializedCopyFieldsResponse.copyfields#" index="currentField">
                            <tr>
                                <td>#currentField.source#</td>
                                <td>#currentField.dest#</td>
                            </tr>
                        </cfloop>
                    </table>
                </td>
            </tr>
        </table>
        </cfoutput>
	</body>
</html>