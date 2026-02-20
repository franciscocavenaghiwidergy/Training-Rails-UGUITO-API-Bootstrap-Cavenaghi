# frozen_string_literal: true

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    panel 'Utilities' do
      table_for Utility.order(code: :asc) do
        column('Name', &:name)
        column('Code', &:code)
        column('Type', &:type)
        column('Base URL') { |u| u.base_url.present? ? truncate(u.base_url, length: 50) : '—' }
        column('Created', &:created_at)
        column('Actions') do |utility|
          buffer = link_to('Ver', send("admin_#{utility.class.to_s.underscore}_path", utility))
          buffer += ' '
          buffer +=
            link_to('Editar',
                    send("edit_admin_#{utility.class.to_s.underscore}_path", utility))
          buffer
        end
      end
    end

    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end
end
