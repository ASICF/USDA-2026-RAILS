import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Grid,
  Header,
  Label,
  Accordion,
  Divider,
  Form,
  Breadcrumb,
  Table,
  Tab,
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";

export default function ImageryUploadStatus({
  vector_metadatas,
  projects,
  services,
  date_to,
  date_from,
  token,
}) {
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  console.log("ImageryUploadStatus", {
    vector_metadatas,
    projects,
    services,
    date_to,
    date_from,
    token,
    results,
  });

  // Testing
  // useEffect(() => {
  //   onSubmit({ project: "SL", date_from: "01/01/2022", date_to: "07/01/2022" });
  // }, []);

  const resetForm = () => {
    reset({
      project: "",
      date_from: date_from,
      date_to: date_to,
    });
  };

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setLoading(true)
    setSubmitted(true)

    axios
      .post(`/imagery_upload_status/query`, {
        authenticity_token: token,
        project: data.project,
        date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
        date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setLoading(false)
        setSubmitted(false)
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });
        // Reset form if successful
        if (data.state) {
          setResults(data.results);

          // setTimeout(() => {
          //   resetForm();
          // }, 500);
        } else {
          setResults(null);
        }
        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        window.onbeforeunload = null;
      });
  };

  const onExport = (data) => {
    console.error("onExport", data);

    window.open(
      `/imagery_upload_status/download?${new URLSearchParams({
        project: data.project,
        date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
        date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      }).toString()}`,
      "_blank"
    );
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Imagery Upload Status</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {/* {renderHelp()} */}
      {/* <Divider /> */}
      {renderMessage()}
      {renderForm()}
      {!results && <RenderSummary records={vector_metadatas} />}
      {<RenderTable results={results} />}
      <br />
      <br />
    </div>
  );

  //   function renderHelp() {
  //     return (
  //       <Accordion styled fluid>
  //         <Accordion.Title
  //           active={accordionState}
  //           onClick={() => {
  //             setAccordionState(!accordionState);
  //           }}
  //         >
  //           <Icon name="dropdown" />
  //           Tool Help
  //         </Accordion.Title>
  //         <Accordion.Content active={accordionState}>
  //           <Header as="h4">Summary</Header>
  //           <p>Imports the DOQQs via Shapefile</p>
  //           <Divider />
  //           <Grid divided="vertically">
  //             <Grid.Row columns={2}>
  //               <Grid.Column>
  //                 <Header as="h5">Inputs</Header>
  //                 <List bulleted>
  //                   <List.Item>
  //                     A <b>single shapefile</b> that contains a{" "}
  //                     <b>.shp, .shx, .dbf, and .prj</b> files
  //                   </List.Item>
  //                 </List>
  //               </Grid.Column>
  //               <Grid.Column>
  //                 <Header as="h5">Process</Header>
  //                 <List bulleted>
  //                   <List.Item>
  //                     The associationed County, State, and UTM will be verified
  //                     and calculated
  //                   </List.Item>
  //                 </List>
  //               </Grid.Column>
  //             </Grid.Row>
  //           </Grid>
  //         </Accordion.Content>
  //       </Accordion>
  //     );
  //   }

  function RenderSummary({ records }) {
    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: records,
      direction: null,
    });
    const { column, data, direction } = state;

    return (
      <Fragment>
        <Divider />
        <Table sortable celled textAlign="center">
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                sorted={column === "state_name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "state_name" })
                }
              >
                State Name
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
                sorted={column === "provisional_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "provisional_count" })
                }
              >
                Provisional Count
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "provisional_date" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "provisional_date" })
                }
              >
                Provisional Upload Date
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
                sorted={column === "production_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "production_count" })
                }
              >
                Production Count
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "production_upload_date" ? direction : null}
                onClick={() =>
                  dispatch({
                    type: "CHANGE_SORT",
                    column: "production_upload_date",
                  })
                }
              >
                Production Upload Date
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {data.map((record, index) => {
              return (
                <Table.Row key={index}>
                  <Table.Cell>{record.state_name}</Table.Cell>
                  <Table.Cell>{record.flight_date}</Table.Cell>
                  <Table.Cell>{record.provisional_count}</Table.Cell>
                  <Table.Cell>{record.provisional_date}</Table.Cell>
                  <Table.Cell>{record.provisional_due_date}</Table.Cell>
                  <Table.Cell>{record.production_count}</Table.Cell>
                  <Table.Cell>{record.production_upload_date}</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>
      </Fragment>
    );
  }

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

  function renderForm() {
    if (message && message.status === "loading") return null;

    return (
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                data-value={value}
                label={"Project"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                  };
                })}
                error={
                  errors["project"]
                    ? {
                        content: errors["project"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
          <Form.Field error={errors.hasOwnProperty("date_from")}>
            <div className="calendar-input">
              <Controller
                name={"date_from"}
                control={control}
                rules={{
                  required: "Required",
                }}
                defaultValue={date_from}
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Upload Date From"}
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
            {errors[`date_from`] && (
              <Label pointing prompt>
                {errors[`date_from`].message}
              </Label>
            )}
          </Form.Field>
          <Form.Field error={errors.hasOwnProperty("date_to")}>
            <div className="calendar-input">
              <Controller
                name={"date_to"}
                control={control}
                rules={{
                  required: "Required",
                }}
                defaultValue={date_to}
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Upload Date To"}
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
            {errors[`date_to`] && (
              <Label pointing prompt>
                {errors[`date_to`].message}
              </Label>
            )}
          </Form.Field>
        </Form.Group>
        <Divider />
        <Button.Group floated="right">
          <Button primary 
          loading={submitted}
          disabled={submitted}
          onClick={handleSubmit(onSubmit)}>
            Submit
          </Button>
          <Button.Or />
          <Button onClick={handleSubmit(onExport)}>Export</Button>
        </Button.Group>
        {/* <Button
          primary
          floated="right"
          type="button"
          onClick={handleSubmit(onExport)}
        >
          Export
        </Button>
        <Button
          primary
          floated="right"
          type="button"
          onClick={handleSubmit(onSubmit)}
        >
          Submit
        </Button> */}
        <Button
          secondary
          floated="right"
          type="button"
          style={{ marginRight: "0.5em" }}
          onClick={() => resetForm()}
        >
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }

  function RenderTable({ results }) {
    if (!results) return null;

    console.log("asdf", results);

    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: results,
      direction: null,
    });
    const { column, data, direction } = state;

    if (results.length === 0) {
      return (
        <MessageBox
          title={"No Records Found"}
          message={"Query returned no records"}
        />
      );
    }

    return (
      <Table sortable celled textAlign="center">
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "type" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "type" })}
            >
              EAWS Type
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "exposure_id" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "exposure_id" })
              }
            >
              Exposure ID
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "service_name" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "service_name" })
              }
            >
              Service Name
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
              sorted={column === "upload_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "upload_date" })
              }
            >
              Upload Date
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "due_date" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "due_date" })
              }
            >
              Due Date
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>
          {data.map((record, index) => {
            return (
              <Table.Row key={index}>
                <Table.Cell>{record.type}</Table.Cell>
                <Table.Cell>{record.exposure_id}</Table.Cell>
                <Table.Cell>{record.service_name}</Table.Cell>
                <Table.Cell>{record.flight_date}</Table.Cell>
                <Table.Cell>{record.upload_date}</Table.Cell>
                <Table.Cell>{record.due_date}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    );
  }
}
