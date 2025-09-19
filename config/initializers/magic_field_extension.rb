# Include MagicFieldExtension in the dynamically generated MagicField model
Rails.application.config.to_prepare do
  if defined?(MagicField)
    MagicField.include MagicFieldExtension
  end
end