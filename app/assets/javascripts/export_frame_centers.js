$(document).on("turbolinks:load", function() {
    if ($("#export_frame_centers.ui.dropdown").length) {
        $("#export_frame_centers.ui.dropdown").dropdown({placeholder:'Select AT Block'}).dropdown('clear');
    }
})