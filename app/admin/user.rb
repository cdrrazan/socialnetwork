ActiveAdmin.register User do
  menu priority: 2
  actions :all, except: :new

  # Admins can only toggle the `admin` flag; members manage everything else.
  permit_params :admin

  index do
    selectable_column
    id_column
    column :username
    column :email
    column :admin
    column :sign_in_count
    column :created_at
    actions
  end

  filter :username
  filter :email
  filter :admin
  filter :created_at

  show do
    attributes_table do
      row :username
      row :email
      row :admin
      row :sign_in_count
      row :last_sign_in_at
      row :created_at
    end
  end

  form do |f|
    f.inputs "Permissions" do
      f.input :admin, label: "Site moderator (may edit or delete any member content)"
    end
    f.actions
  end
end
