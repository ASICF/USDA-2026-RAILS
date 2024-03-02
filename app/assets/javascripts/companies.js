$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#company_form.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
			plane_id: {
				identifier: 'company_name',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
                }]
			},
			company_alias: {
				identifier: 'company_alias',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

        form.initialize();
    }

});