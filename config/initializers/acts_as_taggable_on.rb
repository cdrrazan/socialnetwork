# Tags are stored lowercase so "Ruby" and "ruby" are the same tag. The tags
# table uses the case-sensitive utf8mb4_bin collation, so normalising here is
# what keeps the unique index on tags.name meaningful.
ActsAsTaggableOn.force_lowercase = true
ActsAsTaggableOn.strict_case_match = true

# Delete tags that are no longer used by any post.
ActsAsTaggableOn.remove_unused_tags = true
