module MagicFieldExtension
  def items=(value)
    Rails.logger.info "MagicFieldExtension#items= called with: #{value.inspect} (class: #{value.class})"
    
    if value.is_a?(String) && value.present?
      # Split by comma and strip whitespace from each item
      array_value = value.split(',').map(&:strip).reject(&:blank?)
      Rails.logger.info "Converting string to array: #{value} -> #{array_value.inspect}"
      write_attribute(:items, array_value)
    elsif value.is_a?(Array)
      Rails.logger.info "Setting array directly: #{value.inspect}"
      write_attribute(:items, value)
    else
      Rails.logger.info "Setting empty array"
      write_attribute(:items, [])
    end
  end

  def items
    # Ensure we always return an array
    value = read_attribute(:items)
    value.is_a?(Array) ? value : []
  end
end