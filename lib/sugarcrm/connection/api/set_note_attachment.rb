module SugarCRM; class Connection
  # Creates or updates an attachment on a note
  def set_note_attachment(id, filename, file, opts={})
    options = { 
      :module_id => '', 
      :module_name => '' 
    }.merge! opts
    
    login! unless logged_in?
    json = <<-EOF
      {
        "session": "#{@sugar_session_id}",
           "note": {
              "id": "#{id}",
              "filename": "#{filename}",
              "file": "#{b64_encode(file)}",
              "related_module_id": "#{options[:module_id]}",
              "related_module_name": "#{options[:module_name]}" 
           }
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_note_attachment, json)
  end
end; end
