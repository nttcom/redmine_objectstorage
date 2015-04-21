require_relative 'lib/redmine_objectstorage'

Redmine::Plugin.register :redmine_dropbox_attachments do
  name        "Redmine Object Storage Plugin"
  author      "NTT Communications"
  description "Use object storage for attachment storage"
  author_url  "http://ntt.com/"
  version     "0.0.1"

  requires_redmine :version_or_higher => '3.0.0'
end
