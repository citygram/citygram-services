require 'active_support/inflector/inflections'
require 'active_support/time'
require 'money'
require 'spy_glass/clients'

registry_dir = File.expand_path('../../spy_glass/registry/*.rb', __FILE__)
Dir[registry_dir].each { |file| require file } 
