$(document).on("turbolinks:load", function() {

    if ($("#county_status_dropdown.ui.dropdown").length) {
        $("#county_status_dropdown.ui.dropdown").dropdown({placeholder:'Select State'}).dropdown('clear');
    }

    // Find and check if the form exists
    $f = $("#generate_cut_file.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
			ortho_processing_date: {
				identifier: 'ortho_processing_date',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

        form.initialize();

        form.$el.find(".ui.checkbox").checkbox();

        $("#toggle_all_checkbox.ui.checkbox").checkbox({
            onChecked: function() {
                form.$el.find(".county_checkbox").checkbox('check')
            },
            onUnchecked: function() {
                form.$el.find(".county_checkbox").checkbox('uncheck')
            },
        });

    }

});