# Redmine ObjectStorage Plugin

Use Amazon S3 and other S3 compatible storages as file store for your Redmine (3.0 or later).

## Installation

### Install Plugin

```ruby
cd ${YOUR_REDMINE_ROOT}
git clone https://github.com/nttcom/redmine_objectstorage plugins/redmine_objectstorage
rm -rf plugins/redmine_objectstorage/.git # for Heroku or other PaaS users
```

### Edit config/objectstorage.yml

```shell
cp plugins/objectstorage.yml.example config/objectstorage.yml
```

config/objectstorage.yml:
```yaml
production:
  access_key_id: YOUR_ACCESS_KEY_ID
  secret_access_key: YOUR_SECRET_ACCESS_KEY
  bucket: BACKET_NAME
  endpoint: endpoint.example.com
  #signature_version: 2 # some storage backends are compatible only with signature version 2
```

## Contributing

1. Fork it ( https://github.com/nttcom/redmine_objectstorage/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
