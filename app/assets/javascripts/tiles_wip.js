$(document).on("turbolinks:load", function () {
    // Find and check if the form exists
    $f = $("#tiles_form.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
            state_id: {
				identifier: 'state_id',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}, 
            date_from: {
				identifier: 'date_from',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}, 
            date_to: {
				identifier: 'date_to',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

		form.initialize();

        // Pull the current year from the dropdown
        var year = $(".month-dropdown").data('year');

		$(".month-dropdown").dropdown('setting', 'onChange', function(value) {

            var selected_month;
            var month_start;
            var month_end;

            // builds the selected month and extracts the beginning and end dates for the month
            // => If "all" is selected then it will build for the entire year
            if (value == "ALL") {
                month_start = moment('January 1, '+year,'MMMM Do, YYYY').format('MMMM Do, YYYY');
                month_end = moment('December 31, '+year,'MMMM Do, YYYY').format('MMMM Do, YYYY');
            } else {
                selected_month = moment(value + "-1-" + year, "MM-DD-YYYY");
                month_start = selected_month.startOf('month').format('MMMM Do, YYYY');
                month_end = selected_month.endOf('month').format('MMMM Do, YYYY');
            }

            // Set the values to the calendar inputs
            $("#date_from").closest('.ui.calendar').calendar('set date', month_start);
            $("#date_to").closest('.ui.calendar').calendar('set date', month_end);
		});
    }
});