# Include your extension files here, as simple *.rb files. Here is an example of an extension:

SugarCRM::Contact.class_eval do
  def self.ten_oldest
    self.all(:order_by => 'date_entered', :limit => 10)
  end
  
  def vip?
    self.opportunities.size > 100
  end
end

# This will enable you to call

SugarCRM::Contact.ten_oldest

# to get the 10 oldest contacts entered in CRM .
# 
# You will also be able to call

SugarCRM::Contact.first.vip?

# to see whether a contact is VIP or not.