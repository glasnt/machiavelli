
function renderWaiting(element) { 
	document.getElementById(element).innerHTML = "<i class='icon-spinner icon-spin'>"
}

function unrenderWaiting() {
	$(".icon-spinner").hide()
}

function renderError(element, error) { 
	error_alert = "<div class='alert alert-danger'>"+error+"</div>"
	document.getElementById(element).innerHTML = error_alert
}