$(document).on("turbolinks:load", function() {
    // Find and check if the form exists
    if ($("#generate_content_file_status.ui.form").length) {

        // Initialize the Form module
        var form = new Form($("#generate_content_file_status.ui.form"));

        // Set the validation rules for the fields
		form.validate_fields = {
			file: {
				identifier: 'file',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			},
        };

		form.initialize();

    }
});