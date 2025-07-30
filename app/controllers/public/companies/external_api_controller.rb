module Public

  module Companies

    class ExternalApiController < ::PublicApiController

      before_action :find_company

      def projects
        projects = @company.projects.as_api_response(:details)
        render json: {projects: projects}, status: 200
      end

      private

      def find_company
        @company = Company.find_by(uuid: params[:uuid])
        if @company.blank?
          render json: {status: false, message: "Invalid Request"}, status: 422 and return
        end
      end

    end

  end

end
