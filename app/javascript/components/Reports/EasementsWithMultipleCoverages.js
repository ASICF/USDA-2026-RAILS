import React, { useState, useEffect, Fragment } from "react";

import {
  List,
  Accordion,
  Header,
  Table,
  Input,
  Modal,
  Breadcrumb,
  Divider,
  Button,
  Icon,
  Grid,
  Checkbox,
  Message,
  Label,
  ButtonContent,
} from "semantic-ui-react";
import Breadcrumbs from "../Shared/Breadcrumb";
import { tableSortReducer } from "../Shared/TableSort";
import MessageBox from "../Shared/MessageBox";
import RenderValue from "../Shared/RenderValue";
import axios from "axios";

export default function EasementsWithMultipleCoverages({
  records,
  rejected,
  token,
}) {
  const [covered, setCovered] = useState(records);
  const [reject, setRejected] = useState(rejected);
  const [selected, setSelected] = useState(null);
  const [loading, setLoading] = useState(true);
  const [footprints, setFootprints] = useState(true);
  const [upload, setUpload] = useState(null);
  const [message, setMessage] = useState(null);
  const [submitted, setSubmitted] = useState(false);
  const [searchInput, setSearchInput] = useState("");

  // Flown Reducer
  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: covered,
    direction: null,
  });
  const { column, data, direction } = state;

  // Flown Reducer
  const [rejected_state, rejected_dispatch] = React.useReducer(
    tableSortReducer,
    {
      column: null,
      data: reject,
      direction: null,
    }
  );
  const {
    column: rejected_column,
    data: rejected_data,
    direction: rejected_direction,
  } = rejected_state;

  console.log("asdf", { records, rejected });

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

  // Filter the results when the
  useEffect(() => {
    let filteredRecords = [];
    let filteredRejected = [];

    // if the searchinput is empty then store the original records
    // => If there is text then filter it by the searchinput
    if (searchInput.length === "") {
      filteredRecords = records;
      filteredRejected = reject;
    } else {
      filteredRecords = records.filter((record) => {
        return Object.values(record)
          .join("")
          .toLowerCase()
          .includes(searchInput);
      });
      filteredRejected = reject.filter((record) => {
        console.error(Object.values(record));
        return Object.values(record)
          .join("")
          .toLowerCase()
          .includes(searchInput);
      });
    }

    console.log({
      filteredRecords,
      filteredRejected,
    });

    // update the data in the table
    dispatch({
      data: filteredRecords,
      type: "UPDATE_DATA",
      column,
      direction,
    });
    rejected_dispatch({
      data: filteredRejected,
      type: "UPDATE_DATA",
      rejected_column,
      rejected_direction,
    });
  }, [searchInput]);

  useEffect(() => {
    dispatch({ data: covered, type: "UPDATE_DATA", column, direction });
  }, [covered]);
  useEffect(() => {
    rejected_dispatch({ data: reject, type: "UPDATE_DATA", rejected_column, rejected_direction });
  }, [reject]);

  useEffect(() => {
    if (selected) {
      setLoading(true);
      setMessage(null);
      axios
        .post("/easements_with_multiple_coverages/query", {
          id: selected.id,
          authenticity_token: token,
        })
        .then((res) => {
          console.log(res);
          if (res.data.state) {
            setFootprints(res.data.result);
          } else {
            setMessage({
              title: "Error",
              text: res.data.message,
            });
          }
          setLoading(false);
        });
    } else {
      setFootprints([]);
    }
  }, [selected]);

  const submit = () => {
    console.log("submit", {
      tile_id: selected.id,
      upload_id: upload,
      authenticity_token: token,
    });
    setSubmitted(true);
    setLoading(true);
    axios
      .post("/easements_with_multiple_coverages/execute", {
        tile_id: selected.id,
        upload_id: upload,
        authenticity_token: token,
      })
      .then((res) => {
        console.log(res);
        setCovered(res.data.result);
        setRejected(res.data.rejected)
        setSelected(false);
        setLoading(false);
        setUpload(null);
      });
    setSubmitted(false);
    setLoading(false);
  };

  return (
    <div>
      {selected && footprints.length > 0 && (
        <Modal open={selected ? true : false} size="large">
          <Modal.Header>
            Select Footprint Upload to associate to Poly ID {selected.poly_id}
          </Modal.Header>
          <Modal.Content>
            {loading && (
              <Modal.Description style={{ textAlign: "center" }}>
                <Header as="h3" icon>
                  <Icon name="circle notched" loading />
                  Querying Overlapping Footprints...
                </Header>
              </Modal.Description>
            )}

            {!loading && footprints.length > 0 && (
              <RenderFootprints
                selected={selected}
                footprints={footprints}
                upload={upload}
                setUpload={setUpload}
              />
            )}
          </Modal.Content>
          <Modal.Actions>
            <Button secondary animated onClick={() => setSelected(null)}>
              <ButtonContent visible>Cancel</ButtonContent>
              <ButtonContent hidden>
                <Icon name="undo" />
              </ButtonContent>
            </Button>
            <Button
              disabled={(selected && upload) || submitted ? false : true}
              animated
              primary={true}
              onClick={() => submit()}
            >
              <ButtonContent visible>Associate Flight Date</ButtonContent>
              <ButtonContent hidden>
                <Icon name="arrow right" />
              </ButtonContent>
            </Button>
          </Modal.Actions>
        </Modal>
      )}

      <div style={{ display: "inline-block", marginTop: "15px" }}>
        <Breadcrumbs>
          <Breadcrumb.Section>Reports</Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section active>
            Easements with Multiple Coverages
          </Breadcrumb.Section>
        </Breadcrumbs>
      </div>

      <Input
        icon="search"
        style={{ float: "right" }}
        placeholder="Search..."
        onChange={(e) => searchItems(e.target.value)}
      />
      <div style={{ clear: "both" }} />

      <Divider />

      {message && <MessageBox title={message.title} message={message.text} />}

      {rejected_data.length === 0 && (
        <Message>No Rejected Tiles with Coverage</Message>
      )}
      {rejected_data.length > 0 && (
        <Table selectable unstackable sortable celled striped>
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                colSpan="100%"
                style={{
                  backgroundColor: "#ededed",
                  textAlign: "center",
                  cursor: "default",
                }}
              >
                <Header as="h4">Rejected Tiles with Coverage</Header>
              </Table.HeaderCell>
            </Table.Row>
            <Table.Row
              style={{ cursor: "pointer" }}
              onClick={() => {
                setSelected(record);
              }}
            >
              <Table.HeaderCell
                sorted={
                  rejected_column === "poly_id" ? rejected_direction : null
                }
                onClick={() =>
                  rejected_dispatch({ type: "CHANGE_SORT", column: "poly_id" })
                }
              >
                Poly ID
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={
                  rejected_column === "rejected_date"
                    ? rejected_direction
                    : null
                }
                onClick={() =>
                  rejected_dispatch({
                    type: "CHANGE_SORT",
                    column: "rejected_date",
                  })
                }
              >
                Rejected Flight Date
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={
                  rejected_column === "county_name" ? rejected_direction : null
                }
                onClick={() =>
                  rejected_dispatch({
                    type: "CHANGE_SORT",
                    column: "county_name",
                  })
                }
              >
                County Name
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={
                  rejected_column === "state_name" ? rejected_direction : null
                }
                onClick={() =>
                  rejected_dispatch({
                    type: "CHANGE_SORT",
                    column: "state_name",
                  })
                }
              >
                State Name
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {rejected_data.map((record) => {
              return (
                <Table.Row
                  style={{ cursor: "pointer" }}
                  key={record.id}
                  onClick={() => setSelected(record)}
                >
                  <Table.Cell>{record.poly_id}</Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.rejected_date} date />
                  </Table.Cell>
                  <Table.Cell>{record.county_name}</Table.Cell>
                  <Table.Cell>{record.state_name}</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
      )}

      {data.length === 0 && <Message>No Tiles marked as Covered</Message>}
      {data.length > 0 && (
        <Table selectable unstackable sortable celled striped>
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                colSpan="100%"
                style={{
                  backgroundColor: "#ededed",
                  textAlign: "center",
                  cursor: "default",
                }}
              >
                <Header as="h4">Easements with Multiple Coverages</Header>
              </Table.HeaderCell>
            </Table.Row>
            <Table.Row
              style={{ cursor: "pointer" }}
              onClick={() => {
                setSelected(record);
              }}
            >
              <Table.HeaderCell
                sorted={column === "poly_id" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "poly_id" })
                }
              >
                Poly ID
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "flight_date" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "flight_date" })
                }
              >
                Selected Flight Date
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "flown_by_alias" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "flown_by_alias" })
                }
              >
                Flown By
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "county_name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "county_name" })
                }
              >
                County Name
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "state_name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "state_name" })
                }
              >
                State Name
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {data.map((record) => {
              return (
                <Table.Row
                  style={{ cursor: "pointer" }}
                  key={record.id}
                  onClick={() => setSelected(record)}
                >
                  <Table.Cell>{record.poly_id}</Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.flight_date} date />
                  </Table.Cell>
                  <Table.Cell>{record.flown_by_alias}</Table.Cell>
                  <Table.Cell>{record.county_name}</Table.Cell>
                  <Table.Cell>{record.state_name}</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
      )}
      <br />
    </div>
  );
}

