class ApplicationController < ActionController::Base
  include AsyncRequestManager
  include ExceptionHandler
  include ParamsHandler
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def utility_code_header
    @utility_code_header ||= request.headers['Utility-ID']
  end

  def utility
    raise ActionController::ParameterMissing, 'Utility-ID header' if utility_code_header.nil?
    utility_code = sanitized_utility_code(utility_code_header)
    @utility ||= Utility.find_by!(code: utility_code)
  end

  def sanitized_utility_code(utility_code_header)
    Integer(utility_code_header)
  rescue ArgumentError
    nil
  end

  def render_error(identifier, message: nil, meta: nil, status: :unprocessable_entity)
    error_response = ErrorResponseBuilder.new(status).add_error(identifier, message: message, meta: meta)
    render json: error_response.to_h, status: status
  end

  def validation_error(resource)
    render json: {
      errors: [
        {
          status: '400',
          title: 'Bad Request',
          detail: resource.errors,
          code: '100'
        }
      ]
    }, status: :bad_request
  end

  def render_resource(resource)
    resource.errors.empty? ? resource_created(resource) : validation_error(resource)
  end

  def resource_created(resource)
    render json: resource, status: :created
  end

  def access_denied(exception)
    reset_session
    redirect_to '/admin/login', alert: exception.message
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name document_number])
  end
end
