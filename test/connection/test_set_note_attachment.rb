require 'helper'

class TestSetNoteAttachment < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "Add an attachment to a Note" do
      n = SugarCRM::Note.new
      n.name = "A Test Note"
      assert n.save
      file = File.read("test/config_test.yaml")
      assert SugarCRM.connection.set_note_attachment(n.id, "config_test.yaml", file)
      attachment = SugarCRM.connection.get_note_attachment(n.id)
      assert_equal file, Base64.decode64(attachment["file"])
      assert n.delete
    end
  end
end