module SugarCRM; class Connection
  # Sets a new revision for a document.
  def set_document_revision(id, revision)
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"document_revision\": \"#{revision}\"\,
        \"id\": #{id}
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_document_revision, json)
  end
end; end