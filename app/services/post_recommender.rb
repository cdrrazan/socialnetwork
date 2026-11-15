require "matrix"
require "tf-idf-similarity"

# Recommends posts similar to a given post using TF-IDF weighted term vectors
# and cosine similarity (see doc/recommendations.org for the background).
#
#   PostRecommender.new(post).similar(limit: 5) # => [#<Post>, ...]
#
# The whole corpus is scored on every call, which is fine for the small
# community this app targets. For large datasets, precompute similarities in a
# background job instead.
class PostRecommender
  include ActionView::Helpers::SanitizeHelper

  def initialize(post, scope: Post.published)
    @post = post
    @scope = scope
  end

  def similar(limit: 5)
    corpus = @scope.where.not(id: @post.id).pluck(:id, :body)
    return Post.none if corpus.empty?

    documents = corpus.map { |(_, body)| document_for(body) }
    target = document_for(@post.body)
    model = TfIdfSimilarity::TfIdfModel.new([ target, *documents ])
    scores = model.similarity_matrix.row(0).to_a.drop(1)

    ranked_ids = corpus.map(&:first).zip(scores)
                       .select { |(_, score)| score.positive? }
                       .sort_by { |(_, score)| -score }
                       .first(limit)
                       .map(&:first)

    Post.where(id: ranked_ids).in_order_of(:id, ranked_ids)
  end

  private

  def document_for(body)
    TfIdfSimilarity::Document.new(strip_tags(body.to_s))
  end
end
