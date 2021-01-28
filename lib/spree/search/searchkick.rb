module Spree
  module Search
    class Searchkick < Spree::Core::Search::Base
      def retrieve_products
        @products = base_elasticsearch
      end

      def base_elasticsearch
        curr_page = page || 1
        Spree::Product.search(
          keyword_query,
          fields: Spree::Product.search_fields,
          where: where_query,
          aggs: aggregations,
          smart_aggs: true,
          order: sorted,
          page: curr_page,
          per_page: per_page
        )
      end

      def where_query
        where_query = {
          active: true,
          currency: current_currency,
          price: { not: nil },
        }
        where_query[:taxon_ids] = taxon.id if taxon
        add_search_filters(where_query)
      end

      def keyword_query
        keywords.nil? || keywords.empty? ? "*" : keywords
      end

      def sorted
        order_params = {}
        order_params[:conversions] = :desc if conversions
        order_params
      end

      def aggregations
        fs = {}

        aggregation_classes.each do |agg_class|
          agg_class.filterable.each do |record|
            fs[record.filter_name.parameterize.to_sym] = { min_doc_count: 1 }
          end
        end

        #TODO: Allow to configure these ranges or to set a dynamic range
        price_ranges = [{ to: 10000 }, { from: 20000, to: 50000 }, { from: 50000, to: 100000 }, { from: 100000, to: 200000 }, { from: 200000 }]
        fs[:price] = { ranges: price_ranges }
        
        fs
      end

      def aggregation_classes
        [
          Spree::Taxonomy, 
          Spree::Property, 
          Spree::OptionType
        ]
      end

      def add_search_filters(query)
        return query unless search
        search.each do |name, scope_attribute|
          query.merge!(Hash[name, scope_attribute])
        end
        query
      end

      def prepare(params)
        super
        @properties[:conversions] = params[:conversions]
      end
    end
  end
end
