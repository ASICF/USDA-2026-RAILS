$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#execute_move_tiles_from_utm.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
			input_directory: {
				identifier: 'input_directory',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

        form.initialize();
    }

});