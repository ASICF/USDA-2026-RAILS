$(document).on("turbolinks:load", function() {

    if ($("#ready_to_ship_dropdown.ui.dropdown").length) {
        $("#ready_to_ship_dropdown.ui.dropdown").dropdown({placeholder:'Select State'}).dropdown('clear');
    }

});