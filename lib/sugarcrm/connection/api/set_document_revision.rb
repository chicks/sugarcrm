module SugarCRM; class Connection
  # Sets a new revision for a document.
  def set_document_revision(document_id, revision_number, opts={})
    options = { 
      :file => '', 
      :file_name => '' 
    }.merge! opts
    
    # Raise an exception of we try to pass :file, but not :file_name
    if (!options[:file].empty? && options[:file_name].empty?)
      raise ArgumentException, ":file_name must be specified if :file is specified"
    end
    
    login! unless logged_in?
    json = <<-EOF
      {
        "session": "#{@session.id}",
        "document_revision": {
           "id": "#{document_id}",
           "filename": "#{options[:file_name]}",
           "file": "#{Base64.encode64(options[:file])}",
           "revision": "#{revision_number}"
        }
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_document_revision, json)
  end
end; end