import React, { useState, useEffect, Fragment } from "react";
import { Breadcrumb, Divider, Input } from "semantic-ui-react";

//Import TimelineReports Tables:
import TileTimeline from "../TimelineReports/TileTimeline";
import RejectedTileTimeline from "../TimelineReports/RejectedTileTimeline";
import FootprintsTimeline from "../TimelineReports/FootprintsTimeline";
import FrameCenterTimeline from "../TimelineReports/FrameCenterTimeline";
import PhotoCenterTimeline from "../TimelineReports/PhotoCenterTimeline";
import TileStatusMap from "./TileStatusMap";

function TileStatusShow(props) {
  console.log(props);
  const data = props;

  // Store the searched text
  const [searchInput, setSearchInput] = useState("");

  // Store the timout
  var inputTimeout;
  const searchItems = (searchValue) => {
    // Clear the timeout if the user keeps typing
    clearTimeout(inputTimeout);

    // Start a half second timeout
    inputTimeout = setTimeout(() => {
      // if the timeout occurs then store the text
      setSearchInput(searchValue.toLowerCase());
    }, 500);
  };

  return (
    <div>
      <Breadcrumb>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>
          <a href="/tile_status">Tile Status</a>
        </Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>{props.tile?.poly_id}</Breadcrumb.Section>
      </Breadcrumb>
      <Divider />

      {/* Leaflet Map here */}
      <TileStatusMap poly_id={props.tile.poly_id} token={props.token} />

      {/* <Divider /> */}

      <Input
        icon="search"
        style={{ overflow: "auto", float: "right" }}
        placeholder="Search..."
        onChange={(e) => searchItems(e.target.value)}
      />
      <div style={{ clear: "both" }} />
      <Divider />

      <TileTimeline records={[props.tile]} searchInput={searchInput} />
      {typeof data.footprints !== "undefined" && (
        <FootprintsTimeline
          records={data.footprints}
          searchInput={searchInput}
        />
      )}
      {typeof data.frame_centers !== "undefined" && (
        <FrameCenterTimeline
          records={data.frame_centers}
          searchInput={searchInput}
        />
      )}
      {data.photo_index.length > 0 && (
        <PhotoCenterTimeline
          records={data.photo_index}
          searchInput={searchInput}
        />
      )}
      {data.rejected_tiles.length > 0 && (
        <RejectedTileTimeline
          records={data.rejected_tiles}
          searchInput={searchInput}
        />
      )}
      <br />
      <br />
    </div>
  );
}

export default TileStatusShow;
