class AccountUpload < Upload

  def hashify(user_or_hash)
    if user_or_hash.is_a?(Hash) 
      user_or_hash 
    else
      { :first_name => user_or_hash.first_name,
        :last_name => user_or_hash.last_name,
        :grade => user_or_hash.grade,
        :id_number => user_or_hash.id_number,
        :authorization => { :login => user_or_hash.login }
      }
    end
  end

  def import_users(params, type, school, override = {})
    @names = prep_names(params)
    type = 'staffers' if type == 'administrators'
    @klass = Object.const_get(type.chomp('s').capitalize)
    substitute(override)
    duplicates, @saveable = check_duplicate_logins
    @existing_auth = Authorization.find_all_by_school_id(school, :select => 'login').map(&:login)
    @saveable, @unsaveable = @saveable.partition{|name| !@existing_auth.include?(name[:login]) }
    @unsaveable += duplicates
    check_teacher_limit(school, type)
    @saveable, @substitutes = @saveable.partition{|name| name[:replacement].blank?}
    if should_create_accounts?(school, type)
      Delayed::Job.enqueue(AccountJob.new(:school => school, 
                                 :type => type, :accounts => @saveable)) 
    end
    hydrate_users
    [@saveable, @unsaveable, @substitutes]
  end

  def replace(old, new)
    unless @names.index(old).nil? || 
      new[:authorization][:login] == (old[:first_name] + old[:last_name]).downcase
      @names[@names.index(old)] = new.except(:authorization).merge({
                                  :login => new[:authorization][:login], 
                                  :replacement => true})
    end
  end

  def substitute(override)
    skip_id_number = @names.all?{|name| name[:id_number].blank?}
    skip_grade = @names.all?{|name| name[:grade].blank?}
    override.each do |entry|
      replacement = hashify(entry)
      replaced = identify(replacement, skip_id_number, skip_grade) 
      replace(replaced, replacement)
    end
  end
  
  def identify(replacement, skip_id_number, skip_grade)
    @names.detect do |name|
      name[:first_name] == replacement[:first_name] &&
      name[:replacement].blank? &&
      name[:last_name] == replacement[:last_name] &&
      match(:id_number, name, replacement, skip_id_number) &&
      match(:grade, name, replacement, skip_grade)
    end
  end

  def match(attr, name, replacement, skip)
    skip || name[attr].to_i == replacement[attr].to_i || 
    replacement[attr].blank? 
  end

  def hydrate_users
    @saveable.map! do |user| 
      u = @klass.new(user.except(:login, :position))
      u.build_authorization(:login => user[:login])
      u
    end
    @unsaveable.map! do |user| 
      u = @klass.new(user.except(:login, :position, :replacement))
      u.build_authorization(:login => user[:login])
      u.authorization.errors.add(:login, 'must be unique. The default login for a user is created by combining the user&#39;s first and last names, so if two people in your school have the same name one of them will have to be given a different login at first. Each user can change their own username to something equally memorable but more secure on first log in.'.html_safe) 
      u
    end
  end

  def check_teacher_limit(school, type)
    @saveable = @saveable[0, school.teacher_limit - school.teachers(true).length] if type == 'teachers'
  end

  def check_duplicate_logins
    @names.each_with_index{|name, i| name[:login] ||= (name[:first_name] + name[:last_name]).downcase; name[:position] = i}
    @names = @names.sort_by{|name| name[:login]}
    @names.partition{|name| name != @names.first && @names[@names.index(name)-1][:login] == name[:login]}
  end

  def no_bad_accounts?(school)
    school_id = school.id
    id_number = (@klass.maximum('id_number', :conditions => ['school_id = ?', school_id]) || 0) + @saveable.length + 1
    @substitutes.map! do |user|
      id_number += 1
      u = @klass.new(user.except(:login, :position, :replacement))
      u.school_id = school_id
      u.id_number ||= id_number
      u.build_authorization(:login => user[:login], :school_id => school_id)
      u
    end
    @unsaveable.empty? && @substitutes.all?{|u| u.valid?} 
  end
  
  def prep_names(params)
    first_row = params[:header_row] ? 0 : 1
    imported_columns = params[:import].delete_if {|key,value| value == ''}
    data[first_row..-1].map do |row|
      h = {}
      imported_columns.each{|k,v| h[v.to_sym] = row[k.to_i]}
      h[:last_name], h[:first_name] = h[:last_first].split(/,\s+/) if h[:last_first]
      h[:first_name], h[:last_name] = h[:full_name].split if h[:full_name]
      (h[:last_name] && h[:first_name]) ? h.except(:last_first, :full_name) : nil
    end.compact
  end

  def should_create_accounts?(school, type)
    no_bad_accounts?(school) || teacher_limit_reached?(school, type)
  end

  def teacher_limit_reached?(school, type)
    type == 'teachers' && @saveable.length + school.teachers.length == school.teacher_limit
  end
end
