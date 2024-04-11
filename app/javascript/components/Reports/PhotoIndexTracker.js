import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Header,
  List,
  Message,
  Divider,
  Segment,
  Breadcrumb,
  Grid,
  Icon,
  Table,
  Modal,
  ButtonContent,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { tableSortReducer } from "../Shared/TableSort";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

export default function PhotoIndexTracker({ uploads, token }) {
  const [upload, setUpload] = useState(null);

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: uploads,
    direction: null,
  });
  const { column, data, direction } = state;

  console.log("Photo Index Tracker", { data, upload });

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Photo Index Tracker</Breadcrumb.Section>
      </Breadcrumbs>

      <Divider />

      {renderTable()}
      <RenderUpload upload={upload} setUpload={setUpload} token={token} />
      {renderMessage()}
    </div>
  );

  function renderMessage() {
    if (data.length > 0) return null;

    return (
      <MessageBox
        status={"Success"}
        title={"No delayed Photo Index files found"}
        message={
          "Any Footprints that have been uploaded and have not received any Photo Index files will appear on this list. No Footprints currently meet this requirement."
        }
      />
    );
  }

  function renderTable() {
    if (data.length === 0) return null;

    return (
      <Fragment>
        <Table celled selectable sortable textAlign="center">
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                rowSpan="2"
                sorted={column === "flown_by" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "flown_by" })
                }
              >
                Flown By
              </Table.HeaderCell>
              <Table.HeaderCell
                rowSpan="2"
                sorted={column === "state_name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "state_name" })
                }
              >
                State
              </Table.HeaderCell>
              <Table.HeaderCell
                rowSpan="2"
                sorted={column === "project" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "project" })
                }
              >
                Project
              </Table.HeaderCell>
              <Table.HeaderCell
                rowSpan="2"
                sorted={column === "flight_date" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "flight_date" })
                }
              >
                Flight Date
              </Table.HeaderCell>
              <Table.HeaderCell
                rowSpan="2"
                sorted={column === "time_offset" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "time_offset" })
                }
              >
                Days Since Flight
              </Table.HeaderCell>
              <Table.HeaderCell
                rowSpan="2"
                sorted={column === "upload_created_at" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "upload_created_at" })
                }
              >
                Upload Date
              </Table.HeaderCell>
              <Table.HeaderCell
                rowSpan="2"
                sorted={column === "plane" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "plane" })
                }
              >
                Plane
              </Table.HeaderCell>
              <Table.HeaderCell
                rowSpan="2"
                sorted={column === "camera" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "camera" })
                }
              >
                Camera
              </Table.HeaderCell>
              <Table.HeaderCell
                colSpan="3"
                style={{
                  cursor: "default",
                }}
              >
                Footprints
              </Table.HeaderCell>
            </Table.Row>
            <Table.Row>
              <Table.HeaderCell
                sorted={
                  column === "footprints_that_need_pis" ? direction : null
                }
                onClick={() =>
                  dispatch({
                    type: "CHANGE_SORT",
                    column: "footprints_that_need_pis",
                  })
                }
              >
                Missing PIs
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "footprints_with_pis" ? direction : null}
                onClick={() =>
                  dispatch({
                    type: "CHANGE_SORT",
                    column: "footprints_with_pis",
                  })
                }
              >
                Have PIs
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "total_footprints" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "total_footprints" })
                }
              >
                Total
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            {data.map((record) => {
              return (
                <Table.Row
                  key={record.upload_id}
                  onClick={() => {
                    setUpload(record);
                  }}
                  style={{ cursor: "pointer" }}
                >
                  <Table.Cell>{record.flown_by}</Table.Cell>
                  <Table.Cell>{record.state_name}</Table.Cell>
                  <Table.Cell>{record.project}</Table.Cell>
                  <Table.Cell>
                    {moment(record.flight_date, "YYYY MM-DD").format(
                      "MM/DD/YYYY"
                    )}
                  </Table.Cell>
                  <Table.Cell>{record.time_offset}</Table.Cell>
                  <Table.Cell>
                    {moment(record.upload_created_at, "YYYY MM-DD").format(
                      "MM/DD/YYYY"
                    )}
                  </Table.Cell>
                  <Table.Cell>{record.plane}</Table.Cell>
                  <Table.Cell>{record.camera}</Table.Cell>
                  <Table.Cell>{record.footprints_that_need_pis}</Table.Cell>
                  <Table.Cell>{record.footprints_with_pis}</Table.Cell>
                  <Table.Cell>{record.total_footprints}</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
        <br />
      </Fragment>
    );
  }

  function RenderUpload({ upload, setUpload, token }) {
    const [records, setRecords] = useState(null);
    const [stripFrames, setStripFrames] = useState(null);
    const [message, setMessage] = useState(null);

    console.error({ records, stripFrames, message });

    if (!upload) return null;

    useEffect(() => {
      axios
        .post("/query_photo_index_tracker", {
          upload_id: upload.upload_id,
          authenticity_token: token,
        })
        .then((res) => {
          console.log("query_photo_index_tracker", res);
          if (res.data.strip_frames.length) {
            setStripFrames(res.data.strip_frames);
          } else {
            setStripFrames([]);
          }

          if (res.data.poly_ids.length) {
            setRecords(res.data.poly_ids);
          } else {
            setRecords([]);
          }
        })
        .catch((err) => {
          console.error("Error Response", err);
          setRecords([]);
          setMessage({
            status: "Error",
            title: "Error Processing request",
            text: "Please review required fields in form and resubmit",
          });
        });
    }, []);

    const handleEmail = () => {
      let html = `
  Company: ${upload.flown_by}%0D%0A
  Flight Date: ${moment(upload.flight_date, "YYYY MM-DD").format(
    "MM/DD/YYYY"
  )}%0D%0A
  Camera: ${upload.camera}%0D%0A
  Plane: ${upload.plane}%0D%0A%0D%0A
  The following sites are still awaiting the matching Photo Index file.%0D%0A`;

      records.forEach((item) => {
        html += `- ${item.poly_id} (${item.project})%0D%0A`;
      });

      window.open(
        `mailto:?subject=Missing%20Photo%20Index%20Files%20for%20Flight%20Date%20${moment(
          upload.upload_created_at,
          "YYYY MM-DD"
        ).format("MM/DD/YYYY")}&body=${html}`,
        "_blank"
      );
    };

    const exportShapefile = () => {
      console.error("exportShapefile", upload, stripFrames);

      setMessage(null);

      // Build the shapefile
      axios
        .post(`/photo_index_tracker/generate`, {
          authenticity_token: token,
          upload_id: upload.upload_id,
          strip_frames: stripFrames,
        })
        .then(({ data }) => {
          console.log("submit response", data);

          if (data.state) {
            window.open(`/photo_index_tracker/download/${data.history_id}`, "_blank");
          } else {
            console.error(data);
            setMessage({
              status: "Error",
              text: data.message,
            });
          }
        })
        .catch((err) => {
          console.log(err);
          setMessage({
            status: "Error",
            text: err,
          });
          window.onbeforeunload = null;
        });

      // window.open(
      //   `/imagery_upload_status/download?${new URLSearchParams({
      //     project: "SL",
      //     date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
      //     date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      //   }).toString()}`,
      //   "_blank"
      // );
    };

    // console.log("RenderUpload", { records, stripFrames });

    return (
      <Modal
        open={upload ? true : false}
        onClose={() => {
          setUpload(null);
        }}
        closeOnDocumentClick={true}
      >
        <Modal.Header>
          {`Upload ID: ${upload.upload_id}`}

          <Button.Group floated="right">
            {records && records.length > 0 && records.length <= 30 && (
              <Button onClick={handleEmail}>Email</Button>
            )}
          </Button.Group>
        </Modal.Header>
        <Modal.Content>
          <Modal.Description>
            {message && (
              <MessageBox
                status={message.status ? message.status : "notice"}
                title={message.title}
                message={message.text}
              />
            )}

            {records && (records.length > 0 || stripFrames.length > 0) && (
              <Fragment>
                <p>
                  <b>Company</b>: {upload.flown_by}
                  <br />
                  <b>State</b>: {upload.state_name}
                  <br />
                  <b>Flight Date</b>:{" "}
                  {moment(upload.flight_date, "YYYY MM-DD").format(
                    "MM/DD/YYYY"
                  )}
                  <br />
                  <b>Camera</b>: {upload.camera}
                  <br />
                  <b>Plane</b>: {upload.plane}
                  <br />
                </p>
              </Fragment>
            )}

            {records && records.length === 0 && (
              <MessageBox
                title={"No Easements Found"}
                message={
                  "No flown Easements were found that are associated with footprints that have no Frame Centers."
                }
              />
            )}
            {records && stripFrames.length === 0 && (
              <MessageBox
                title={"No Footprints Found"}
                message={"No Footprints were found."}
              />
            )}

            {!records && (
              <MessageBox
                status="loading"
                title={"Loading"}
                message={
                  "Querying associated Footprints and Easements from Upload"
                }
              />
            )}

            {records && records.length > 0 && (
              <Fragment>
                <p>
                  The following Easements are still awaiting the matching Photo Index
                  file.
                </p>
                <ul>
                  {records.map((item, index) => {
                    return (
                      <li key={index}>
                        {item.poly_id} ({item.project})
                      </li>
                    );
                  })}
                </ul>
              </Fragment>
            )}

            {records && stripFrames.length > 0 && (
              <Fragment>
                <p>
                  The following Strip Frames are from Footprints are missing a
                  Frame Center
                </p>
                <ul>
                  {stripFrames.map((item, index) => {
                    return <li key={index}>{item}</li>;
                  })}
                </ul>
              </Fragment>
            )}
          </Modal.Description>
        </Modal.Content>
        <Modal.Actions>
          <Button
            animated="fade"
            as="a"
            floated="left"
            onClick={() => exportShapefile()}
          >
            <ButtonContent visible>Export</ButtonContent>
            <ButtonContent hidden>
              <Icon name="download" />
            </ButtonContent>
          </Button>

          <Button
            animated="fade"
            as="a"
            target="_blank"
            href={`/timeline/${upload.history_id}`}
          >
            <ButtonContent visible>View Upload</ButtonContent>
            <ButtonContent hidden>
              <Icon name="external" />
            </ButtonContent>
          </Button>

          <Button secondary animated="fade" onClick={() => setUpload(null)}>
            <ButtonContent visible>Close Modal</ButtonContent>
            <ButtonContent hidden>
              <Icon name="window close" />
            </ButtonContent>
          </Button>
        </Modal.Actions>
      </Modal>
    );
  }
}
