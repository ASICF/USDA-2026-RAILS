import React, { useState, useEffect, useRef, Fragment } from "react";
import {
  Button,
  Label,
  Divider,
  Form,
  Breadcrumb,
  Container,
  Table,
  Accordion,
  Icon,
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";
import RenderValue from "../Shared/RenderValue";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

export default function WipByState({ months, states, projects, token }) {
  const [message, setMessage] = useState(null);
  const [submitted, setSubmitted] = useState(false);
  const [selectedMonth, setSelectedMonth] = useState(null);
  const [result, setResult] = useState(null);
  const [scope, setScope] = useState("state");
  const [queryAccordionOpen, setQueryAccordionOpen] = useState(true);

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: result || [],
    direction: null,
  });
  const { column, data, direction } = state;

  const {
    handleSubmit,
    reset,
    setValue,
    getValues,
    control,
    formState: { errors },
  } = useForm();

  // console.error("WipByState", {
  //   months,
  //   states,
  //   token,
  //   errors,
  //   result,
  // });

  useEffect(() => {
    // submit default all states and all months report
    setValue("state_id", "all");
    setValue(
      "date_from",
      moment(months[0].date).startOf("month").format("MM/DD/YYYY")
    );
    setValue(
      "date_to",
      moment(months[months.length - 1].date)
        .endOf("month")
        .format("MM/DD/YYYY")
    );
    setSelectedMonth("all");
    onSubmit(getValues());
  }, []);

  useEffect(() => {
    if (result) {
      dispatch({
        data: result,
        type: "UPDATE_DATA",
      });
    }
  }, [result]);

  const monthChange = (e, { name, value }) => {
    // console.error("monthChange", { name, value, months });

    // Set the selected month
    setSelectedMonth(value);

    // if the user clears the input
    if (value.length === 0) return false;

    // declare variables used for setting the dates
    let startOfMonth, endOfMonth;

    // if all then set the max start/end dates
    if (value === "all") {
      startOfMonth = moment(months[0].date)
        .startOf("month")
        .format("MM/DD/YYYY");
      endOfMonth = moment(months[months.length - 1].date)
        .endOf("month")
        .format("MM/DD/YYYY");
    } else {
      // Filter out the selected month
      var record = months.filter((obj) => obj.name === value)[0];

      startOfMonth = moment(record.date).startOf("month").format("MM/DD/YYYY");
      endOfMonth = moment(record.date).endOf("month").format("MM/DD/YYYY");
    }

    // Set the month range
    setValue("date_from", startOfMonth);
    setValue("date_to", endOfMonth);
  };

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const resetForm = () => {
    reset();
    setResult(null);
    setSelectedMonth(null);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);

    setSubmitted(true);

    setMessage({
      status: "Loading",
      text: "Querying database and building table",
    });

    const obj = {
      authenticity_token: token,
      project: data.project,
      state_id: data.state_id,
      date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
      date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
    };

    axios
      .post(`/wip_by_state/query`, obj)
      .then(({ data }) => {
        console.log("submit response", data);

        if (!data.pass) {
          setMessage({
            status: "Error",
            text: data.message,
          });
        } else {
          if (data.result.length === 0) {
            setMessage({
              text: "No Records Found",
            });
            setResult(null);
          } else {
            setMessage(null);
            setResult(data.result);
            setScope(data.scope);
          }
        }
        setSubmitted(false);
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        window.onbeforeunload = null;
        setSubmitted(false);
      });
  };

  return (
    <div>
      <Container style={{ paddingTop: "2em" }}>
        <Breadcrumbs>
          <Breadcrumb.Section>Reports</Breadcrumb.Section>
          <Breadcrumb.Divider />
          <Breadcrumb.Section active>WIP By State</Breadcrumb.Section>
        </Breadcrumbs>
        <Divider />
        {renderForm()}
        {renderMessage()}
      </Container>
      {renderTable()}
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

  function renderForm() {
    return (
      <Accordion styled fluid>
        <Accordion.Title
          active={queryAccordionOpen}
          index={0}
          onClick={() => setQueryAccordionOpen(!queryAccordionOpen)}
        >
          <Icon name="dropdown" />
          Query States
        </Accordion.Title>
        <Accordion.Content active={queryAccordionOpen}>
          <Form>
            <Form.Group widths="equal">
              <Controller
                name={"project"}
                control={control}
                rules={{ required: "Required" }}
                defaultValue={projects[0]}
                render={({ field: { name, value } }) => (
                  <Form.Select
                    fluid
                    search
                    selection
                    name={name}
                    label={"Project"}
                    required={true}
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
                    name={name}
                    required={true}
                    label={"State"}
                    value={value || ""}
                    onChange={handleChange}
                    autoComplete="off"
                    options={[
                      {
                        key: 0,
                        text: "All",
                        value: "all",
                      },
                    ].concat(
                      states.map((record) => {
                        return {
                          key: record.id,
                          text: record.name,
                          value: record.id,
                        };
                      })
                    )}
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
              <Form.Select
                fluid
                search
                selection
                clearable
                name={"month"}
                label={"Month"}
                value={selectedMonth || ""}
                onChange={monthChange}
                autoComplete="off"
                options={[
                  {
                    key: 0,
                    text: "All",
                    value: "all",
                  },
                ].concat(
                  months.map((record, index) => {
                    return {
                      key: `month_${index}`,
                      text: record.name,
                      value: record.name,
                    };
                  })
                )}
              />
            </Form.Group>
            <Form.Group widths="equal">
              <Form.Field error={errors.hasOwnProperty("date_from")}>
                <div className="calendar-input">
                  <Controller
                    name={"date_from"}
                    control={control}
                    rules={{
                      required: "Required",
                    }}
                    render={({ field: { name, value, defaultValue } }) => (
                      <DateInput
                        closable
                        clearable
                        name={name}
                        label={"Ship Date (From)"}
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
                    render={({ field: { name, value, defaultValue } }) => (
                      <DateInput
                        closable
                        clearable
                        name={name}
                        label={"Ship Date (To)"}
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

            <Button
              primary
              loading={submitted}
              disabled={submitted}
              floated="right"
              type="button"
              onClick={handleSubmit(onSubmit)}
            >
              Submit
            </Button>
            <Button
              secondary
              disabled={submitted}
              floated="right"
              type="button"
              onClick={() => resetForm()}
            >
              Reset
            </Button>
            <div style={{ clear: "both" }} />
          </Form>
        </Accordion.Content>
      </Accordion>
    );
  }

  function renderTable() {
    if (!result || result.length === 0) return null;

    // calc totals
    var total_acres = 0;
    var total_counties = 0;
    var total_tiles = 0;
    // cost
    var total_flown_cost = 0;
    var total_at_done_cost = 0;
    var total_ortho_proc_cost = 0;
    var total_dump_cost = 0;
    var total_shipped_cost = 0;
    var total_invoiced_cost = 0;
    // acres
    var total_flown_acres = 0;
    var total_at_done_acres = 0;
    var total_ortho_proc_acres = 0;
    var total_dump_acres = 0;
    var total_shipped_acres = 0;
    var total_invoiced_acres = 0;
    // counts
    var total_flown_count = 0;
    var total_at_done_count = 0;
    var total_ortho_proc_count = 0;
    var total_dump_count = 0;
    var total_shipped_count = 0;
    var total_invoiced_count = 0;

    return (
      <Fragment>
        <Divider />
        <div className="table-overflow">
          <Table
            celled
            striped
            structured
            unstackable
            sortable
            textAlign="center"
          >
            <Table.Header>
              <Table.Row>
                <Table.HeaderCell colSpan="100%" className="no-sort">
                  {`WIP By State for ${getValues("project")} : ${getValues(
                    "date_from"
                  )} - ${getValues("date_to")}`}
                </Table.HeaderCell>
              </Table.Row>
              <Table.Row>
                <Table.HeaderCell
                  rowSpan="2"
                  sorted={column === "name" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "name" })
                  }
                >
                  State
                </Table.HeaderCell>
                {scope === "county" && (
                  <Table.HeaderCell
                    rowSpan="2"
                    sorted={column === "county_name" ? direction : null}
                    onClick={() =>
                      dispatch({ type: "CHANGE_SORT", column: "county_name" })
                    }
                  >
                    County
                  </Table.HeaderCell>
                )}
                <Table.HeaderCell
                  rowSpan="2"
                  sorted={column === "total" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "total" })
                  }
                >
                  Acres
                </Table.HeaderCell>
                <Table.HeaderCell
                  rowSpan="2"
                  sorted={column === "total" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "total" })
                  }
                >
                  Tile Count
                </Table.HeaderCell>
                <Table.HeaderCell colSpan="6" className="dark-green no-sort">
                  Costs
                </Table.HeaderCell>
                <Table.HeaderCell colSpan="8" className="yellow no-sort">
                  Acres
                </Table.HeaderCell>
                <Table.HeaderCell colSpan="6" className="purple no-sort">
                  Counts
                </Table.HeaderCell>
              </Table.Row>
              <Table.Row>
                <Table.HeaderCell
                  className="light-green"
                  sorted={column === "flown_cost" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "flown_cost" })
                  }
                >
                  Flown
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-green"
                  sorted={column === "at_done_cost" ? direction : null}
                  onClick={() =>
                    dispatch({
                      type: "CHANGE_SORT",
                      column: "at_done_cost",
                    })
                  }
                >
                  AT Done
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-green"
                  sorted={column === "ortho_processing_cost" ? direction : null}
                  onClick={() =>
                    dispatch({
                      type: "CHANGE_SORT",
                      column: "ortho_processing_cost",
                    })
                  }
                >
                  Ortho Processing
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-green"
                  sorted={column === "dumped_cost" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "dumped_cost" })
                  }
                >
                  Dumped
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-green"
                  sorted={column === "shipped_cost" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "shipped_cost" })
                  }
                >
                  Shipped
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-green"
                  sorted={column === "invoiced_cost" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "invoiced_cost" })
                  }
                >
                  Invoiced
                </Table.HeaderCell>

                <Table.HeaderCell
                  className="light-yellow"
                  sorted={column === "flown_acres" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "flown_acres" })
                  }
                >
                  Flown
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-yellow"
                  sorted={column === "flown_acres" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "flown_acres" })
                  }
                >
                  Flown Percentage
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-yellow"
                  sorted={column === "at_done_acres" ? direction : null}
                  onClick={() =>
                    dispatch({
                      type: "CHANGE_SORT",
                      column: "at_done_acres",
                    })
                  }
                >
                  AT Done
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-yellow"
                  sorted={
                    column === "ortho_processing_acres" ? direction : null
                  }
                  onClick={() =>
                    dispatch({
                      type: "CHANGE_SORT",
                      column: "ortho_processing_acres",
                    })
                  }
                >
                  Ortho Processing
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-yellow"
                  sorted={column === "orthos_percentage" ? direction : null}
                  onClick={() =>
                    dispatch({
                      type: "CHANGE_SORT",
                      column: "orthos_percentage",
                    })
                  }
                >
                  Orthos Percentage
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-yellow"
                  sorted={column === "dumped_acres" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "dumped_acres" })
                  }
                >
                  Dumped
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-yellow"
                  sorted={column === "shipped_acres" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "shipped_acres" })
                  }
                >
                  Shipped
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-yellow"
                  sorted={column === "invoiced_acres" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "invoiced_acres" })
                  }
                >
                  Invoiced
                </Table.HeaderCell>

                <Table.HeaderCell
                  className="light-purple"
                  sorted={column === "flown_coount" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "flown_coount" })
                  }
                >
                  Flown
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-purple"
                  sorted={column === "at_done_count" ? direction : null}
                  onClick={() =>
                    dispatch({
                      type: "CHANGE_SORT",
                      column: "at_done_count",
                    })
                  }
                >
                  AT Done
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-purple"
                  sorted={
                    column === "ortho_processing_count" ? direction : null
                  }
                  onClick={() =>
                    dispatch({
                      type: "CHANGE_SORT",
                      column: "ortho_processing_count",
                    })
                  }
                >
                  Ortho Processing
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-purple"
                  sorted={column === "dumped_acres" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "dumped_acres" })
                  }
                >
                  Dumped
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-purple"
                  sorted={column === "shipped_count" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "shipped_count" })
                  }
                >
                  Shipped
                </Table.HeaderCell>
                <Table.HeaderCell
                  className="light-purple"
                  sorted={column === "invoiced_count" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "invoiced_count" })
                  }
                >
                  Invoiced
                </Table.HeaderCell>
              </Table.Row>
            </Table.Header>

            <Table.Body>
              {data.map((record, index) => {
                // calc totals
                total_acres += record.acres;
                total_counties += 1;
                total_tiles += record.total;
                // cost
                total_flown_cost += parseFloat(record.flown_cost);
                total_at_done_cost += parseFloat(record.at_done_cost);
                total_ortho_proc_cost += parseFloat(
                  record.ortho_processing_cost
                );
                total_dump_cost += parseFloat(record.dumped_cost);
                total_shipped_cost += parseFloat(record.shipped_cost);
                total_invoiced_cost += parseFloat(record.invoiced_cost);
                // acres
                total_flown_acres += parseFloat(record.flown_acres);
                total_at_done_acres += parseFloat(record.at_done_acres);
                total_ortho_proc_acres += parseFloat(
                  record.ortho_processing_acres
                );
                total_dump_acres += parseFloat(record.dumped_acres);
                total_shipped_acres += parseFloat(record.shipped_acres);
                total_invoiced_acres += parseFloat(record.invoiced_acres);
                // counts
                total_flown_count += record.flown_count;
                total_at_done_count += record.at_done_count;
                total_ortho_proc_count += record.ortho_processing_count;
                total_dump_count += record.dumped_count;
                total_shipped_count += record.shipped_count;
                total_invoiced_count += record.invoiced_count;

                return (
                  <Table.Row key={index}>
                    <Table.Cell>{record.name}</Table.Cell>

                    {scope === "county" && (
                      <Table.Cell>{record.county_name}</Table.Cell>
                    )}

                    <Table.Cell>{record.acres.toFixed(1)}</Table.Cell>
                    <Table.Cell>{record.total}</Table.Cell>
                    {/* costs */}
                    <Table.Cell style={{ borderLeft: "2px solid #999999" }}>
                      <RenderValue value={record.flown_cost} currency />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.at_done_cost} currency />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue
                        value={record.ortho_processing_cost}
                        currency
                      />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.dumped_cost} currency />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.shipped_cost} currency />
                    </Table.Cell>
                    <Table.Cell style={{ borderRight: "2px solid #999999" }}>
                      <RenderValue value={record.invoiced_cost} currency />
                    </Table.Cell>
                    {/* Acres */}
                    <Table.Cell>
                      <RenderValue value={record.flown_acres.toFixed(1)} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue
                        value={record.flown_percentage.toFixed(0)}
                        percentage
                      />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.at_done_acres.toFixed(1)} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue
                        value={record.ortho_processing_acres.toFixed(1)}
                      />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue
                        value={record.orthos_percentage.toFixed(0)}
                        percentage
                      />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.dumped_acres.toFixed(1)} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.shipped_acres.toFixed(1)} />
                    </Table.Cell>
                    <Table.Cell style={{ borderRight: "2px solid #999999" }}>
                      <RenderValue value={record.invoiced_acres.toFixed(1)} />
                    </Table.Cell>
                    {/* Counts */}
                    <Table.Cell>
                      <RenderValue value={record.flown_count} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.at_done_count} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.ortho_processing_count} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.dumped_count} />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={record.shipped_count} />
                    </Table.Cell>
                    <Table.Cell style={{ borderRight: "2px solid #999999" }}>
                      <RenderValue value={record.invoiced_count} />
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table.Body>
            <Table.Footer>
              <Table.Row>
                {scope === "county" ? (
                  <Table.Cell colSpan="2">
                    <b>{`${total_counties} Counties`}</b>
                  </Table.Cell>
                ) : (
                  <Table.HeaderCell></Table.HeaderCell>
                )}
                <Table.HeaderCell>
                  <b>{total_acres.toFixed(1)}</b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>{total_tiles}</b>
                </Table.HeaderCell>
                {/* cost */}
                <Table.HeaderCell style={{ borderLeft: "2px solid #999999" }}>
                  <b>
                    <RenderValue value={total_flown_cost} currency />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_at_done_cost} currency />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_ortho_proc_cost} currency />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_dump_cost} currency />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_shipped_cost} currency />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell style={{ borderRight: "2px solid #999999" }}>
                  <b>
                    <RenderValue value={total_invoiced_cost} currency />
                  </b>
                </Table.HeaderCell>
                {/* acres */}
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_flown_acres.toFixed(1)} />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue
                      value={((total_flown_acres / total_acres) * 100).toFixed(
                        0
                      )}
                      percentage
                    />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_at_done_acres.toFixed(1)} />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_ortho_proc_acres.toFixed(1)} />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue
                      value={(
                        (total_ortho_proc_acres / total_acres) *
                        100
                      ).toFixed(0)}
                      percentage
                    />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_dump_acres.toFixed(1)} />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_shipped_acres.toFixed(1)} />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell style={{ borderRight: "2px solid #999999" }}>
                  <b>
                    <RenderValue value={total_invoiced_acres.toFixed(1)} />
                  </b>
                </Table.HeaderCell>
                {/* counts */}
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_flown_count} numeric />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_at_done_count} numeric />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_ortho_proc_count} numeric />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_dump_count} numeric />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>
                    <RenderValue value={total_shipped_count} numeric />
                  </b>
                </Table.HeaderCell>
                <Table.HeaderCell style={{ borderRight: "2px solid #999999" }}>
                  <b>
                    <RenderValue value={total_invoiced_count} numeric />
                  </b>
                </Table.HeaderCell>
              </Table.Row>
            </Table.Footer>
          </Table>
        </div>
      </Fragment>
    );
  }
}
