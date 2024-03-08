require 'tempfile'

class RequestListPDF

  attr_reader :base_url, :mapper

  def initialize(mapper, base_url)
    @mapper = mapper
    @base_url = base_url
  end


  def filename
    AppConfig[:request_list].fetch(:pdf_filename, 'ArchivesSpace_Request_list.pdf')
  end


  def source_file
    renderer = RequestListController.new

    out_html = Tempfile.new
    out_html.write(renderer.render_to_string partial: 'pdf_header', layout: false)

    mapper.handlers.each do |handler|
      handler.each_item_map do |item|
        out_html.write(renderer.render_to_string partial: 'item_external_display', layout: false, :locals => {:item => item, :url_prefix => base_url})
      end
    end

    out_html.write(renderer.render_to_string partial: 'pdf_footer', layout: false)
    out_html.close

    out_html
  end


  def generate
    out_html = source_file

    # XMLCleaner.new.clean(out_html.path)
    XMLCleaner.new(out_html)

    pdf_file = Tempfile.new
    pdf_file.close

    renderer = org.xhtmlrenderer.pdf.ITextRenderer.new
    renderer.set_document(java.io.File.new(out_html.path))

    # FIXME: We'll need to test this with a reverse proxy in front of it.
    renderer.shared_context.base_url = base_url

    renderer.layout

    pdf_output_stream = java.io.FileOutputStream.new(pdf_file.path)
    renderer.create_pdf(pdf_output_stream)
    pdf_output_stream.close

    out_html.unlink

    pdf_file
  end
end
