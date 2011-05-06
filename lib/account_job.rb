class AccountJob < Struct.new(:data)

  def perform
    type, school = data[:type], data[:school]
    klass = Object.const_get(type.chomp('s').capitalize)
    id_number = klass.maximum('id_number', :conditions => ['school_id = ?', school]) || 0
    users = data[:accounts].map do |name|
      id_number += 1
      account = name.except(:login, :position)
      klass.new(account.merge(:school_id => school.id, :id_number => id_number))
    end
    User.transaction do
      User.import_with_authorizations users
      School.find(school).add_parents_bulk if type == 'students'
    end
  end

end

