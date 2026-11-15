# Post recommendations

Every post page shows a "Similar posts" list. It is produced by
[`PostRecommender`](../app/services/post_recommender.rb), which compares the
text of posts using **TF-IDF** weights and **cosine similarity**, with the
[tf-idf-similarity](https://github.com/jpmckinney/tf-idf-similarity) gem.

## How it works

1. **Build the corpus.** Take the body of every published post (HTML tags
   removed) as a document. The post being read goes first.

2. **Term frequency (TF).** Count how often each term appears in a document.
   For example, in

   > I live in Nepal and Nepal is the best country in the world

   the counts are: I = 1, live = 1, in = 2, Nepal = 2, and = 1, is = 1,
   the = 2, best = 1, country = 1, world = 1.

3. **Normalized term frequency.** Divide each count by the number of terms
   in the document (13 here): in = 2/13, Nepal = 2/13, live = 1/13, and so on.
   This stops long documents from dominating.

4. **Inverse document frequency (IDF).** Terms that appear in many
   documents ("the", "and") say little about what a document is about, so
   they are weighted down:

   ```
   IDF(term) = 1 + log(total documents / documents containing term)
   ```

5. **TF × IDF.** Each document becomes a vector with one TF-IDF weight per
   term in the vocabulary.

6. **Cosine similarity.** The similarity of two documents is the cosine of the
   angle between their vectors:

   ```
   similarity(d1, d2) = (d1 · d2) / (‖d1‖ × ‖d2‖)

   d1 · d2 = d1[0]×d2[0] + d1[1]×d2[1] + … + d1[n]×d2[n]
   ‖d‖     = √(d[0]² + d[1]² + … + d[n]²)
   ```

   1 means the same distribution of terms; 0 means no terms in common.

7. **Rank.** Drop posts with a score of 0, sort the rest by score and show
   the top five.

## Usage

```ruby
post.similar_posts             # => top 5 similar published posts
post.similar_posts(limit: 10)
PostRecommender.new(post, scope: Post.where(user: someone)).similar
```

## Limitations

- The full corpus is scored on every page view: O(posts × vocabulary). That is
  fine for hundreds of posts. For more, compute similarities in a background
  job when a post is saved and store the top matches.
- Matching is purely lexical: "JS" and "JavaScript" are different terms, and
  there is no stemming or stop-word list.
- Tags are not used. Blending tag overlap into the score is an easy
  improvement.

## References

- The Fact Machine, [Cosine similarity](http://www.thefactmachine.com/cosine-similarity/)
- [TF-IDF and cosine similarity](https://janav.wordpress.com/2013/10/27/tf-idf-and-cosine-similarity/)
