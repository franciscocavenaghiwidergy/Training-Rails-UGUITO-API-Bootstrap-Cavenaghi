class NorthUtility < Utility
    def get_word_limit
        50
    end

    def content_length_of(word_count)
        return "short" if word_count <= 50
        return "medium" if word_count <= 100
        return "long" if word_count > 100
    end
end
