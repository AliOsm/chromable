# frozen_string_literal: true

require_relative 'chromable/version'

# Ruby on Rails integration for ChromaDB.
module Chromable
  def self.included(base)
    base.extend ClassMethods
    base.include InstanceMethods

    base.after_save :chroma_upsert_embedding
    base.after_destroy :chroma_destroy_embedding
  end

  # Chromable settings class to hide them from Rails models.
  class Settings
    attr_accessor :document, :collection_name, :metadata, :embedder, :keep_document

    def initialize(document:, metadata: nil, embedder: nil, collection_name: nil, keep_document: true)
      @collection_name = collection_name
      @document = document
      @metadata = metadata
      @embedder = embedder
      @keep_document = keep_document
    end
  end

  # Methods to be added to the model class.
  module ClassMethods
    def self.extended(base)
      class << base
        alias_method :collection, :chroma_collection unless method_defined? :collection
        alias_method :delete_collection, :chroma_delete_collection unless method_defined? :delete_collection
        alias_method :query, :chroma_query unless method_defined? :query
      end

      base.cattr_accessor :chromable_settings
    end

    def chromable(**options)
      options[:collection_name] ||= name.underscore.pluralize

      self.chromable_settings = Settings.new(**options)
    end

    def chroma_collection
      Chroma::Resources::Collection.get_or_create(chromable_settings.collection_name)
    end

    def chroma_delete_collection
      Chroma::Resources::Collection.delete(chromable_settings.collection_name)
    end

    def chroma_query( # rubocop:disable Metrics/ParameterLists
      text:,
      results: 10,
      where: {},
      where_document: {},
      include: %w[metadatas documents distances],
      **embedder_options
    )
      find(chroma_collection.query(
        query_embeddings: [send(chromable_settings.embedder, text, **embedder_options)],
        results: results,
        where: where,
        where_document: where_document,
        include: include
      ).map(&:id))
    end
  end

  # Methods to be added to the model instances.
  module InstanceMethods
    def self.included(base)
      base.instance_eval do
        # rubocop:disable Style/Alias
        alias_method :embedding, :chroma_embedding unless method_defined? :embedding
        alias_method :upsert_embedding, :chroma_upsert_embedding unless method_defined? :upsert_embedding
        alias_method :destroy_embedding, :chroma_destroy_embedding unless method_defined? :destroy_embedding
        # rubocop:enable Style/Alias
      end
    end

    def chroma_embedding
      self.class.chroma_collection.get(ids: [id])[0]
    end

    def chroma_upsert_embedding
      self.class.chroma_collection.upsert(build_embedding)
    end

    def chroma_destroy_embedding
      self.class.chroma_collection.delete(ids: [id])
    end

    private

    def build_embedding
      Chroma::Resources::Embedding.new(
        id: id,
        document: document_to_embed,
        embedding: document_embedding,
        metadata: embedding_metadata
      )
    end

    def document_to_embed
      chromable_settings.keep_document ? send(chromable_settings.document) : nil
    end

    def document_embedding
      chromable_settings.embedder && self.class.send(chromable_settings.embedder, send(chromable_settings.document))
    end

    def embedding_metadata
      chromable_settings.metadata&.index_with { |attribute| send(attribute) }
    end
  end
end
