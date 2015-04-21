module RedmineObjectStorage
  module AttachmentsControllerPatch
    
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable
        before_filter :redirect_to_objectstorage, :except => :destroy
        skip_before_filter :file_readable
      end
    end

    def redirect_to_objectstorage
      skip_redirection = false
      
      if @attachment.nil?
        # Since we uploads occur prior to an actual record being created,
        # the context needs to be parsed from the url.
        #   ex: http://url/projects/project_id/..../action_id
        ref = request.env["HTTP_REFERER"].split("/")
        # We also only want the url parts that follow .../projects/ if possible.
        # If not, just use the standard split HTTP_REFERER
        ref = ref[ref.index("projects") + 1 .. -1] if ref.index("projects")

        # For "Issues", the url is longer than "News" or "Documents"
        klass_idx = (ref.length > 2) ? -2 : -1
        klass = ref[klass_idx].singularize.titlecase
        # For attachments in the "File" area, we want to identify
        # as a "Project" since there technically is no "File" container
        klass = "Project" if klass == "File"
        
        # Try to match an id (regardless of whether it'll be valid)
        record  = ref[-1].to_i
        project = if record > 0
          klass.constantize.find(record).project_id
        else
          ref[0] # we won't have a project AND a record, so this shouldn't fail
        end

        filename = request.env["QUERY_STRING"].scan(/filename=(.*)/).flatten.first
        path = Attachment.objectstorage_absolute_path(filename, project)

        Attachment.set_context :class => klass, :project => project
        skip_redirection = true
      else
        if @attachment.respond_to?(:container)
          Attachment.set_context @attachment.container
          # increment the download counter if necessary
          @attachment.increment_download if (@attachment.container.is_a?(Version) || @attachment.container.is_a?(Project))
        end
      end

      path ||= @attachment.objectstorage_path

      expire_str = Attachment.objectstorage_config["expire"]
      expire = expire_str ? Integer(expire_str) : 86400
      redirect_to(p(Attachment.objectstorage_bucket.files.get(path).url(Time.now.to_i + expire))) unless skip_redirection
    end
  end
end
