$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#usda_rejection_form.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
			file: {
				identifier: 'file',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
                }]
			}, 
			status: {
				identifier: 'status',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
                }]
			}
        };

        form.initialize();
    }

});