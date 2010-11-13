module SugarCRM; class Connection
  # Downloads a particular revision of a document.
  def get_document_revision(id)
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"id\": #{id}
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    SugarCRM::Response.handle(send!(:get_document_revision, json))
    #send!(:get_document_revision, json)
  end
end; end