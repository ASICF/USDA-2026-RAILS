$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#upload_easements.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
			at: {
				identifier: 'at',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			},
			files: {
				identifier: 'files',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

        form.initialize();
    }

});