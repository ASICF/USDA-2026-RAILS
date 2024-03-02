$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#plane_form.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
			plane_company_id: {
				identifier: 'plane_company_id',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
                }]
			},
			plane_name: {
				identifier: 'plane_name',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
                }]
			},
			plane_model: {
				identifier: 'plane_model',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

        form.initialize();
    }

});