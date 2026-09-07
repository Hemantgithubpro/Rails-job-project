module Api
  module V1
    module Admin
      class ProductsController < BaseController
        def index
          products = Product.all

          # Include inactive products for admin
          products = products.where(active: params[:active] == "true") if params[:active].present?

          # Apply search filter
          products = products.search_by_name(params[:q]) if params[:q].present?

          # Apply sorting
          products = case params[:sort]
                    when "price_asc"
                      products.by_price_asc
                    when "price_desc"
                      products.by_price_desc
                    when "name"
                      products.by_name
                    else
                      products.order(created_at: :desc)
                    end

          # Pagination
          page = (params[:page] || 1).to_i
          per_page = (params[:per_page] || 20).to_i
          per_page = [per_page, 100].min

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
          product = Product.find(params[:id])
          render json: { product: product_json(product) }
        rescue ActiveRecord::RecordNotFound
          render json: {
            error: {
              code: "not_found",
              message: "Product not found"
            }
          }, status: :not_found
        end

        def create
          product = Product.new(product_params)

          if product.save
            render json: { product: product_json(product) }, status: :created
          else
            render json: {
              error: {
                code: "validation_failed",
                message: product.errors.full_messages.join(", ")
              }
            }, status: :unprocessable_entity
          end
        end

        def update
          product = Product.find(params[:id])

          if product.update(product_params)
            render json: { product: product_json(product) }
          else
            render json: {
              error: {
                code: "validation_failed",
                message: product.errors.full_messages.join(", ")
              }
            }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: {
            error: {
              code: "not_found",
              message: "Product not found"
            }
          }, status: :not_found
        end

        def destroy
          product = Product.find(params[:id])
          product.destroy!

          head :no_content
        rescue ActiveRecord::RecordNotFound
          render json: {
            error: {
              code: "not_found",
              message: "Product not found"
            }
          }, status: :not_found
        end

        private

        def product_params
          params.permit(:name, :description, :price_cents, :currency, :stock_quantity, :active, :sku)
        end

        def product_json(product)
          {
            id: product.id,
            name: product.name,
            description: product.description,
            price_cents: product.price_cents,
            price_formatted: product.price_formatted,
            currency: product.currency,
            stock_quantity: product.stock_quantity,
            active: product.active,
            available: product.available?,
            sku: product.sku,
            created_at: product.created_at.iso8601,
            updated_at: product.updated_at.iso8601
          }
        end
      end
    end
  end
end
