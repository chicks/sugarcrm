SugarCRM::Contact.class_eval do
  def self.is_monkey_patched?
    true
  end
  
  def is_monkey_patched?
    true
  end
end