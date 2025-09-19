class ProcessUpdateMagicAttributesLeadid

  @queue = :process_magic_attributes_update
  @process_magic_attributes_update_logger = Logger.new('log/process_magic_attributes_update_logger.log')

  def self.perform
    @process_magic_attributes_update_logger.info("Updating Magic Attributes Lead ID Initiated !")
    MagicAttribute.where(lead_id: nil).joins(:magic_attribute_relationships).find_each(batch_size: 1000) do |record|
      owner_id = record.magic_attribute_relationships.first&.owner_id
      if owner_id.present?
        record.update_columns(lead_id: owner_id)
        puts "Magic Attribute #{record.id} Updated Successfully!"
        @process_magic_attributes_update_logger.info("Magic Attribute #{record.id} Updated Successfully !")
      end
    end
    @process_magic_attributes_update_logger.info("Updated Magic Attributes Lead ID !")
  end
end