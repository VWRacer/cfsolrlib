<script src="js/jquery-2.1.4.min.js"></script>
<script src="js/jqueryui/jquery-ui.min.js"></script>
<link rel="stylesheet" href="css/jqueryui/jquery-ui.min.css" type="text/css" />
<script type="text/javascript">
$(function() {
    $("#keyword").autocomplete({
        source: "components/cfsolrlib.cfc?method=getAutoSuggestResults&returnformat=json"
    });
});
</script>

<html>
	<head>
		<title>CFSolrLib 4.0 | JQuery UI Auto-Suggest example</title>
	</head>
	<body>
    	<h3>Auto-Suggest Using JQuery UI</h3>
    	<p>This example was built with JQuery UI 1.11.4</p>
		Keyword: <input id="keyword" />
        
    </body>
</html>