// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#timeline.ui.form");

    if ($f.length) {

        // Initialize the dropdown
        $(".timeline_dropdown.ui.dropdown").dropdown();

        // Initialize the Form module
        var form = new Form($f);

        form.initialize();
    }

});