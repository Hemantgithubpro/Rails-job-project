module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :authenticate_admin!
      end
    end
  end
end
