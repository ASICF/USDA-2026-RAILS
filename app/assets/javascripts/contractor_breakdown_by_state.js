$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#contractor_breakdown_by_state.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Compare date ranges
        $.fn.form.settings.rules.dateGreaterThan = function (inputValue, validationValue) {
            var date_from = moment.utc($("#date_flown_from").val());
            var date_end = moment.utc($("#date_flown_end").val());
            if ((date_end).diff(date_from) >= 0) {
                return true;
            } else {
                return false;
            }
        };

        // Set the validation rules for the fields
		form.validate_fields = {
			config_id: {
				identifier: 'config_id',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
                }]
			},
			company_id: {
				identifier: 'company_id',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
                }]
			},
			date_flown_from: {
				identifier: 'date_flown_from',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}, {
					type   : 'dateGreaterThan[1]',
					prompt : 'Invalid Date Range: From Date must be older than End Date'
                }]
			},
			date_flown_end: {
				identifier: 'date_flown_end',
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
            $("#date_flown_from").closest('.ui.calendar').calendar('set date', month_start);
            $("#date_flown_end").closest('.ui.calendar').calendar('set date', month_end);
		});
    }

}); 