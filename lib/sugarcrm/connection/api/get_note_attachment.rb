module SugarCRM; class Connection
# Retrieves an attachment from a note.
def get_note_attachment(id)
  login! unless logged_in?

  json = <<-EOF
    {
      \"session\": \"#{@session}\"\,
      \"id\": #{id}\
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  send!(:get_note_attachment, json)
end
end; end