# Chromable

Ruby on Rails integration for ChromaDB based on `chroma-db` gem.

## Installation

Since `chromable` is depending on `chroma-db` gem, you will need to install it using:

    $ bundle add chroma-db

Or, if you are not using bundler, install it by executing:

    $ gem install chroma-db

Then, install `chromable` and add to the application's Gemfile by executing:

    $ bundle add chromable

Or, if you are not using bundler, install it by executing:

    $ gem install chromable

## Usage

`chromable` is depending on `chroma-db`, so you will need to initialize it in `config/initializers/chroma.rb`:

```ruby
require 'chroma-db'

Chroma.connect_host = ENV.fetch('CHROMA_DB_URL', 'http://localhost:8000')
Chroma.logger = Logger.new($stdout)
Chroma.log_level = Chroma::LEVEL_ERROR
```

Then, include `Chromable` module in your model and initialize it:

```ruby
class Post < ApplicationRecord
  include Chromable

  chromable document: :content, metadata: %i[author category], embedder: :embed
end
```

Where:
- `document:` is a callable represents the text content you want to embed and store in ChromaDB.
- `metadata:` is the list of attributes to be passed to ChromaDB as metadata to be used to filter.
- `embedder:` is a callable returns the embedding representation for the current instance.

Optionaly you can pass `collection_name:`. If not passed, the plural form of the model name will be used.

All `chromable` method arguments are optional.

To interact with the ChromaDB collection, `chromable` provides `Model.collection` method to retrieve the collection instance.
Also, `chromable` provides the following methods for each model instance:

- `embedding`: Retrieves the instance's ChromaDB embedding object.
- `upsert_embedding`: Creates or updates the instance's ChromaDB embedding object.
- `destroy_embedding`: Destroys the instance's ChromaDB embedding object.

All these methods (including `Model.collection`) are available with `chroma_` prefix, if you have similar methods defined in your model.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle install`. To release a new version, update the version number in `version.rb`, and then create a git tag for the version, push git commits and the created tag. The `Publish Gem` Github Action will push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AliOsm/chromable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/chromable/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Chromable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/chromable/blob/main/CODE_OF_CONDUCT.md).
