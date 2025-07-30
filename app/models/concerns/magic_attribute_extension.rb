module MagicAttributeExtension

  extend ActiveSupport::Concern

  included do

    has_many :magic_attribute_relationships
    belongs_to :magic_field

    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mappings dynamic: false do
        indexes :value, type: :text
        indexes :magic_field_id, type: :integer
        indexes :magic_attribute_relationships, type: :nested do
          indexes :owner_id, type: :integer
        end
      end
    end

    def as_indexed_json(options = {})
      as_json(
        only: [:value, :magic_field_id],
        include: {
          magic_attribute_relationships: { only: :owner_id }
        }
      )
    end

  end

end
