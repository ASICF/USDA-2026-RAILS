import React, { useState, useEffect, Fragment } from "react";

import {
  Button,
  Label,
  Divider,
  Form,
  Breadcrumb,
  Table,
  Accordion,
  Icon,
  Grid,
  List,
  Header,
  ButtonContent
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

export default function TileDumpCompare({ projects, states, token }) {
  const [result, setResult] = useState(null);
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const {
    handleSubmit,
    reset,
    register,
    setValue,
    getValues,
    control,
    formState: { errors },
  } = useForm();

  const resetForm = () => {
    reset({
      project: "",
      state_id: "",
      file: "",
    });
  };

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);
    setLoading(true)
    const form = new FormData();

    form.append("authenticity_token", token);
    form.append("tile_dump_compare[project]", data.project_id);
    form.append("tile_dump_compare[state_id]", data.state_id);
    form.append("tile_dump_compare[file]", data.file[0]);

    setMessage({
      status: "loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    window.onbeforeunload = () => {
      return "Leaving may interrupt the import process. Please wait til the operation is complete";
    };

    axios
      .post(`/tile_dump_compare/execute`, form, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setSubmitted(true);
        setLoading(false)
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });
        // Reset form if successful
        if (data.state) {
          setResult(data.records);
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

  console.log("TileDumpCompare", { projects, states });

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Tile Dump Compare</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderHelp()}
      <Divider />
      {renderMessage()}
      {renderForm()}
      <RenderTable result={result} />
    </div>
  );

  function renderHelp() {
    return (
      <Accordion styled fluid>
        <Accordion.Title
          active={accordionState}
          onClick={() => {
            setAccordionState(!accordionState);
          }}
        >
          <Icon name="dropdown" />
          Tool Help
        </Accordion.Title>
        <Accordion.Content active={accordionState}>
          <Header as="h4">Summary</Header>
          <p>
            Accepts a text file consisting of the filenames in a folder and
            returns the missing Tiles within that state
          </p>
          <Divider />
          <Grid divided="vertically">
            <Grid.Row columns={2}>
              <Grid.Column>
                <Header as="h5">Inputs</Header>
                <List bulleted>
                  <List.Item>
                    A Text file of Filenames with or without the ".tif" suffix
                  </List.Item>
                  <List.Item>The State to filter by</List.Item>
                  <List.Item>The Project to filter by</List.Item>
                </List>
              </Grid.Column>
              <Grid.Column>
                <Header as="h5">Output</Header>
                <List bulleted>
                  <List.Item>
                    List of Tiles that are not within the txt file including
                    their statuses, scoped by that State and Project
                  </List.Item>
                </List>
              </Grid.Column>
            </Grid.Row>
          </Grid>
        </Accordion.Content>
      </Accordion>
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
    return (
      <Form>
        <Form.Group widths="equal">
          <Form.Field
            required
            error={errors.hasOwnProperty("file")}
            style={{ margin: "0" }}
          >
            <label>Text File of Filenames on a new Line (.txt file)</label>
            <input
              {...register("file", { required: "Required" })}
              name="file"
              type="file"
            />
            {errors[`file`] && (
              <Label pointing prompt>
                {errors[`file`].message}
              </Label>
            )}
          </Form.Field>

          <Controller
            name={"state_id"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                label={"State"}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={states.map((record) => {
                  return {
                    key: record.id,
                    text: record.name,
                    value: record.id,
                  };
                })}
                error={
                  errors["state_id"]
                    ? {
                        content: errors["state_id"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
          <Controller
            name={"project_id"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                label={"Project"}
                value={value || ""}
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
                  errors["project_id"]
                    ? {
                        content: errors["project_id"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>

        <Divider />

        <Button
          primary
          floated="right"
          type="button"
          loading={submitted}
        disabled={submitted}
          onClick={handleSubmit(onSubmit)}
        >
           <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
          <Icon name='arrow right' />
          </ButtonContent>
        </Button>
        <Button secondary floated="right" type="button" onClick={() => reset()}>
        <ButtonContent visible>Reset</ButtonContent>
          <ButtonContent hidden>
          <Icon name="undo" />
          </ButtonContent>
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }

  function RenderTable({ records }) {
    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: result || [],
      direction: null,
    });
    const { column, data, direction } = state;

    if (data.length == 0) return null;

    return (
      <Fragment>
        <Table celled sortable>
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                sorted={column === "poly_id" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "poly_id" })
                }
              >
                Poly ID
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "filename" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "filename" })
                }
              >
                Filename
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "county_name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "county_name" })
                }
              >
                County
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
                sorted={column === "at_start_date" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "at_start_date" })
                }
              >
                AT Start/Done Date
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "ortho_proc_date" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "ortho_proc_date" })
                }
              >
                Ortho Proc Date
              </Table.HeaderCell>

              <Table.HeaderCell
                sorted={column === "ship_date" ? direction : null}
                onClick={() =>
                  dispatch({
                    type: "CHANGE_SORT",
                    column: "ship_date",
                  })
                }
              >
                Ship Date
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            {data.map((record) => {
              return (
                <Table.Row key={record.id}>
                  <Table.Cell>{record.poly_id}</Table.Cell>
                  <Table.Cell>{record.filename ? record.filename : "NA"}</Table.Cell>
                  <Table.Cell>{record.county_name}</Table.Cell>
                  <Table.Cell>
                    {record.flight_date
                      ? moment(record.flight_date, "YYYY MM-DD").format(
                          "MM/DD/YYYY"
                        )
                      : "NA"}
                  </Table.Cell>
                  <Table.Cell>
                    {record.at_done_date
                      ? moment(record.at_done_date, "YYYY MM-DD").format(
                          "MM/DD/YYYY"
                        )
                      : "NA"}
                  </Table.Cell>
                  <Table.Cell>
                    {record.ortho_proc_date
                      ? moment(record.ortho_proc_date, "YYYY MM-DD").format(
                          "MM/DD/YYYY"
                        )
                      : "NA"}
                  </Table.Cell>
                  <Table.Cell>
                    {record.ship_date
                      ? moment(record.ship_date, "YYYY MM-DD").format(
                          "MM/DD/YYYY"
                        )
                      : "NA"}
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
          <Table.Footer></Table.Footer>
        </Table>
        <br />
      </Fragment>
    );
  }
}
