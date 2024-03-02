import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Icon,
  Tab,
  Segment,
  Divider,
  Label,
  Breadcrumb,
  Form,
  Table,
  Header,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import axios from "axios";
import { tableSortReducer } from "../Shared/TableSort";

export default function ExportProvisionalVectorMetadata({
  projects,
  all_states,
  sl_states,
  naip_states,
  services,
  active,
  token,
}) {
  const [message, setMessage] = useState(null);
  const [states, setStates] = useState(sl_states);
  const [queryData, setQueryData] = useState({
    project: "NAIP",
    status: "Active",
    state_id: "All",
    flight_date: "",
  });
  const [executeData, setExecuteData] = useState(active);
  const [selected, setSelected] = useState(null);

  const handleQueryChange = (e, { name, value }) => {
    console.log(name, value);

    if (name === "project") {
      switch (value) {
        case "SL":
          setStates(sl_states);
          break;
        case "NAIP":
          setStates(naip_states);
          break;
        default:
          setStates(all_states);
      }
    }

    const record = { ...queryData };
    record[name] = value;
    setQueryData(record);
  };

  const handleQuerySubmit = () => {
    console.log("handleQuerySubmit");
    setSelected(null);

    axios
      .post("/query_provisional_export_vector_metadata", {
        project: queryData.project,
        status: queryData.status,
        flight_date: queryData.flight_date
          ? moment(queryData.flight_date, "l").format("YYYY-MM-DD")
          : null,
        state_id: queryData.state_id,
        authenticity_token: token,
      })
      .then((res) => {
        console.log(res.data);

        if (res.data.result.length > 0) {
          setMessage(null);
          setExecuteData(res.data.result);
        } else {
          setExecuteData(null);
          setMessage({
            title: "No Records Found",
            text: "Adjust the form parameters and try again",
          });
        }
      })
      .catch((err) => {
        console.error("Error Response", err);
        setMessage({
          status: "Error",
          title: "Error Processing request",
          text: "Please review required fields in form and resubmit",
        });
      });
  };

  const updateSelected = (record) => {
    setSelected(record);
  };

  console.log("ExportVectorMetadata", {
    // projects,
    // all_states,
    // sl_states,
    // naip_states,
    // states,
    // services,
    // queryData,
    // active,
    // executeData,
    selected,
  });

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Export</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Vector Metadata</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Provisional</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {queryForm()}
      {renderMessage()}
      <VectorMetadataList
        executeData={executeData}
        setSelected={setSelected}
        selected={selected}
        project={queryData.project}
      />
      <SelectedVectorMetadata
        selected={selected}
        setSelected={setSelected}
        handleQuerySubmit={handleQuerySubmit}
        token={token}
      />
    </div>
  );

  function renderMessage() {
    if (!message) return null;

    return (
      <MessageBox
        status={message.status}
        title={message.title}
        message={message.text}
      />
    );
  }

  function queryForm() {
    if (selected) return null;

    return (
      <Form>
        <Form.Group widths="equal">
          <Form.Select
            fluid
            search
            selection
            name={"project"}
            label={"Project"}
            required={true}
            value={queryData.project}
            onChange={handleQueryChange}
            autoComplete="off"
            options={projects.map((record) => {
              return {
                key: record,
                text: record,
                value: record,
              };
            })}
          />
          <Form.Select
            fluid
            search
            selection
            name={"status"}
            label={"Status"}
            required={true}
            value={queryData.status}
            onChange={handleQueryChange}
            autoComplete="off"
            options={["All", "Active", "Completed"].map((record) => {
              return {
                key: record,
                text: record,
                value: record,
              };
            })}
          />
          <Form.Field>
            <div className="calendar-input">
              <DateInput
                closable
                // required={true}
                clearable
                label={"Flight Date"}
                name="flight_date"
                placeholder="Date"
                iconPosition="left"
                dateFormat="MM/DD/YYYY"
                value={queryData.flight_date}
                onChange={handleQueryChange}
                autoComplete="off"
              />
            </div>
          </Form.Field>
          <Form.Select
            fluid
            search
            selection
            required={true}
            name={"state_id"}
            label={"State"}
            value={queryData.state_id}
            onChange={handleQueryChange}
            autoComplete="off"
            options={[{ id: "All", name: "All" }]
              .concat(states)
              .map((record) => {
                return {
                  key: record.id,
                  text: record.name,
                  value: record.id,
                };
              })}
          />
        </Form.Group>
        <Divider />
        <Button
          primary
          floated="right"
          onClick={handleQuerySubmit}
          disabled={
            queryData.status && queryData.project && queryData.state_id
              ? false
              : true
          }
        >
          Submit
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }
}

