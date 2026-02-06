class SouthUtility < Utility
    def get_word_limit
        60
    end

    def content_length_of(word_count)
        return "short" if word_count <= 60
        return "medium" if word_count <= 120
        return "long" if word_count > 120
    end
end
