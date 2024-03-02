$(document).on("turbolinks:load", function() {

    if ($("#usda_approve_dropdown").length) {
        $("#usda_approve_dropdown").dropdown({placeholder:'Select State'}).dropdown('clear');
    }

    // Find and check if the form exists
    $f = $("#usda_approve.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        form.initialize();
    }

});