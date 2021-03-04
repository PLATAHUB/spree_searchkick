module Spree::ProductDecorator
  def self.prepended(base)
    base.searchkick(
      callbacks: :async,
      word_start: [:name],
      locations: [:location],
      settings: { number_of_replicas: 0 },
      merge_mappings: true,
      mappings: {
        properties: {
          properties: {
            type: 'nested'
          }
        }
      }
    ) unless base.respond_to?(:searchkick_index)

    base.scope :search_import, lambda {
      includes(
        :option_types,
        :variants_including_master,
        taxons: :taxonomy,
        master: :default_price,
        product_properties: :property,
        variants: :option_values
      )
    }

    def base.autocomplete_fields
      [:name]
    end

    def base.search_fields
      [:name]
    end

    def base.autocomplete(keywords)
      if keywords
        Spree::Product.search(
          keywords,
          fields: autocomplete_fields,
          match: :word_start,
          limit: 10,
          load: false,
          misspellings: { below: 3 },
          where: search_where,
        ).map(&:name).map(&:strip).uniq
      else
        Spree::Product.search(
          "*",
          fields: autocomplete_fields,
          load: false,
          misspellings: { below: 3 },
          where: search_where,
        ).map(&:name).map(&:strip)
      end
    end

    def base.search_where
      {
        active: true,
        price: { not: nil },
      }
    end
  end

  def search_data
    all_variants = variants_including_master.pluck(:id, :sku)

    all_taxons = taxons.flat_map { |t| t.self_and_ancestors.pluck(:id, :name) }.uniq

    filterable_properties = properties.filterable.pluck(:id, :name)

    properties_values = product_properties.where(property_id: filterable_properties.map(&:first)).pluck(:property_id, :value)

    filterable_properties = filterable_properties.map do |prop|
      {
        id: prop.first,
        name: prop.last,
        value: properties_values.find { |pv| pv.first == prop.first }&.last
      }
    end

    filterable_option_types = option_types.filterable.pluck(:id, :name)
    option_value_ids = ::Spree::OptionValueVariant.where(variant_id: all_variants.map(&:first)).pluck(:option_value_id).uniq
    option_values = ::Spree::OptionValue.where(
      id: option_value_ids, 
      option_type_id: filterable_option_types.map(&:first)
    ).pluck(:option_type_id, :name)

    json = {
      id: id,
      name: name,
      slug: slug,
      description: description,
      active: available?,
      in_stock: in_stock?,
      created_at: created_at,
      updated_at: updated_at,
      price: price,
      currency: currency,
      conversions: orders.complete.count,
      taxon_ids: all_taxons.map(&:first),
      taxon_names: all_taxons.map(&:last),
      option_type_ids: filterable_option_types.map(&:first),
      option_type_names: filterable_option_types.map(&:last),
      option_value_ids: option_value_ids,
      skus: all_variants.map(&:last),
      properties: filterable_properties,
      property_ids: filterable_properties.map { |p| p[:id] },
      property_names: filterable_properties.map { |p| p[:name] },
      total_on_hand: total_on_hand
    }

    filterable_properties.each do |prop|
      json.merge!(Hash[prop[:name].parameterize, prop[:value].parameterize]) if prop[:value].present?
    end

    filterable_option_types.each do |option_type|
      values = option_values.find_all { |ov| ov.first == option_type.first }.map(&:last).uniq.compact.each(&:parameterize)

      json.merge!(Hash[option_type.last.parameterize, values]) if values.present?
    end

    taxonomies_ids = taxons.pluck(:taxonomy_id).uniq
    taxonomies = Spree::Taxonomy.where(id: taxonomies_ids).pluck(:id, :name)
    taxonomies.each do |taxonomy|
      json.merge!(Hash["#{taxonomy.last.parameterize}_ids", taxons.select { |t| t.taxonomy_id = taxonomy.first }.map(&:id)])
    end

    json.merge!(index_data)

    json
  end

  def index_data
    {}
  end
end

::Spree::Product.prepend(Spree::ProductDecorator)
