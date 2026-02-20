ActiveAdmin.register NorthUtility do
  filter :name
  filter :code
  filter :created_at
  filter :updated_at

  permit_params = %i[
    name code base_url external_api_key external_api_secret
    external_api_authentication_url books_data_url notes_data_url
  ]

  member_action :copy, method: :get do
    @north_utility = resource.dup
    render :new, layout: false
  end

  action_item :copy, only: :show do
    link_to(I18n.t('active_admin.clone_model', model: 'NorthUtility'),
            copy_admin_north_utility_path(id: resource.id))
  end

  controller do
    define_method :permitted_params do
      params.permit(active_admin_namespace.permitted_params, north_utility: permit_params)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :code
    actions
  end

  show do |north|
    attributes_table do
      row :id
      row :name
      row :code
      row :type
      row :base_url
      row :external_api_key
      row :external_api_secret
      row :external_api_authentication_url
      row :books_data_url
      row :notes_data_url
      row :external_api_access_token do |u|
        u.external_api_access_token.present? ? '••••••••' : status_tag('no')
      end
      row :external_api_access_token_expiration
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.inputs 'Utility Details', allow_destroy: true do
      f.semantic_errors(*f.object.errors.keys)
      f.input :name
      f.input :code
      f.input :base_url, as: :url
      f.input :external_api_key
      f.input :external_api_secret
      f.input :external_api_authentication_url, as: :url
      f.input :books_data_url, as: :url
      f.input :notes_data_url, as: :url
      f.actions
    end
  end
end
