class ExportFrameCentersController < ApplicationController
  def index
    # Find unique AT Block Names
    # => Iterate and uppercase the values so it isn't case sensitive
    @at_blocks = Footprint.all.pluck(:at_block_name).map{|record| record.upcase unless record.nil? }.uniq.sort
  end

  def generate
    fetch
  end

  def execute
    response = FrameCenter.export fetch
    if response[:pass]
        send_file(
            response[:file],
            filename: response[:file_name],
            type: "text/plain"
        )
    end
  end

  private

  def fetch
    # Find footprints 
    @frame_centers = []
    if params[:at_block].present?
      @frame_centers = frame_centers = FrameCenter.joins(:footprint).where('upper(footprints.at_block_name) = ?', params[:at_block].upcase)
    end
  end
end