function RenderFootprints({ selected, footprints, upload, setUpload }) {
  const [activeIndex, setActiveIndex] = useState(0);
  // const [selectedIndex, setSelectedIndex] = useState(null);
  console.log("RenderFootprints", { footprints, upload });

  return (
    <Fragment>
      <Message>
        Select the appropriate Upload to associate to the selected Easement.
        Other Overlapping Footprints will be rejected.
      </Message>
      <Accordion styled fluid>
        {footprints.map((record, index) => {
          return (
            <Fragment key={index}>
              <Accordion.Title
                // style={{ background: "#eee" }}
                active={activeIndex === index}
                index={index}
                onClick={() => setActiveIndex(index)}
              >
                <Icon name="dropdown" />
                Flight Date: {moment(record.flight_date).format("l")}{" "}
                {record.flight_date === selected.flight_date ? (
                  <Label
                    size="small"
                    color="green"
                    style={{ marginLeft: "10px" }}
                  >
                    Associated
                  </Label>
                ) : null}
              </Accordion.Title>
              <Accordion.Content active={activeIndex === index}>
                <Grid stackable columns={2}>
                  <Grid.Column>
                    <Table basic="very" celled>
                      <Table.Body>
                        <Table.Row>
                          <Table.Cell>
                            <Header as="h4">Company</Header>
                          </Table.Cell>
                          <Table.Cell>{record.flown_by_name}</Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>
                            <Header as="h4">Plane</Header>
                          </Table.Cell>
                          <Table.Cell>{record.plane_name}</Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>
                            <Header as="h4">Camera</Header>
                          </Table.Cell>
                          <Table.Cell>{record.camera_name}</Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>
                            <Header as="h4">Upload ID</Header>
                          </Table.Cell>
                          <Table.Cell>{record.upload_id}</Table.Cell>
                        </Table.Row>
                        <Table.Row>
                          <Table.Cell>
                            <Header as="h4">Upload Date</Header>
                          </Table.Cell>
                          <Table.Cell>
                            {moment(record.upload_date).format("LLL")}
                          </Table.Cell>
                        </Table.Row>
                      </Table.Body>
                    </Table>
                  </Grid.Column>
                  <Grid.Column>
                    <Header as="h4">Footprints</Header>
                    <List bulleted>
                      {record.strip_frames.map((strip_frame, i) => {
                        return (
                          <List.Item key={i}>{strip_frame.value}</List.Item>
                        );
                      })}
                    </List>
                    {record.fp_rejection && (
                      <Message>
                        <Message.Header>Important</Message.Header>

                        <p>
                          One or more Footprints is associated to a Rejected
                          Tile of this selected Tile. Most likely this means
                          that this flight date should not be selected. When a
                          Tile is rejected if it's associated Footprints overlap
                          other Tiles they will not be rejected.
                        </p>
                      </Message>
                    )}
                  </Grid.Column>
                </Grid>
                <Divider />
                <Checkbox
                  checked={upload === record.upload_id}
                  onClick={(i, { checked }) => {
                    if (checked) {
                      // setSelectedIndex(index);
                      setUpload(record.upload_id);
                    } else {
                      // setSelectedIndex(null);
                      setUpload(null);
                    }
                  }}
                  label="Associate this Footprint Upload"
                />
              </Accordion.Content>
            </Fragment>
          );
        })}
      </Accordion>
    </Fragment>
  );
}
