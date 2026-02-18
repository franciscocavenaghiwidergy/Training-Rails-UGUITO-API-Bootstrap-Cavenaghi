# == Schema Information
#
# Table name: utilities
#
#  id                                   :bigint(8)        not null, primary key
#  name                                 :string           not null
#  type                                 :string           not null
#  code                                 :integer
#  base_url                             :string
#  external_api_key                     :string
#  external_api_secret                  :string
#  external_api_access_token            :string
#  external_api_access_token_expiration :datetime
#  integration_urls                     :jsonb
#  jsonb                                :jsonb
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#
class Utility < ApplicationRecord
  include EntityWithCode
  include AttributeJsonParser

  JSON_ATTRIBUTES = %i[integration_urls].freeze

  has_many :users, dependent: :destroy

  validates :name, uniqueness: true
  validates :name, :type, presence: true

  store_accessor :integration_urls, :external_api_authentication_url, :books_data_url

  MEDIUM_LIMIT = nil
  LONG_LIMIT   = nil

  def medium_limit
    self.class::MEDIUM_LIMIT
  end

  def long_limit
    self.class::LONG_LIMIT
  end

  def get_word_quantity_limit
    medium_limit
  end

  def get_word_limit
    get_word_quantity_limit
  end

  def content_length_for(word_count)
    return nil if medium_limit.nil? || long_limit.nil?

    if word_count <= medium_limit
      'short'
    elsif word_count <= long_limit
      'medium'
    else
      'long'
    end
  end

  def generate_entity_code
    return if code.present? && !code.to_i.zero?
    self.code = id
    save!
  end

  def self.valid_type?(type)
    subclasses.include?(type.safe_constantize)
  end

  def utility_service_type
    "UtilityService::#{utility_type}".safe_constantize
  end

  def parameter_validator_service_type
    "ParameterValidatorService::#{utility_type}".safe_constantize
  end

  def transform_response_service_dispatcher_type
    "TransformResponseService::#{utility_type}".safe_constantize
  end

  def utility_service(user = nil)
    @utility_service ||= utility_service_type::Base.new(self, user)
  end

  def parameter_validator_service(controller: nil, params: {})
    @parameter_validator_service ||=
      parameter_validator_service_type::Base.new(self, controller, params)
  end

  def transform_response_service_dispatcher(user = nil)
    @transform_response_service_dispatcher ||=
      transform_response_service_dispatcher_type::Dispatcher.new(self, user)
  end

  def find_consumer(params)
    consumers.find_by(username: params[:username])
  end

  def clean_name
    self.class.name.underscore.split('_').first
  end

  private

  def utility_type
    type.chomp('Utility')
  end
end
