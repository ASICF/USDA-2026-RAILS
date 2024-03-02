$(document).on("turbolinks:load", function() {

    // Find and check if the form exists
    $f = $("#upload_rejections.ui.form");
    if ($f.length) {

        // Initialize the Form module
        var form = new Form($f);

        // Set the validation rules for the fields
		form.validate_fields = {
            files: {
				identifier: 'files',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}, 
            type: {
				identifier: 'type',
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
			}, 
            // flight_date: {
			// 	identifier: 'flight_date',
			// 	rules: [{
			// 		type   : 'empty',
			// 		prompt : 'Cannot be blank'
			// 	}]
			// }, 
            reject_date: {
				identifier: 'reject_date',
				rules: [{
					type   : 'empty',
					prompt : 'Cannot be blank'
				}]
			}
        };

		form.initialize();

		$('#rejection_type').dropdown({
			onChange: function(value) {
				if (value == "asi") {
					$("#rejection_status").dropdown('set selected', "reject");
					$("#rejection_status").addClass("disabled");
				} else {
					$("#rejection_status").removeClass("disabled");
					$("#rejection_status").dropdown("clear");
				}
			}
		});

		$('#rejection_status').dropdown({
			onChange: function(value) {
				if (value == "clear") {
					$("#reject_date").val("");
					$("#no_rejection_date").show();
					$(".show_rejection_date").hide();
					delete form.validate_fields.reject_date;
				} else {
					$(".show_rejection_date").show();
					$("#no_rejection_date").hide();
					form.validate_fields.reject_date = {
						identifier: 'reject_date',
						rules: [{
							type   : 'empty',
							prompt : 'Cannot be blank'
						}]
					}
				}
				form.initialize();
			}
		});
	}

});