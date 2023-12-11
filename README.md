# Chromable

Ruby on Rails integration for ChromaDB based on `chroma-db` gem.

## Installation

Install `chromable` and add it to the application's Gemfile by executing:

    $ bundle add chromable

Or, if bundler is not being used to manage dependencies, install `chromable` by executing:

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

  def self.embed(text, **options)
    options[:is_query] ||= false

    if options[:is_query]
      # Call OpenAI API to embed `text` as a search query.
    else
      # Call OpenAI API to embed `text` as a post content.
    end
  end
end
```

Where:
- `document:` is a callable represents the text content you want to embed and store in ChromaDB.
- `metadata:` is the list of attributes to be passed to ChromaDB as metadata to be used to filter.
- `embedder:` is a callable defined in the model that returns the embedding representation for the given `text` and `options`.

Optionaly you can pass `collection_name:`. If not passed, the plural form of the model name will be used.

The only required option for `chromable` method is `document:`.

At this point, `chromable` will create, update, and destroy the ChromaDB embeddings for your objects based on Rails `after_save` and `after_destroy` callbacks.

To interact with the ChromaDB collection, `chromable` provides `Model.query` method to query the collection and `Model.collection` method to access the collection directly.

```ruby
puts Post.collection.count # Gets the number of documents inside the collection. Should always match Post.count.

Post.query(
  query: params[:query],
  results: 20,
  where: chroma_search_filters,
  type: 'query' # `type` here will be passed to `Post.embed` as an option.
)
```

`Model.query` accepts the same arguments accepted by `chroma-db` gem `query` method. Extra arguments will be passed to the `embedder:`. Behind the scene, `Model.query` will embed the given `query:` text, then query the collection, and return the closest `results:` records.

Also, `chromable` provides the following methods for each model instance:

- `embedding`: Retrieves the instance's ChromaDB embedding object.
- `upsert_embedding`: Creates or updates the instance's ChromaDB embedding object.
- `destroy_embedding`: Destroys the instance's ChromaDB embedding object.

All these methods (including `Model.query` and `Model.collection`) are available with `chroma_` prefix, if you have similar methods defined in your model.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle install`. To release a new version, update the version number in `version.rb`, and then create a git tag for the version, push git commits and the created tag. The `Publish Gem` Github Action will push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AliOsm/chromable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/chromable/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Chromable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/chromable/blob/main/CODE_OF_CONDUCT.md).
