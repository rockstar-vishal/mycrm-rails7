module Api
  class ManifestController < ::ApiController
    before_action :find_company
    def show
      logo_form=@company.mobile_crm_logo
      to_send_data={}
      to_send_data[:company_name]=@company.name
      to_send_data[:logo]=@company.logo.url
      to_send_data[:favicon]=@company.favicon.url&.sub(/^http:/, 'https:')
      to_send_data[:icon]=@company.icon.url
      if logo_form.present?
        to_send_data[:masked_icon]=logo_form.masked_icon.url
        to_send_data[:small_icon]=logo_form.small_icon.url
        to_send_data[:large_icon]=logo_form.large_icon.url
        to_send_data[:small_maskable_icon]=logo_form.small_maskable_icon.url
        to_send_data[:large_maskable_icon]=logo_form.large_maskable_icon.url
        to_send_data[:apple_icon]=logo_form.apple_icon.url
        to_send_data[:tile_image]=logo_form.tile_image.url
        to_send_data[:favicon_32]=logo_form.large_favicon.url&.sub(/^http:/, 'https:')
        to_send_data[:er_sm_logo]=logo_form.er_sm_logo.url
      end
      render json: to_send_data
    end
    private

    def find_company
      @company=Company.find_by(mobile_domain: URI.parse(request.referrer).host)
      render json: {status: false, message: "Invalid"}, status: 400 and return unless @company.present?
    end

    
    protected

    def authenticate
    end
  end
end