$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#daily_progress_reports.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
			flight_date: {
				identifier: 'flight_date',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

        form.initialize();
    }

});