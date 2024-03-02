var Form = function ($form) {
	var self = this;
  
	this.debugMode = false;
	this.$el = $form;
	this.validate_fields = {};
	this.prefix = this.$el.attr("id").split("-")[0] + "_"; // Call each form by it's controller singular name and this will auto prefix any Rails elements in the form
  
	this.$el
	  .on("cocoon:after-insert", function () {
		self.initialize();
	  })
	  .on("cocoon:after-remove", function () {
		self.initialize();
	  });
  
	// Custom Form Validations
	// ---------------------------
	// Confirm that user value is greater than another number
	$.fn.form.settings.rules.greaterThan = function (
	  inputValue,
	  validationValue
	) {
	  return parseFloat(inputValue) > parseFloat(validationValue);
	};
	// Confirm that user value is greater than or equal to another number
	$.fn.form.settings.rules.greaterThanOrEqualTo = function (
	  inputValue,
	  validationValue
	) {
	  return parseFloat(inputValue) >= parseFloat(validationValue);
	};
	// Confirm that user value is greater than another number
	$.fn.form.settings.rules.lesserThan = function (inputValue, validationValue) {
	  return parseFloat(inputValue) < parseFloat(validationValue);
	};
	// Confirm that user value is less than or equal to another number
	$.fn.form.settings.rules.lesserThanOrEqualTo = function (
	  inputValue,
	  validationValue
	) {
	  return parseFloat(inputValue) <= parseFloat(validationValue);
	};
  
	this.initialize = function () {
	  //		console.log(this.validate_fields);
	  var obj = {};
  
	  if (this.$el.find(".custom_validate:not(.ignore)").length) {
		this.$el.find(".custom_validate:not(.ignore)").each(function () {
		  // console.log("****************");
		  // console.log($(this), $(this).data());
		  // console.log("****************");
  
		  // console.log($(this), $(this).data());
		  var selector = "name";
		  if ($(this).data("selector")) {
			selector = $(this).data("selector");
		  }
  
		  var identifier = null;
		  if ($(this).find("select").length) {
			identifier = $(this).find("select").attr(selector);
		  } else if ($(this).find("input").length) {
			identifier = $(this).find("input").attr(selector);
		  } else if ($(this).find("textarea").length) {
			identifier = $(this).find("textarea").attr(selector);
		  }
  
		  // console.log(identifier);
  
		  if (!identifier) {
			console.error(
			  "ERROR:  Missing Validation Identifier!",
			  $(this),
			  $(this).data()
			);
			return false;
		  }
  
		  obj[identifier] = {
			identifier: identifier,
			rules: $(this).data("validation"),
		  };
		});
	  }
  
	//   console.log("custom validate", obj);
  
	  $.extend(obj, this.validate_fields);
  
	  // console.log("Form fields to validate:", obj);
  
	  if (this.debugMode) {
		obj = {};
	  }
  
	  this.$el.form("destroy");
	  this.$el.form({
		fields: obj,
		inline: "true",
		on: "submit",
		keyboardShortcuts: false,
		// onSuccess: function(event, fields) {
		// console.log("Success", event, fields);
		// event.preventDefault();
		// return false;
		// },
		// onFailure : function(formErrors, fields) {
		// console.error("Failed", formErrors, fields);
		// event.preventDefault();
		// return false;
		// }
	  });
	  //		 console.log(this.$el.form("is valid"));
  
	  this.$el
		.find(".ui.dropdown:not(.protected)")
		.dropdown({ fullTextSearch: true });
	  this.$el.find(".ui.checkbox:not(.protected)").checkbox();
  
	  this.$el.find(".ui.calendar:not(.protected)").each(function () {
		var type = "date";
		if ($(this).data("type")) {
		  type = $(this).data("type");
		}
		$(this).calendar({
		  type: type,
		  on: "focus",
		  popupOptions: {
			hideOnScroll: true,
		  },
		});
	  });
  
	  if (this.$el.find(".add-file-btn").length > 0) {
		this.$el
		  .find(".add-file-btn")
		  .unbind()
		  .on("click", function () {
			$(this)
			  .closest(".hidden-file-container")
			  .find(".hidden-file-upload")
			  .click();
		  });
  
		this.$el
		  .find('input[type="file"]')
		  .unbind()
		  .on("change", function () {
			$el = $(this);
			$el
			  .closest(".hidden-file-container")
			  .find(".add-file-btn")
			  .html($el.val().split("\\").pop());
		  });
  
		if (this.$el.find(".remove-hidden-file").length) {
		  this.$el
			.find(".remove-hidden-file")
			.unbind()
			.on("click", function () {
			  $fileContainer = $(this).closest(".hidden-file-container");
			  $fileContainer
				.find(".add-file-btn")
				.html('<i class="plus icon"></i>Add File');
			  $file = $fileContainer.find(".hidden-file-upload");
			  $file.replaceWith($file.val("").clone(true));
			  $fileContainer.find(".hidden-file-destroy").val(1);
			  $(this).closest("form").find('input[type="submit"]').click();
			});
		}
	  }
  
	  if (this.$el.find(".ui.accordion").length > 0) {
		this.$el.find(".ui.accordion").accordion();
	  }
  
	  // Semantic UI doesn't do a great job of removing error messages or prompts on valid fields.
	  // this.clear_unnecessary_prompts();
	};
  
	this.reset = function () {
	  this.$el.form("reset");
	};
  
	this.clear_unnecessary_prompts = function () {
	  this.$el.find(".field:not(.error)").find(".ui.prompt.visible").remove();
	};
  
	this.clear = function () {
	  this.$el.form("clear");
	};
  
	this.Update_Form_From_Rails = function (error_array) {
	  var errors_found = 0;
  
	  for (var field in error_array) {
		if (error_array[field].length > 0) {
		  errors_found++;
		}
	  }
  
	  if (errors_found === 0) {
		return false;
	  }
  
	  var add_prompt = function (lbl, field, msg) {
		//			console.log(lbl, field, msg);
		self.$el.form("add prompt", lbl, toTitleCase(field) + " " + msg);
	  };
  
	  var validate_field = function ($el, type, callback) {
		var pass = true;
  
		//			console.log($el, type);
  
		if (type == "empty") {
		  if ($el.val().length == 0) {
			pass = false;
		  }
		}
  
		callback(pass);
	  };
  
	  console.log(error_array);
  
	  for (var field in error_array) {
		var lbl = self.prefix + field;
		// console.log(lbl, error_array[field]);
		if ($("#" + lbl).length) {
		  for (var i = 0; i < error_array[field].length; i++) {
			add_prompt(lbl, field, error_array[field][i]);
		  }
		} else {
		  // console.log(" ");
		  // console.log("----------------------------------------");
		  if (field.indexOf(".") !== -1) {
			// if the field has a period then check if it has an association
  
			var associations = field.split(".");
  
			var query = "";
			for (var d = 0; d < associations.length; d++) {
			  query += "[id*='" + associations[d] + "']";
			}
			var $el = $(query);
			// console.log($el.length, $el);
  
			if ($el.length) {
			  for (var e = 0; e < $el.length; e++) {
				//							console.log($el[e]);
				var type = $($el[e]).closest(".custom_validate").data("type");
				// console.log(type);
  
				for (var i = 0; i < error_array[field].length; i++) {
				  //								console.log(error_array[field][i]);
  
				  validate_field($($el[e]), type, function (pass) {
					//									console.log(pass);
					if (!pass) {
					  add_prompt(
						$($el[e]).attr("id"),
						associations[associations.length - 1],
						error_array[field][i]
					  );
					}
				  });
				}
			  }
			} else {
			  console.error("Could not find element in form: ", lbl);
			}
		  } else {
			console.error("Could not find element in form: ", lbl);
		  }
		}
	  }
	};
  };