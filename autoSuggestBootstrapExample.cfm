<!doctype html>
	<head>
		<script src="js/jquery-2.1.4.min.js"></script>
		<script src="js/bootstrap/bootstrap.min.js"></script>
		<script src="js/bootstrap/plugins/typeahead/typeahead.js"></script>
		<link rel="stylesheet" href="css/bootstrap/bootstrap.min.css" type="text/css" />
		<script type="text/javascript">
		  $(document).ready(function() {

		    $('#keyword').typeahead({
		        minLength: 1,

		        source: function(query, process) {
		              $.post('components/cfsolrlib.cfc?method=getAutoSuggestResults&returnformat=json&term=' + query, { limit: 8 }, function(data) {
		                var parJSON = JSON.parse(data);
						var suggestions = [];
						$.each(parJSON, function (i, suggestTerm) {
		                  suggestions.push(suggestTerm);
		                });
						process(suggestions);
		          });
		         }
		    });
		  });
		</script>


		<title>CFSolrLib 4.0 | Bootstrap Auto-Suggest example</title>
	</head>
	<body>
    	<h3>Auto-Suggest Using Bootstrap</h3>
    	<p>This example was built with Bootstrap 3.3.5 and the <a href="https://github.com/bassjobsen/Bootstrap-3-Typeahead">Bootstrap-3-Typeahead</a> plugin.  It is backwards compatible with 2.x versions of Bootstrap without the plugin.</p>
		Keyword: <input type="text" id="keyword" name="keyword" class="typeahead" data-provide="typeahead" autocomplete="off" />
        
    </body>
</html>