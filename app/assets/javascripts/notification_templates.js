$(document).ready(function() {
  $('.trigger-type').each(function() {
    updateTriggerFieldsVisibility($(this));
  });

  $('.variable-mapping').each(function() {
    var nestedFields = $(this).closest('#attribute-nested-fields');
    var textField = nestedFields.find('.text-field')
    if (textField.val() && $(this).val() === ""){
      nestedFields.find('.attribute-select').remove()
      adjustWidth(nestedFields);
    }
  });

  $('.trigger-type').change(function() {
    var nestedFields = $(this).closest('#event-nested_fields');
    var triggerFields = nestedFields.find('#trigger-fields');
    triggerFields.toggle($(this).val() === 'Status');
  });

  $(document).on('click', '.custom-attribute', function(e) {
    e.preventDefault();
    var nestedFields = $(this).closest('#attribute-nested-fields');
    nestedFields.find('.attribute-select').remove();
    adjustWidth(nestedFields);
  });
})

function updateTriggerFieldsVisibility(triggerType) {
  var nestedFields = triggerType.closest('#event-nested_fields');
  var triggerFields = nestedFields.find('#trigger-fields');
  triggerFields.toggle(triggerType.val() === 'Status');
}

function adjustWidth(container) {
  var hasAttributeField = container.find('.attribute-select').length > 0;
  if (!hasAttributeField) {
    container.find('.text-attribute').removeClass('col-md-6').addClass('col-md-12');
  }
}
