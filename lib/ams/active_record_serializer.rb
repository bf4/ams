# frozen_string_literal: true

require "ams/serializer"
module AMS
  class ActiveRecordSerializer < Serializer
    class << self
      # @example
      #   relation :articles, type: :articles, to: :many, key: :posts
      #
      #     def related_articles_ids
      #       object.aritcles.pluck(:id)
      #     end
      #
      #     def related_articles_data
      #       related_articles_ids.map {|id| relationship_data(id, :articles) }
      #     end
      #
      #     def articles
      #       {}.tap do |hash|
      #         hash[:data] = related_articles_data
      #       end
      #     end
      #
      def _relation_to_many(relation_name, type:, key: relation_name, **options)
        options.fetch(:ids) do
          options[:ids] = "object.#{relation_name}.pluck(:id)"
        end
        super
      end

      # @example
      #   relation :article, type: :articles, to: :one, key: :post
      #
      #     def related_article_id
      #       object.article.id
      #     end
      #
      #     def related_article_data
      #       relationship_data(related_article_id, :articles)
      #     end
      #
      #     def article
      #       {}.tap do |hash|
      #         hash[:data] = related_article_data
      #       end
      #     end
      #
      def _relation_to_one(relation_name, type:, key: relation_name, **options)
        options.fetch(:id) do
          options[:id] = "object.#{relation_name}.id"
        end
        super
      end
    end
  end
end
