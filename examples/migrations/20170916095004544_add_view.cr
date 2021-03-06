class AddView < Jennifer::Migration::Base
  def up
    # TODO: allow escaping arguments instead of prepared statement
    create_view(:male_contacts, Jennifer::Query["contacts"].where { _gender == sql("'male'") })
  end

  def down
    drop_view(:male_contacts)
  end
end
