require "fog"

module RedmineObjectStorage
  module AttachmentPatch
    
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        
        cattr_accessor :context_obj, :objectstorage_bucket_instance, :__objectstorage_config

        after_validation :save_to_objectstorage
        before_destroy   :delete_from_objectstorage

        def readable?
          !!Attachment.objectstorage_bucket.get(self.objectstorage_path) rescue false
        end
      end
    end

    module ClassMethods
      def set_context(context)
        @@context_obj = context
      end
      
      def get_context
        @@context_obj
      end

      def objectstorage_config
        unless Attachment.__objectstorage_config
          yaml = ERB.new(File.read(Rails.root.join("config", "objectstorage.yml"))).result
          @@__objectstorage_config = YAML.load(yaml).fetch(Rails.env)
        end
        return @@__objectstorage_config
      end

      def objectstorage_bucket
        unless Attachment.objectstorage_bucket_instance
          config = Attachment.objectstorage_config
          @@objectstorage_bucket_instance = Fog::Storage.new(
            provider: :aws,
            aws_access_key_id: config["access_key_id"],
            aws_secret_access_key: config["secret_access_key"],
            host: config["endpoint"],
            aws_signature_version: config["signature_version"]
          ).directories.get(config["bucket"])
        end
        @@objectstorage_bucket_instance
      end
      
      def objectstorage_absolute_path(filename, project_id)
        ts = DateTime.now.strftime("%y%m%d%H%M%S")
        [project_id, ts, filename].compact.join("/")
      end
    end

    module InstanceMethods
      def objectstorage_filename
        if self.new_record?
          timestamp = DateTime.now.strftime("%y%m%d%H%M%S")
          self.disk_filename = [timestamp, filename].join("/")
        end

        self.disk_filename.blank? ? filename : self.disk_filename
      end

      # path on objectstorage to the file, defaulting the instance's disk_filename
      def objectstorage_path(fn = objectstorage_filename)#, ctx = nil, pid = nil)
        context = self.container || self.class.get_context
        project = context.is_a?(Hash) ? Project.find(context[:project]) : context.project
        ctx = context.is_a?(Hash) ? context[:class] : context.class.name
        # XXX s/WikiPage/Wiki
        ctx = "Wiki" if ctx == "WikiPage"
        pid = project.identifier
        
        [pid, fn].compact.join("/")
      end

      def save_to_objectstorage
        if @temp_file && !@temp_file.empty?
          logger.debug "[redmine_objectstorage_attachments] Uploading #{objectstorage_filename}"

          file = Attachment.objectstorage_bucket.files.create(
            key: objectstorage_path, 
            body: @temp_file.is_a?(String) ? @temp_file : @temp_file.read
          )
          
          self.digest = file.etag
        end

        # set the temp file to nil so the model's original after_save block 
        # skips writing to the filesystem
        @temp_file = nil
      end

      def delete_from_objectstorage
        logger.debug "[redmine_objectstorage_attachments] Deleting #{objectstorage_filename}"
        Attachment.objectstorage_bucket.files.get(objectstorage_path(objectstorage_filename)).destroy
      end
    end
  end
end
