$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#camera_form.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
			camera_company_id: {
				identifier: 'camera_company_id',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			},
			camera_amount: {
				identifier: 'camera_amount',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}, {
					type   : 'number',
					prompt : 'Must be a number'
				}, {
				    type: 'regExp[/^[0-9.0-9]*$/]',
				    prompt: 'Must be greater than 0',
				}]
			},
			camera_name: {
				identifier: 'camera_name',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
                }]
			},
			camera_serial_number: {
				identifier: 'camera_serial_number',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			},
			camera_manufacturer: {
				identifier: 'camera_manufacturer',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			},
			camera_model: {
				identifier: 'camera_model',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

        form.initialize();
    }

});