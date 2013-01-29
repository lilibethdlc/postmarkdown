module PostHelper
  class Sanitizer < HTML::WhiteListSanitizer
    self.allowed_tags -= %w(img a)
  end

  def post_summary_html(post)
    if post.summary.present?
      content_tag :p, post.summary
    else
      html = Sanitizer.new.sanitize(post_content_html(post))
      doc = Nokogiri::HTML.fragment(html)
      para = doc.search('p').detect { |p| p.text.present? }
      para.try(:to_html).try(:html_safe)
    end
  end

  def post_content_html(post)
    renderer = HTMLwithPygments.new(hard_wrap: true)
    options = {
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      lax_html_blocks: true,
      strikethrough: true,
      superscript: true
    }
    Redcarpet::Markdown.new(renderer, options).render(render(:inline => post.content)).html_safe
  end

  require 'net/http'
  require 'uri'
  class HTMLwithPygments < Redcarpet::Render::HTML
    def block_code(code, language)
      sha = Digest::SHA1.hexdigest code
      Rails.cache.fetch ['code', language, sha].join('-') do
        Pygmentize.process(code, language)
      end
    end
  end
end
