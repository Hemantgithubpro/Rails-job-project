module Api
  module V1
    class ProductsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show]

      def index
        products = Product.active

        # Apply search filter
        products = products.search_by_name(params[:q]) if params[:q].present?

        # Apply price range filter
        products = products.where("price_cents >= ?", params[:min_price_cents]) if params[:min_price_cents].present?
        products = products.where("price_cents <= ?", params[:max_price_cents]) if params[:max_price_cents].present?

        # Apply stock filter
        products = products.in_stock if params[:in_stock] == "true"

        # Apply sorting
        products = case params[:sort]
                  when "price_asc"
                    products.by_price_asc
                  when "price_desc"
                    products.by_price_desc
                  when "name"
                    products.by_name
                  else
                    products.by_name
                  end

        # Pagination
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 20).to_i
        per_page = [per_page, 100].min # Cap at 100 per page

        total_count = products.count
        products = products.offset((page - 1) * per_page).limit(per_page)

        render json: {
          products: products.map { |p| product_json(p) },
          meta: {
            total_count: total_count,
            page: page,
            per_page: per_page,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }
      end

      def show
        product = Product.active.find(params[:id])
        render json: { product: product_json(product) }
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: {
            code: "not_found",
            message: "Product not found"
          }
        }, status: :not_found
      end

      private

      def product_json(product)
        {
          id: product.id,
          name: product.name,
          description: product.description,
          price_cents: product.price_cents,
          price_formatted: product.price_formatted,
          currency: product.currency,
          stock_quantity: product.stock_quantity,
          available: product.available?,
          sku: product.sku,
          created_at: product.created_at.iso8601,
          updated_at: product.updated_at.iso8601
        }
      end
    end
  end
end
