require "matrix"
require "tf-idf-similarity"

# Recommends posts similar to a given post using TF-IDF weighted term vectors
# and cosine similarity (see doc/recommendations.md for the background).
#
#   PostRecommender.new(post).similar(limit: 5) # => [#<Post>, ...]
#
# Common English words ("the", "and", "with", ...) are dropped before
# scoring, otherwise two unrelated posts look similar just because both are
# written in English.
#
# The whole corpus is scored on every call, which is fine for the small
# community this app targets. For large datasets, precompute similarities in a
# background job instead.
class PostRecommender
  include ActionView::Helpers::SanitizeHelper

  STOP_WORDS = Set.new(%w[
    a about above after again against all am an and any are as at be because
    been before being below between both but by can could did do does doing
    down during each few for from further had has have having he her here hers
    herself him himself his how i if in into is it its itself just me more most
    my myself no nor not now of off on once only or other our ours ourselves out
    over own same she should so some such than that the their theirs them
    themselves then there these they this those through to too under until up
    very was we were what when where which while who whom why will with would
    you your yours yourself yourselves
  ]).freeze

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
    text = strip_tags(body.to_s)
    TfIdfSimilarity::Document.new(text, tokens: tokens_for(text))
  end

  # Unicode-aware words (the gem's own tokenizer rules), minus stop words.
  def tokens_for(text)
    UnicodeUtils.each_word(text).reject { |word| STOP_WORDS.include?(UnicodeUtils.downcase(word)) }
  end
end
