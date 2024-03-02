import React, { useState, Fragment } from "react";
import {
  Table,
  Breadcrumb,
  Divider,
  Icon,
  Button,
  Input,
} from "semantic-ui-react";
import Breadcrumbs from "../Shared/Breadcrumb";
import _ from "lodash";
import DoqqTimeline from "./TimelineReports/DoqqTimeline";
import EasementsTimeline from "./TimelineReports/EasementsTimeline";
import FootprintsTimeline from "./TimelineReports/FootprintsTimeline";
import FrameCenterTimeline from "./TimelineReports/FrameCenterTimeline";
import TileTimeline from "./TimelineReports/TileTimeline";
import RejectedTileTimeline from "./TimelineReports/RejectedTileTimeline";
import RejectedFootprintsTimeline from "./TimelineReports/RejectedFootprintsTimeline";
import RejectedFrameTimeline from "./TimelineReports/RejectedFrameTimeline";
import PhotoCenterTimeline from "./TimelineReports/PhotoCenterTimeline";
import PackingSlipsTimeline from "./TimelineReports/PackingSlipsTimeline";
import WebLogTimeline from "./TimelineReports/WebLogTimeline";
import CompanyTimeline from "./TimelineReports/CompanyTimeline";
import CameraTimeline from "./TimelineReports/CameraTimeline";
import PlaneTimeline from "./TimelineReports/PlaneTimeline";
import UsersTimeline from "./TimelineReports/UsersTimeline";
import RenderValue from "../Shared/RenderValue";

function TimelineReport(props) {
  console.log("TimelineReport", props);

  var data = props.history;

  // Store the searched text
  const [searchInput, setSearchInput] = useState("");

  // Store the
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

  // check the different types of
  const download_url = () => {
    if (props.history.meta.url) {
      return `/history_download/${props.history.meta.id}`;
    } else {
      return `/uploads/${data.meta.upload_id}/download_original`;
    }
  };

  return (
    <div className="table-overflow no-padding no-margin">
      <br />
      <Breadcrumbs>
        <Breadcrumb.Section>
          <a href="../timeline">Timeline</a>
        </Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>
          <div>{data.meta.action_type}</div>
        </Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      <Table celled unstackable striped>
        <Table.Header>
          <Table.Row textAlign="center">
            <Table.HeaderCell>Message:</Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>
          <Table.Row textAlign="center">
            <>
              <Table.Cell>{data.meta.message}</Table.Cell>
            </>
          </Table.Row>
        </Table.Body>
      </Table>

      <Table colums={1} celled unstackable striped>
        <Table.Header>
          <Table.Row textAlign="center">
            <Table.HeaderCell>Created:</Table.HeaderCell>
            <Table.HeaderCell>Submitted By:</Table.HeaderCell>
            <Table.HeaderCell>Download:</Table.HeaderCell>
            {props.history.meta.action_type === "Photo Index Upload (SL)" && (
              <Table.HeaderCell>Download Photo ID File:</Table.HeaderCell>
            )}
          </Table.Row>
        </Table.Header>

        <Table.Body>
          <Table.Row textAlign="center">
            <Table.Cell>
              <RenderValue value={data.meta.created_at} utc />
            </Table.Cell>

            <Table.Cell>
              <div>
                {" " +
                  data.meta.user.first_name +
                  " " +
                  data.meta.user.last_name}
              </div>
            </Table.Cell>

            <Table.Cell>
              <Button
                primary
                href={download_url()}
                target="_blank"
                style={{ color: "#fff", hover: "none", cursor: "pointer" }}
              >
                Download
              </Button>
            </Table.Cell>
            {props.history.meta.action_type === "Photo Index Upload (SL)" && (
              <Table.Cell>
                <Button
                  primary
                  href={`/photo_index/${data.meta.upload_id}/download`}
                  target="_blank"
                  style={{ color: "#fff", hover: "none", cursor: "pointer" }}
                >
                  Download
                </Button>
              </Table.Cell>
            )}
          </Table.Row>
        </Table.Body>
      </Table>
      {Object.keys(props).length > 1 && (
        <Fragment>
          <Divider />
          <Input
            icon="search"
            style={{ overflow: "auto", float: "right" }}
            placeholder="Search..."
            onChange={(e) => searchItems(e.target.value)}
          />
          <div style={{ clear: "both" }} />
        </Fragment>
      )}

      {typeof data.packing_slips !== "undefined" && (
        <PackingSlipsTimeline
          records={data.packing_slips}
          searchInput={searchInput}
        />
      )}
      {typeof data.tiles !== "undefined" && (
        <TileTimeline records={data.tiles} searchInput={searchInput} />
      )}

      {typeof data.doqqs !== "undefined" && (
        <DoqqTimeline records={data.doqqs} searchInput={searchInput} />
      )}

      {typeof data.easements !== "undefined" && (
        <EasementsTimeline
          records={data.easements}
          searchInput={searchInput}
        />
      )}

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

      {typeof data.photo_indices !== "undefined" && (
        <PhotoCenterTimeline
          records={data.photo_indices}
          searchInput={searchInput}
        />
      )}

      {typeof data.rejected_tiles !== "undefined" && (
        <RejectedTileTimeline
          records={data.rejected_tiles}
          searchInput={searchInput}
        />
      )}

      {typeof data.rejected_footprints !== "undefined" && (
        <RejectedFootprintsTimeline
          records={data.rejected_footprints}
          searchInput={searchInput}
        />
      )}

      {typeof data.rejected_frame_centers !== "undefined" && (
        <RejectedFrameTimeline
          records={data.rejected_frame_centers}
          searchInput={searchInput}
        />
      )}

      {typeof data.web_log_uploads !== "undefined" && (
        <WebLogTimeline
          records={data.web_log_uploads}
          searchInput={searchInput}
        />
      )}
      {typeof data.company_name !== "undefined" && (
        <CompanyTimeline
          records={data.company_name}
          searchInput={searchInput}
        />
      )}

      {typeof data.camera !== "undefined" && (
        <CameraTimeline records={data.camera} searchInput={searchInput} />
      )}
      {typeof data.planes !== "undefined" && (
        <PlaneTimeline records={data.planes} searchInput={searchInput} />
      )}
      {typeof data.users !== "undefined" && (
        <UsersTimeline
          records={data.users}
          setSearchInput={setSearchInput}
        />
      )}
      <br />
      <br />
    </div>
  );
}

export default TimelineReport;
