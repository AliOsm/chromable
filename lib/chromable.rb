# frozen_string_literal: true

require_relative 'chromable/version'

# Ruby on Rails integration for ChromaDB.
module Chromable
  def self.included(base)
    base.extend ClassMethods
    base.class_attribute :collection_name
    base.class_attribute :document
    base.class_attribute :metadata
    base.class_attribute :embedder

    base.after_save :chroma_upsert_embedding
    base.after_destroy :chroma_destroy_embedding
  end

  # Methods to be added to the model class.
  module ClassMethods
    def chromable(document:, metadata: nil, embedder: nil, collection_name: nil)
      self.collection_name = (collection_name.presence || name.underscore.pluralize)
      self.document = document
      self.metadata = metadata
      self.embedder = embedder
    end

    def chroma_collection
      Chroma::Resources::Collection.get_or_create(collection_name)
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
        query_embeddings: [send(embedder, text, **embedder_options)],
        results: results,
        where: where,
        where_document: where_document,
        include: include
      ).map(&:id))
    end

    alias collection chroma_collection unless method_defined? :collection
    alias query chroma_query unless method_defined? :query
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

  alias embedding chroma_embedding unless method_defined? :embedding
  alias upsert_embedding chroma_upsert_embedding unless method_defined? :upsert_embedding
  alias destroy_embedding chroma_destroy_embedding unless method_defined? :destroy_embedding

  private

  def build_embedding
    document = send(self.class.document)

    Chroma::Resources::Embedding.new(
      id: id,
      document: document,
      embedding: self.class.embedder && self.class.send(self.class.embedder, document),
      metadata: self.class.metadata&.index_with { |attribute| send(attribute) }
    )
  end
end
