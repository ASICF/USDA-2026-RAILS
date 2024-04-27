import React, { useEffect, useState, Fragment } from "react";

import { Button, Divider, Form, Breadcrumb, Table } from "semantic-ui-react";

import axios from "axios";
import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import { tableSortReducer } from "../Shared/TableSort";
import RenderValue from "../Shared/RenderValue";

export default function ReadyToShip({ states, projects, priorities, token }) {
  const [results, setResults] = useState(false);
  const [totals, setTotals] = useState(false);
  const [message, setMessage] = useState(null);
  const [loading, setLoading] = useState(false);

  const {
    handleSubmit,
    reset,
    setValue,
    control,
    formState: { errors },
  } = useForm();

  useEffect(() => {
    resetForm();
    fetch({
      state_id: "ALL",
      project: "SL",
      priority: "ALL",
    });
  }, []);

  // Sets the default options for the forms
  const resetForm = () => {
    setValue("state_id", "ALL");
    setValue("project", "SL");
    setValue("priority", "ALL");
  };

  // Detects dropdown changes and pushes to react hook forms
  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  // Handles the submission and will only fire if no validation errors
  const onSubmit = (data) => {
    fetch(data);
  };

  // Passes arguments to server and returns records
  const fetch = (data) => {
    setLoading(true);
    setResults([]);

    axios
      .post(`/ready_to_ship/query`, {
        authenticity_token: token,
        state_id: data.state_id,
        project: data.project,
        priority: data.priority,
      })
      .then(({ data }) => {
        console.log("submit response", data);
        if (data.state) {
          if (data.result.length > 0) {
            setResults(data.result);
            setTotals(data.totals);
          }
          setLoading(false);
        } else {
          setLoading(false);
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
          text: "Something went wrong",
        });
      });
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Ready to Ship</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
      {renderForm()}
      <Divider />
      {renderLoading()}
      <RenderTable results={results} priorities={priorities} />
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

  function renderLoading() {
    if (!loading) return null;
    return (
      <MessageBox
        status={"Loading"}
        title={"Loading"}
        message={"Building Table..."}
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
          <Controller
            name={"state_id"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                label={"State"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={[{ id: "ALL", name: "All States" }]
                  .concat(states)
                  .map((record) => {
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
            name={"priority"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                label={"Priority"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={[{ id: "ALL", value: "All Priorities" }]
                  .concat(priorities)
                  .map((record) => {
                    return {
                      key: record.id,
                      text: record.value,
                      value: record.id,
                    };
                  })}
                error={
                  errors["priority"]
                    ? {
                        content: errors["priority"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>
        <Divider />

        <Button floated="right" primary onClick={handleSubmit(onSubmit)}>
          Submit
        </Button>
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

  function RenderTable({ results, priorities }) {
    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: results || [],
      direction: null,
    });
    const { column, data, direction } = state;

    if (results.length == 0)
      return (
        <MessageBox message="No Counties marked as Fully Flown found with selected Project, State, and Priority" />
      );

    return (
      <Fragment>
        <Divider />
        <Table
          unstackable
          celled
          striped
          structured
          sortable
          selectable
          textAlign="center"
        >
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell
                sorted={column === "state" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "state" })
                }
              >
                State
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "name" })
                }
              >
                Name
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "num_tiles" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "num_tiles" })
                }
              >
                Remaining Tiles
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "at_done" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "at_done" })
                }
              >
                AT Done
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "ortho_processed" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "ortho_processed" })
                }
              >
                Ortho Processed
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "dumped" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "dumped" })
                }
              >
                Dumped
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "total_tiles" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "total_tiles" })
                }
              >
                Total County Tiles
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "county_flown_date" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "county_flown_date" })
                }
              >
                County Flown Date
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "due_date" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "due_date" })
                }
              >
                Due Date
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "days_til_due" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "days_til_due" })
                }
              >
                Days til Due
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "total_amount" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "total_amount" })
                }
              >
                Contract Totals
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "priority" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "priority" })
                }
              >
                Priority
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {data.map((record) => {
              return (
                <Table.Row
                  key={record.county_id}
                  onClick={() => {
                    window.open(
                      `/ready_to_ship/county/${record.county_id}`,
                      "_blank"
                    );
                  }}
                  style={{ cursor: "pointer" }}
                >
                  <Table.Cell>{record.state}</Table.Cell>
                  <Table.Cell>{record.name}</Table.Cell>
                  <Table.Cell>{record.num_tiles}</Table.Cell>
                  <Table.Cell>{record.at_done}</Table.Cell>
                  <Table.Cell>{record.ortho_processed}</Table.Cell>
                  <Table.Cell>{record.dumped}</Table.Cell>
                  <Table.Cell>{record.total_tiles}</Table.Cell>
                  <Table.Cell>{record.county_flown_date_formatted}</Table.Cell>
                  <Table.Cell>{record.due_date_formatted}</Table.Cell>
                  <Table.Cell>{record.days_til_due}</Table.Cell>
                  <Table.Cell>
                    <RenderValue value={record.total_amount} currency />
                  </Table.Cell>
                  {renderPriority(record.priority, priorities)}
                </Table.Row>
              );
            })}
          </Table.Body>
          {totals && (
            <Table.Footer>
              <Table.Row style={{ fontWeight: "bold" }}>
                <Table.Cell>{totals.state_count}</Table.Cell>
                <Table.Cell>{totals.county_count}</Table.Cell>
                <Table.Cell>{totals.remaining_count}</Table.Cell>
                <Table.Cell>{totals.at_done_count}</Table.Cell>
                <Table.Cell>{totals.ortho_proc_count}</Table.Cell>
                <Table.Cell>{totals.dump_count}</Table.Cell>
                <Table.Cell>{totals.county_tiles_count}</Table.Cell>
                <Table.Cell colSpan="3"></Table.Cell>
                <Table.Cell>
                  <RenderValue value={totals.contract_total} currency />
                </Table.Cell>
                <Table.Cell></Table.Cell>
              </Table.Row>
            </Table.Footer>
          )}
        </Table>
        <br />
        <br />
        <br />
      </Fragment>
    );
  }

  function renderPriority(priority, priorities) {
    let record = priorities.filter((record) => record.id === priority)[0];
    return <Table.Cell className={record.color}>{record.value}</Table.Cell>;
  }
}
