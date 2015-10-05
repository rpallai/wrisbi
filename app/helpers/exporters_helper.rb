module ExportersHelper
  def exporters(treasury)
    treasury.exporters.map{|exporter| [exporter.name, exporter.id]}
  end
end
