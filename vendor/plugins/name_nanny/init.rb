require File.dirname(__FILE__) + '/lib/name_nanny'
ActiveRecord::Base.send :include, NameNanny
