module SpreeSearchkick::Spree::PropertyDecorator
  def self.prepended(base)
    base.scope :filterable, -> { where(filterable: true) }
  end

  def filter_name
    name.parameterize.to_s
  end
end

::Spree::Property.prepend(SpreeSearchkick::Spree::PropertyDecorator)