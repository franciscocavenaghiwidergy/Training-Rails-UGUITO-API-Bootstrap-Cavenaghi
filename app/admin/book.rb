# frozen_string_literal: true

ActiveAdmin.register Book do
  menu label: 'Books', priority: 2

  includes :utility, :user

  filter :title
  filter :author
  filter :genre
  filter :publisher
  filter :year
  filter :utility_id, as: :select, collection: -> { Utility.all.map { |u| [u.name, u.id] } }
  filter :user_id, as: :select, collection: -> { User.all.map { |u| ["#{u.email} (##{u.id})", u.id] } }
  filter :created_at
  filter :updated_at

  permit_params :utility_id, :user_id, :genre, :author, :image, :title, :publisher, :year

  index do
    selectable_column
    id_column
    column :title
    column :author
    column :genre
    column :publisher
    column :year
    column :utility do |book|
      book.utility&.name
    end
    column :user do |book|
      book.user&.email
    end
    column :created_at
    actions
  end

  show do |book|
    attributes_table do
      row :id
      row :title
      row :author
      row :genre
      row :image
      row :publisher
      row :year
      row :utility do
        book.utility&.name
      end
      row :user do
        book.user&.email
      end
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |book_form|
    book_form.semantic_errors(*book_form.object.errors.keys)
    book_form.inputs 'Book Details' do
      book_form.input :utility_id, as: :select,
                      collection: Utility.all.map { |user| [user.name, user.id] },
                      include_blank: 'Select Utility'
      book_form.input :user_id, as: :select,
                      collection: User.all.map { |user| ["#{user.email} (##{user.id})", user.id] },
                      include_blank: 'Select User'
      book_form.input :title
      book_form.input :author
      book_form.input :genre
      book_form.input :image
      book_form.input :publisher
      book_form.input :year
    end
    book_form.actions
  end
end
