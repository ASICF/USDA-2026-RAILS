// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require rails-ujs
//= require turbolinks
//= require semantic-ui
//= require semantic-ui-calendar/dist/calendar.min
//= require moment/min/moment.min
//= require jquery-tablesort/jquery.tablesort.min
//= require chart.js/dist/Chart.min
//= require_tree ./modules
//= require_tree .

$(document).on("turbolinks:load", function() {

    $('.site-header .ui.dropdown').dropdown();

	$('.ui.accordion').accordion();
	
	if ($(".ui.sortable.table").length) {
		$(".ui.sortable.table").tablesort()
	}
	
	if ( $(".ui.message.success.animate").length ) {
		$(".ui.message.success.animate").transition('pulse')
	}

	if ( $(".ui.message.error.animate").length ) {
		$(".ui.message.error.animate").transition('shake')
	}

	if ($(".settings-dropdown").length) {
		$(".settings-dropdown").dropdown({action: 'select'});
	}

	$('.message .close').on('click', function() {
    	$(this).closest('.message').transition('fade');
	});

	if ($("#confirm-dialog").length){
		$.rails.allowAction = function(link) {
		  	if (!link.attr('data-confirm')) {
		    	return true;
		  	}
		  	$.rails.showConfirmDialog(link);
		  	return false;
		};
	
		$.rails.confirmed = function(link) {
		  	link.removeAttr('data-confirm');
		  	return link.trigger('click.rails');
		};
	
		$.rails.showConfirmDialog = function(link) {
		  $("#confirm-dialog").modal('show');
		  $("#confirm-dialog").on('click', '.confirm', function() {
		  	$.rails.confirmed(link);  
		  });
		};
	}

	$(".print_btn").click(function() {
		window.print();
	});

});

function trip(url, type, data, callback) {
	$.ajax({
		url: url,
		type: type,
		data: data,
		success: callback
	});
}

function bytesToSize(bytes) {
	var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
	if (bytes == 0) return '0 Byte';
	var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
	return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
 };