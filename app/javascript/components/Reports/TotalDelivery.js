import React, { useState, useEffect, useRef, Fragment } from "react";
import {
  Button,
  Label,
  Divider,
  Form,
  Breadcrumb,
  Table,
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

export default function TotalDelivery({ months, states, projects, token }) {
  const [message, setMessage] = useState(null);
  const [submitted, setSubmitted] = useState(false);
  const [selectedMonth, setSelectedMonth] = useState(null);
  const [result, setResult] = useState(null);
  const [totals, setTotals] = useState(null);

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

  console.log("TotalDelivery", {
    months,
    states,
    projects,
    token,
    totals,
    result,
    values: getValues(),
    errors,
  });

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

    const obj = {
      authenticity_token: token,
      project: data.project,
      state_id: data.state_id,
      date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
      date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
    };

    axios
      .post(`/total_delivery/query`, obj)
      .then(({ data }) => {
        console.log("submit response", data);

        if (!data.pass) {
          setMessage({
            status: "Error",
            text: data.message,
          });
        } else {
          setMessage(null);

          if (data.result.length === 0) {
            setMessage({
              text: "No Records Found",
            });
            setResult(null);
          } else if (data.result.length > 1) {
            var obj = {
              lesser_count: 0,
              between_count: 0,
              greater_count: 0,
              total_count: 0,
              usda_count: 0,
            };

            data.result.forEach((record) => {
              obj.lesser_count += record.lesser_count;
              obj.between_count += record.between_count;
              obj.greater_count += record.greater_count;
              obj.total_count += record.total_count;
              obj.usda_count += record.usda_count;
            });

            setTotals(obj);
          }
          setResult(data.result);
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
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Total Delivery</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
      {renderForm()}
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
    );
  }

  function renderTable() {
    if (!result || result.length === 0) return null;

    return (
      <Fragment>
        <Divider />
        <Table celled striped structured sortable textAlign="center">
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell colSpan="6">
                {`Total Delivery for ${getValues("project")} : ${getValues(
                  "date_from"
                )} - ${getValues("date_to")}`}
              </Table.HeaderCell>
            </Table.Row>
            <Table.Row>
              <Table.HeaderCell
                sorted={column === "name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "name" })
                }
              >
                State
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "lesser_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "lesser_count" })
                }
              >
                {"< 15 Days"}
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "between_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "between_count" })
                }
              >
                {"15 - 30 Days"}
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "greater_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "greater_count" })
                }
              >
                {"> 30 Days"}
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "total_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "total_count" })
                }
              >
                Total Count
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "usda_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "usda_count" })
                }
              >
                USDA Count
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {data.map((record, index) => {
              return (
                <Table.Row key={index}>
                  <Table.Cell>{record.name}</Table.Cell>
                  <Table.Cell>{record.lesser_count}</Table.Cell>
                  <Table.Cell>{record.between_count}</Table.Cell>
                  <Table.Cell>{record.greater_count}</Table.Cell>
                  <Table.Cell>{record.total_count}</Table.Cell>
                  <Table.Cell>{record.usda_count}</Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
          {totals && (
            <Table.Footer>
              <Table.Row>
                <Table.HeaderCell>
                  <b>Totals</b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>{totals.lesser_count}</b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>{totals.between_count}</b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>{totals.greater_count}</b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>{totals.total_count}</b>
                </Table.HeaderCell>
                <Table.HeaderCell>
                  <b>{totals.usda_count}</b>
                </Table.HeaderCell>
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
}
