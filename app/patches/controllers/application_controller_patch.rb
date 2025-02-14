require_dependency 'application_controller'

module  Controllers
  module ApplicationControllerPatch
    extend ActiveSupport::Concern
    unloadable

    included do
      unloadable
      before_action :check_out_of_band_auth
      alias_method :check_twofa_activation_without_out_of_band_auth, :check_twofa_activation 
      def check_twofa_activation
        if User.current.enabled_out_of_band_auth?
          return
        end
        check_twofa_activation_without_out_of_band_auth
      end
      def check_out_of_band_auth
        return true if request.original_url.include? "out_of_band_auths/login"
        return true if controller_name == 'account'
        return true if session[:pwd].present?

        if session[:oob]
          if User.current.enabled_out_of_band_auth?

            flash[:notice] = l(:notice_sent_verification_code, email: ERB::Util.h(User.current.mail))
            redirect_to controller: 'out_of_band_auths', action: 'login'
          else
            session.delete(:oob)
          end
        end
      end

    end

  end
end

Controllers::ApplicationControllerPatch.tap do |mod|
  ApplicationController.send :include, mod unless ApplicationController.include?(mod)
end
