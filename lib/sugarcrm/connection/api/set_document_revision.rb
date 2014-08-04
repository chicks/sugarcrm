module SugarCRM; class Connection
  # Sets a new revision for a document.
  def set_document_revision(document_id, revision_number, opts={})
    options = { 
      :file => '', 
      :file_name => '',
      :document_name => nil
    }.merge! opts
    
    # Raise an exception of we try to pass :file, but not :file_name
    if (!options[:file].empty? && options[:file_name].empty?)
      raise ArgumentError, ":file_name must be specified if :file is specified"
    end
    
    # If no document_name is given, use the file_name
    options[:document_name] ||= options[:file_name]
    
    login! unless logged_in?
    
    json = <<-EOF
      {
        "session": "#{@sugar_session_id}",
        "document_revision": {
           "id": "#{document_id}",
           "document_name": "#{options[:document_name]}",
           "revision": "#{revision_number}",
           "filename": "#{options[:file_name]}",
           "file": "#{b64_encode(options[:file])}"
        }
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_document_revision, json)
  end
end; end