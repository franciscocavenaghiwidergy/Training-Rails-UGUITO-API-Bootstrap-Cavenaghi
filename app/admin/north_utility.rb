ActiveAdmin.register NorthUtility do
  permit_params *%i[
    name code base_url external_api_key external_api_secret
    external_api_authentication_url books_data_url notes_data_url
    notes_short_limit notes_medium_limit
  ]

  filter :name
  filter :code
  filter :created_at
  filter :updated_at

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
      keys = %i[
        name code base_url external_api_key external_api_secret
        external_api_authentication_url books_data_url notes_data_url
        notes_short_limit notes_medium_limit
      ]
      params.permit(active_admin_namespace.permitted_params, north_utility: keys)
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
    render 'show', locals: { north: north }
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
      f.input :notes_short_limit,
              label: 'Limite short notas',
              hint: 'En blanco usa el valor por defecto (North: 50).'
      f.input :notes_medium_limit,
              label: 'Limite medium notas',
              hint: 'En blanco usa el valor por defecto (North: 100).'
      f.actions
    end
  end
end
