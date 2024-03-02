$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#generate_easements_to_fly.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        form.initialize();

        $("#toggle_all_state_checkboxes.ui.checkbox").checkbox({
            onChecked: function() {
                form.$el.find(".state_checkbox").checkbox('check')
            },
            onUnchecked: function() {
                form.$el.find(".state_checkbox").checkbox('uncheck')
            },
        })

    }

});