$(document).ready( function() {
  	$("table.striped tbody tr").mouseover( function() {
   		$(this).addClass("highlight");
   		}).mouseout( function() {
   			$(this).removeClass("highlight");
   			});
   	$("table.striped tbody tr:odd").addClass("odd");
   	$("table.striped tbody tr:even").addClass("even");
   	});
