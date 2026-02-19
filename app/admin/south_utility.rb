SOUTH_UTILITY_PERMITTED_KEYS = %i[
  name code base_url external_api_key external_api_secret
  external_api_authentication_url books_data_url notes_data_url
  notes_short_limit notes_medium_limit
].freeze

ActiveAdmin.register SouthUtility do
  filter :name
  filter :code
  filter :created_at
  filter :updated_at

  permit_params *SOUTH_UTILITY_PERMITTED_KEYS

  member_action :copy, method: :get do
    @south_utility = resource.dup
    render :new, layout: false
  end

  action_item :copy, only: :show do
    link_to(I18n.t('active_admin.clone_model', model: 'SouthUtility'),
            copy_admin_south_utility_path(id: resource.id))
  end

  controller do
    define_method :permitted_params do
      params.permit(active_admin_namespace.permitted_params, south_utility: SOUTH_UTILITY_PERMITTED_KEYS)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :code
    actions
  end

  show do |south|
    render 'show', locals: { south: south }
    active_admin_comments
  end

  form do |f|
    f.inputs 'Utility Details', allow_destroy: true do
      f.semantic_errors(*f.object.errors.keys)
      f.input :name
      f.input :code
      f.input :external_api_key
      f.input :external_api_secret
      f.input :external_api_authentication_url, as: :url
      f.input :books_data_url, as: :url
      f.input :notes_data_url, as: :url
      f.input :notes_short_limit,
              label: 'Limite short notas',
              hint: 'En blanco usa el valor por defecto (South: 60).'
      f.input :notes_medium_limit,
              label: 'Limite medium notas',
              hint: 'En blanco usa el valor por defecto (South: 120).'
      f.actions
    end
  end
end
