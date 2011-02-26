# Load the values in config/sugarcrm.yml into a hash
config_values = SugarCRM::Session.parse_config_file(File.join(Rails.root, 'config', 'sugarcrm.yml'))
# Connect to appropriate SugarCRM instance (depending on Rails environment)
SugarCRM::Session.from_hash(config_values[Rails.env.to_sym])