$(document).on("turbolinks:load", function () {
  // Find and check if the form exists
  if ($("#validate_final_delivery.ui.form").length) {
    // Initialize the Form module
    var form = new Form($("#validate_final_delivery.ui.form"));

    // Set the validation rules for the fields
    form.validate_fields = {
      file: {
        identifier: "file",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
      input_directory: {
        identifier: "input_directory",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
    };
    form.initialize();
  }

  // Close psn segment
  $("#close_psn_segment").click(function () {
    $("#final_deliver_psn_segment").remove();
    $("#validate_final_delivery").show();
  });

  // Find and check if the form exists
  if ($("#execute_final_delivery.ui.form").length) {
    // Initialize the Form module
    var form = new Form($("#execute_final_delivery.ui.form"));

    // Set the validation rules for the fields
    form.validate_fields = {
      ship_date: {
        identifier: "ship_date",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
      packing_slip_name: {
        identifier: "packing_slip_name",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
    };

    $("#packing_slip_name").dropdown({
      allowAdditions: true,
      hideAdditions: false,
    });

    form.initialize();

    form.$el.find(".ui.checkbox").checkbox();

    $("#toggle_all_checkbox.ui.checkbox").checkbox({
      onChecked: function () {
        form.$el.find(".county_checkbox").checkbox("check");
      },
      onUnchecked: function () {
        form.$el.find(".county_checkbox").checkbox("uncheck");
      },
    });
  }
});
