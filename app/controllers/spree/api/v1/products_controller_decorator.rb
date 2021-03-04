module Spree
  module Api
    module V1
      module ProductsControllerDecorator
        include ::Spree::Core::ControllerHelpers::Search

        # Sort by conversions desc
        def index
          
          @products = if params[:ids]
            product_scope.where(id: params[:ids].split(',').flatten)
          else
            @searcher = build_searcher(params.merge(include_images: true, current_store_id: current_store.id))
            @searcher.retrieve_products
          end

          # @products = @products.distinct.page(params[:page]).per(params[:per_page])
          expires_in 15.minutes, public: true
          headers['Surrogate-Control'] = "max-age=#{15.minutes}"
          respond_with(@products)
        end
      end
    end
  end
end
  
if defined?(Spree::Api::V1::ProductsController)
  ::Spree::Api::V1::ProductsController.prepend(Spree::Api::V1::ProductsControllerDecorator)
end
