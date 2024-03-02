$(document).on("turbolinks:load", function () {
  // Find and check if the form exists
  $f = $("#upload_frame_centers.ui.form");
  if ($f.length) {
    // Initialize the Form module
    var form = new Form($f);

    // Set the validation rules for the fields
    form.validate_fields = {
      flown_by_id: {
        identifier: "flown_by_id",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
      flight_date: {
        identifier: "flight_date",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
      at: {
        identifier: "at",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
      file: {
        identifier: "file",
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
});

// Moved ADS form to FrameCenter JS file because Adblock blocks files named ads...
$(document).on("turbolinks:load", function () {
  // Find and check if the form exists
  $f = $("#upload_ads.ui.form");
  if ($f.length) {
    // Initialize the Form module
    var form = new Form($f);

    // Set the validation rules for the fields
    form.validate_fields = {
      at: {
        identifier: "at",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
      flight_date: {
        identifier: "flight_date",
        rules: [
          {
            type: "empty",
            prompt: "Cannot be blank",
          },
        ],
      },
      files: {
        identifier: "files",
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
});
