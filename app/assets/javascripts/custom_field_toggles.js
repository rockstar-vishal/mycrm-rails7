// Custom field toggle functionality
$(document).ready(function() {
  // Initialize toggles for existing fields
  initializeCustomFieldToggles();
  
  // Handle dynamically added fields (Cocoon)
  $(document).on('cocoon:after-insert', function(e, insertedItem) {
    initializeCustomFieldToggles();
  });
  
  // Handle form submission to prevent unwanted updates
  $('form').on('submit', function() {
    handleItemsFieldSubmission();
  });
});

function initializeCustomFieldToggles() {
  // Handle is_select_list checkboxes
  $('.is-select-list-checkbox').off('change').on('change', function() {
    var isChecked = $(this).is(':checked');
    var itemList = $(this).closest('.form-group').find('.item-list');
    var itemsField = $(this).closest('.form-group').find('.items-field');
    var itemsHiddenField = $(this).closest('.form-group').find('.items-hidden-field');
    
    if (isChecked) {
      itemList.show();
      itemsField.prop('disabled', false);
      itemsHiddenField.prop('disabled', true);
    } else {
      itemList.hide();
      itemsField.prop('disabled', true);
      itemsHiddenField.prop('disabled', false);
    }
  });
  
  // Handle fb_form_field checkboxes
  $('.fb-form-field-checkbox').off('change').on('change', function() {
    var isChecked = $(this).is(':checked');
    var itemList = $(this).closest('.form-group').find('.item-list');
    if (isChecked) {
      itemList.show();
    } else {
      itemList.hide();
    }
  });
}

function handleItemsFieldSubmission() {
  // For each magic field, ensure items are only submitted when is_select_list is checked
  $('.is-select-list-checkbox').each(function() {
    var isChecked = $(this).is(':checked');
    var itemsField = $(this).closest('.form-group').find('.items-field');
    var itemsHiddenField = $(this).closest('.form-group').find('.items-hidden-field');
    
    if (!isChecked) {
      // If checkbox is unchecked, disable the items field to prevent submission
      itemsField.prop('disabled', true);
      itemsHiddenField.prop('disabled', false);
    } else {
      // If checkbox is checked, enable the items field
      itemsField.prop('disabled', false);
      itemsHiddenField.prop('disabled', true);
    }
  });
}
