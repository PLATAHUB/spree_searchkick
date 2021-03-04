module Spree::TaxonomyDecorator
  def self.prepended(base)
    base.scope :filterable, -> { where(filterable: true) }
  end
  
  def filter_name
    "#{name.parameterize}_ids"
  end
end

::Spree::Taxonomy.prepend(Spree::TaxonomyDecorator)