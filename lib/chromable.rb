# frozen_string_literal: true

require 'active_support/concern'

require_relative 'chromable/version'

# Ruby on Rails integration for ChromaDB.
module Chromable
  extend ActiveSupport::Concern

  included do
    after_save :chroma_upsert_embedding
    after_destroy :chroma_destroy_embedding

    class_attribute :collection_name
    class_attribute :document
    class_attribute :metadata
    class_attribute :embedder
  end

  class_methods do
    def chromable(document:, metadata:, embedder:, collection_name: nil)
      self.collection_name = (collection_name.presence || name.underscore.pluralize)
      self.document = document
      self.metadata = metadata
      self.embedder = embedder
    end

    def chroma_collection
      Chroma::Resources::Collection.get_or_create(collection_name)
    end

    alias_method :collection, :chroma_collection unless method_defined? :collection
  end

  def chroma_embedding
    self.class.chroma_collection.get(ids: [id])[0]
  end

  def chroma_upsert_embedding
    self.class.chroma_collection.upsert(
      Chroma::Resources::Embedding.new(
        id: id,
        document: send(self.class.document),
        embedding: send(self.class.embedder),
        metadata: self.class.metadata.index_with { |attribute| send(attribute) }
      )
    )
  end

  def chroma_destroy_embedding
    self.class.chroma_collection.delete(ids: [id])
  end

  alias embedding chroma_embedding unless method_defined? :embedding
  alias upsert_embedding chroma_embedding unless method_defined? :upsert_embedding
  alias destroy_embedding chroma_embedding unless method_defined? :destroy_embedding
end
