module Api

  module MobileCrm

    module SvApps

      class OtpsController < ::Api::MobileCrm::SiteVisitInformationsController

        before_action :find_company, :set_api_key
        before_action :authenticate, except: [:create, :validate]

        def create
          if otp_params[:lead_no].present?
            lead=@company.leads.find_by(lead_no: otp_params[:lead_no])
            render json: {success: false, message: "Invalid Lead No."}, status: 422 and return unless lead.present?
            mobile_num= lead.mobile&.last(10)
          else
            mobile_num= otp_params[:mobile]
          end
          is_otp_generated, otp = @company.generate_sms_otp(
              {validatable_data: mobile_num, event_type: 'sv_visit'}
            )
          if is_otp_generated
            render json: {success: true, message: 'otp created'}, status: 201
          else
            render json: {success: false}, status: 422
          end
        end

        def validate
          lead_no=params[:lead_no]
          lead=@company.leads.find_by(lead_no: lead_no) if lead_no.present?
          mobile=lead&.mobile || params[:mobile]
          if @company.validate_otp({otp: params[:otp], event_type: 'sv_visit', validatable_data: mobile})
            render json: {success: true, message: 'otp validated'}, status: 202
          else
            render json: {success: false, message: 'Invalid Otp'}, status: 401
          end
        end


        def otp_params
          params.require(:params).permit(
            :mobile, :lead_no
          )

        end

      end

    end

  end

end