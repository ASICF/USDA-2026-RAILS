$(document).on("turbolinks:load", function () {
  // Find and check if the form exists
  $f = $("#tile_status_report_form.ui.form");
  if ($f.length) {
    // Initialize the Form module
    var form = new Form($f);

    // Set the validation rules for the fields
    form.validate_fields = {
      poly_id: {
        identifier: "poly_id",
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

  $input = $("#tile_status_input");

  if ($input) {
    $("#tile_status_submit_btn").click(function () {
      console.log($input.val());
      window.location.pathname = "/tile_status_render/"+$input.val()
    });
  }
});
