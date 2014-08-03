require 'active_support/inflector/inflections'
require 'active_support/time'
require 'core_ext/string'
require 'money'
require 'rack/utils'
require 'spy_glass/client'

module SpyGlass
  Registry = []
  Salutations = [
    'Hi!',
    'Hello!',
    'Salutations!',
    'YO!',
    'Hi there.',
    'Hey.',
    'Hola.',
    'Ahoy!',
    'Aloha!',
    'Ciao.',
    'Hi :)',
    'Good day!',
    'Greetings!',
    'Look!'
  ].cycle
end

registry_dir = File.expand_path('../../spy_glass/registry/*.rb', __FILE__)
Dir[registry_dir].each { |file| require file } 