function VectorMetadataList({ project, executeData, setSelected, selected }) {
  if (!executeData || selected) return null;

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: executeData,
    direction: null,
  });
  const { column, data, direction } = state;

  useEffect(() => {
    dispatch({ data: executeData, type: "UPDATE_DATA", column, direction });
  }, [executeData]);

  if (executeData.length === 0) {
    return (
      <Fragment>
        <Divider />
        <MessageBox message={"No Records Found"} />
      </Fragment>
    );
  }

  console.log("VectorMetadataList", { project, executeData });

  return (
    <Fragment>
      <Divider />
      <Table textAlign="center" celled selectable sortable>
        <Table.Header>
          <Table.Row style={{ cursor: "pointer" }}>
            <Table.HeaderCell
              sorted={column === "project" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "project" })
              }
            >
              Project
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "state" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "state" })}
            >
              State
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "completed" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "completed" })
              }
            >
              Status
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "flight_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "flight_date" })
              }
            >
              Flight Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "count" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "count" })}
            >
              Footprint Uploaded
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "remaining" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "remaining" })
              }
            >
              Footprints Remaining
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "provisional_due_date" ? direction : null}
              onClick={() =>
                dispatch({
                  type: "CHANGE_SORT",
                  column: "provisional_due_date",
                })
              }
            >
              Provisional Due Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "provisional_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "provisional_date" })
              }
            >
              Provisional Completed Date
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {data.map((record) => {
            return (
              <Table.Row
                key={record.id}
                style={{ cursor: "pointer" }}
                onClick={() => setSelected(record)}
              >
                <Table.Cell>{record.project}</Table.Cell>
                <Table.Cell>{record.state_name}</Table.Cell>
                <Table.Cell>
                  {record.provisional_date ? (
                    <Label color="green" horizontal>
                      Completed
                    </Label>
                  ) : (
                    <Label color="red" horizontal>
                      Active
                    </Label>
                  )}
                </Table.Cell>
                <Table.Cell>
                  {moment(record.flight_date, "YYYY MM-DD").format(
                    "MM/DD/YYYY"
                  )}
                </Table.Cell>
                <Table.Cell>{record.count}</Table.Cell>
                <Table.Cell>{record.not_uploaded_count}</Table.Cell>
                <Table.Cell>
                  {moment(record.provisional_due_date, "YYYY MM-DD").format(
                    "MM/DD/YYYY"
                  )}
                </Table.Cell>
                <Table.Cell>
                  {record.provisional_date ? (
                    moment(record.provisional_date, "YYYY MM-DD").format(
                      "MM/DD/YYYY"
                    )
                  ) : (
                    <Label color="red" horizontal>
                      NA
                    </Label>
                  )}
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
      <br />
    </Fragment>
  );
}

function SelectedVectorMetadata({
  selected,
  setSelected,
  handleQuerySubmit,
  token,
}) {
  if (!selected) return null;

  const [loading, setLoading] = useState(false);
  const [footprints, setFootprints] = useState([]);
  const [imageryPaths, setImageryPaths] = useState([]);
  const [footprintsReady, setFootprintsReady] = useState(false);

  // Footprint Table Sorter
  const [footprintState, footprintDispatch] = React.useReducer(
    tableSortReducer,
    {
      column: null,
      data: footprints,
      direction: null,
    }
  );

  const {
    column: footprintColumn,
    data: footprintData,
    direction: footprintDirection,
  } = footprintState;

  useEffect(() => {
    if (footprints) {
      footprintDispatch({
        data: footprints,
        type: "UPDATE_DATA",
        footprintColumn,
        footprintDirection,
      });

      // Check if all the footprints have flight time and ready to be uploaded
      if (!selected.provisional_date) {
        var ready = true;
        footprints.forEach((record) => {
          if (!record.time) {
            ready = false;
            return false;
          }
        });
        setFootprintsReady(ready);
      }
    }
  }, [footprints]);

  // Imagery Table Sorter
  const [imageryState, imageryDispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: imageryPaths,
    direction: null,
  });
  const {
    column: imageryColumn,
    data: imageryData,
    direction: imageryDirection,
  } = imageryState;

  useEffect(() => {
    if (imageryPaths) {
      imageryDispatch({
        data: imageryPaths,
        type: "UPDATE_DATA",
        imageryColumn,
        imageryDirection,
      });
    }
  }, [imageryPaths]);

  // Query the footprints and imagery paths on load, set upload date to today
  useEffect(() => {
    console.error(selected);
    if (!selected.provisional_date) {
      setValue("upload_date", moment().format("MM/DD/YYYY"));
      // setValue(
      //   "input_directory",
      //   "P:\\Vol_3\\226567_04_SL_GA\\03_FrameBase\\Ortho_Raw"
      // );
    }

    queryRelated();
  }, [selected]);

  const queryRelated = () => {
    axios
      .post("/query_imagery_paths_provisional_export_vector_metadata", {
        id: selected.id,
        authenticity_token: token,
      })
      .then((res) => {
        console.log(res);
        setFootprints(res.data.result.footprints);
        setImageryPaths(res.data.result.imagery_paths);
      });
  };

  const {
    handleSubmit,
    setValue,
    control,
    formState: { errors },
  } = useForm();

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const resetSelected = () => {
    handleQuerySubmit();
    setSelected(null);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);

    setLoading(true);

    axios
      .post("/execute_export_provisional_vector_metadata", {
        id: selected.id,
        input_directory: data.input_directory,
        upload_date: moment(data.upload_date, "l").format("YYYY-MM-DD"),
        authenticity_token: token,
      })
      .then((res) => {
        console.log(res);

        if (res.data.state) {
          // update the selected variable
          if (res.data.record) {
            setSelected(res.data.record);
          }
        }

        setLoading(false);
      });
  };

  console.log("SelectedVectorMetadata", {
    selected,
    footprints,
    imageryPaths,
  });

  if (loading) {
    return (
      <Segment placeholder>
        <Header icon>
          <Icon loading name="circle notch" />
          Updating Footprints and Building Shapefile...
        </Header>
      </Segment>
    );
  }

  return (
    <div>
      <Button
        icon
        labelPosition="left"
        floated="left"
        size="tiny"
        onClick={resetSelected}
        style={{ marginBottom: "5px" }}
      >
        <Icon name="angle left" />
        Return to List
      </Button>
      <Divider clearing />
      {!selected.provisional_date && footprintsReady && (
        <Form>
          <Form.Group widths="equal">
            <Controller
              name={"input_directory"}
              control={control}
              rules={{ required: "Required" }}
              render={({ field: { name, onBlur, onChange, value } }) => (
                <Form.Input
                  fluid
                  label={"Path to Root Folder of Images (Within P:\\Vol_3)"}
                  autoComplete="off"
                  name={name}
                  required={true}
                  onBlur={onBlur}
                  onChange={onChange}
                  value={value || ""}
                  error={
                    errors["serial_number"] && errors["serial_number"].message
                  }
                />
              )}
            />
            <Form.Field error={errors.hasOwnProperty("flight_date")}>
              <div className="calendar-input">
                <Controller
                  name={"upload_date"}
                  control={control}
                  rules={{
                    required: "Required",
                  }}
                  render={({ field: { name, value } }) => (
                    <DateInput
                      closable
                      clearable
                      name={name}
                      label={"Upload Date"}
                      required={true}
                      value={value || ""}
                      dateFormat="MM/DD/YYYY"
                      iconPosition="left"
                      onChange={handleChange}
                      autoComplete="off"
                    />
                  )}
                />
              </div>
              {errors[`upload_date`] && (
                <Label pointing prompt>
                  {errors[`upload_date`].message}
                </Label>
              )}
            </Form.Field>
          </Form.Group>
          <Divider />
          <Button primary floated="right" onClick={handleSubmit(onSubmit)}>
            Submit
          </Button>
          <Button secondary floated="right" onClick={resetSelected}>
            Cancel
          </Button>
          <div style={{ clear: "both" }} />
        </Form>
      )}

      {!selected.provisional_date && !footprintsReady && (
        <MessageBox
          title={"Provisional Footprints are not ready to be Uploaded"}
          message={
            "All Footprints associated to the Vector Metadatum must have valid Flight Date Times that are derived from the EO (Frame Centers). Review the list in the Foootprint tab below to see which Footprints are missing Flight Time values."
          }
        />
      )}

      <Segment>
        <Table textAlign="center" basic="very" celled>
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell>Project</Table.HeaderCell>
              <Table.HeaderCell>State</Table.HeaderCell>
              <Table.HeaderCell>Flight Date</Table.HeaderCell>
              <Table.HeaderCell>Total Footprints</Table.HeaderCell>
              <Table.HeaderCell>Remaining Footprints</Table.HeaderCell>
              <Table.HeaderCell>Due Date</Table.HeaderCell>
              {selected.shapefile_path && (
                <Table.HeaderCell>Download Shapefile</Table.HeaderCell>
              )}
            </Table.Row>
          </Table.Header>
          <Table.Body>
            <Table.Row>
              <Table.Cell>{selected.project}</Table.Cell>
              <Table.Cell>{selected.state_name}</Table.Cell>
              <Table.Cell>
                {moment(selected.flight_date, "YYYY MM-DD").format(
                  "MM/DD/YYYY"
                )}
              </Table.Cell>
              <Table.Cell>{selected.count}</Table.Cell>
              <Table.Cell>{selected.not_uploaded_count}</Table.Cell>

              <Table.Cell>
                {moment(selected.provisional_due_date, "YYYY MM-DD").format(
                  "MM/DD/YYYY"
                )}
              </Table.Cell>
              {selected.shapefile_path && (
                <Table.Cell>
                  <Button
                    secondary
                    href={`download_provisional_vector_metadata/${selected.id}`}
                    target="_blank"
                  >
                    Download
                  </Button>
                </Table.Cell>
              )}
            </Table.Row>
          </Table.Body>
        </Table>

        <Divider />
        <Tab
          menu={{ borderless: true, secondary: true, pointing: true }}
          panes={[
            {
              menuItem: "Footprints",
              render: () => renderFootprints(),
            },
            {
              menuItem: "Imported Paths",
              render: () => renderImportPaths(),
            },
          ]}
        />
      </Segment>
      <br />
      <br />
    </div>
  );

  function renderFootprints() {
    if (footprintData.length === 0) {
      return (
        <Tab.Pane loading={!footprintData}>No Associated Footprints</Tab.Pane>
      );
    }

    return (
      <Table textAlign="center" celled sortable>
        <Table.Header>
          <Table.Row style={{ cursor: "pointer" }}>
            <Table.HeaderCell
              sorted={
                footprintColumn === "strip_frame" ? footprintDirection : null
              }
              onClick={() =>
                footprintDispatch({
                  type: "CHANGE_SORT",
                  footprintColumn: "strip_frame",
                })
              }
            >
              Strip Frame
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={footprintColumn === "time" ? footprintDirection : null}
              onClick={() =>
                footprintDispatch({
                  type: "CHANGE_SORT",
                  footprintColumn: "time",
                })
              }
            >
              Flight Time
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={
                footprintColumn === "imagery_path" ? footprintDirection : null
              }
              onClick={() =>
                footprintDispatch({
                  type: "CHANGE_SORT",
                  footprintColumn: "imagery_path",
                })
              }
            >
              Full Path
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={
                footprintColumn === "imagery_path" ? footprintDirection : null
              }
              onClick={() =>
                footprintDispatch({
                  type: "CHANGE_SORT",
                  footprintColumn: "imagery_path",
                })
              }
            >
              Imported Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={footprintColumn === "user" ? footprintDirection : null}
              onClick={() =>
                footprintDispatch({
                  type: "CHANGE_SORT",
                  footprintColumn: "user",
                })
              }
            >
              User
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {footprintData.map((record) => {
            return (
              <Table.Row key={record.id}>
                <Table.Cell>{record.strip_frame}</Table.Cell>
                <Table.Cell>
                  {record.time ? (
                    moment.utc(record.time).format("HH:mm")
                  ) : (
                    <Label color="red" horizontal>
                      NA
                    </Label>
                  )}
                </Table.Cell>
                <Table.Cell>
                  {record.path ? (
                    record.path
                  ) : (
                    <Label color="red" horizontal>
                      NA
                    </Label>
                  )}
                </Table.Cell>
                <Table.Cell>
                  {record.created_at ? (
                    moment(record.created_at, "YYYY MM-DD").format("MM/DD/YYYY")
                  ) : (
                    <Label color="red" horizontal>
                      NA
                    </Label>
                  )}
                </Table.Cell>
                <Table.Cell>
                  {record.user ? (
                    record.user
                  ) : (
                    <Label color="red" horizontal>
                      NA
                    </Label>
                  )}
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    );
  }
  function renderImportPaths() {
    if (imageryData.length === 0) {
      return (
        <Tab.Pane loading={!imageryData}>
          No Previously Imported Directories
        </Tab.Pane>
      );
    }

    return (
      <Table textAlign="center" celled sortable>
        <Table.Header>
          <Table.Row style={{ cursor: "pointer" }}>
            <Table.HeaderCell
              sorted={
                imageryColumn === "imagery_path" ? imageryDirection : null
              }
              onClick={() =>
                imageryDispatch({
                  type: "CHANGE_SORT",
                  imageryColumn: "imagery_path",
                })
              }
            >
              Upload Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={imageryColumn === "user" ? imageryDirection : null}
              onClick={() =>
                imageryDispatch({
                  type: "CHANGE_SORT",
                  imageryColumn: "user",
                })
              }
            >
              User
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={
                imageryColumn === "imagery_path" ? imageryDirection : null
              }
              onClick={() =>
                imageryDispatch({
                  type: "CHANGE_SORT",
                  imageryColumn: "imagery_path",
                })
              }
            >
              Full Path
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>
        <Table.Body>
          {imageryData.map((record) => {
            return (
              <Table.Row key={record.id}>
                <Table.Cell>
                  {moment(record.created_at, "YYYY MM-DD").format("MM/DD/YYYY")}
                </Table.Cell>
                <Table.Cell>{record.user}</Table.Cell>
                <Table.Cell>{record.path}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    );
  }
}
