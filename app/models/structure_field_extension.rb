module StructureFieldExtension
  extend ActiveSupport::Concern

  included do
    # The items field is already configured as a PostgreSQL array column
    # No need for explicit serialization as it's handled natively
    before_save :normalize_items_field
  end

  def items=(value)
    Rails.logger.info "StructureFieldExtension#items= called with: #{value.inspect} (class: #{value.class})"
    
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

  private

  def normalize_items_field
    if items_changed?
      Rails.logger.info "Normalizing items field: #{items.inspect}"
      # Ensure items is always an array
      if items.is_a?(String) && items.present?
        array_value = items.split(',').map(&:strip).reject(&:blank?)
        write_attribute(:items, array_value)
      elsif !items.is_a?(Array)
        write_attribute(:items, [])
      end
    end
  end
end
