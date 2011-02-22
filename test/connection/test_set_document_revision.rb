require 'helper'

class TestSetDocumentRevision < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "Update a document revision" do
      file = File.read("test/config_test.yaml")
      # Create a new document, no file is attached or uploaded at this stage.
      d = SugarCRM::Document.create(
        :revision     => 1, 
        :active_date  => Date.today,
        :filename     => "config_test.yaml", 
        :document_name=> "config_test.yaml",
        :uploadfile   => "config_test.yaml"
      )
      # Did we succeed?
      assert !d.new?
      # Create a new document revision, attaching the file to the document_revision, and associating the document
      # revision with parent document
      assert SugarCRM.connection.set_document_revision(d.id, d.revision + 1, {:file => file, :file_name => "config_test.yaml"})
      # Delete the document
      assert d.delete
      # Remove any document revisions associated with that document
      SugarCRM::DocumentRevision.find_all_by_document_id(d.id).each do |dr|
        assert dr.delete
      end
    end
  end
end