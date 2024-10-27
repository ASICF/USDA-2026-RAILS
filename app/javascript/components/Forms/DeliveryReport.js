import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Grid,
  Icon,
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
import RenderValue from "../Shared/RenderValue";
import moment from "moment";
import axios from "axios";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";

export default function InvoiceReport({
  projects,
  months,
  states,
  state_totals,
  token,
}) {
  const [message, setMessage] = useState(null);
  const [selectedMonth, setSelectedMonth] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [results, setResults] = useState(false);
  const [totals, setTotals] = useState(false);
  const [project, setProject] = useState(null);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const {
    handleSubmit,
    reset,
    setValue,
    register,
    getValues,
    control,
    formState: { errors },
  } = useForm();

  console.log("InvoiceReport", {
    projects,
    months,
    state_totals,
    results,
    totals,
  });

  // Testing
  //   useEffect(() => {
  //     onSubmit({ project: "SL", date_from: "01/01/2022", date_to: "07/01/2022" });
  //   }, []);

  const resetForm = () => {
    reset({
      project: "",
      date_from: "",
      date_to: "",
    });
  };

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

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);
    setResults(null);
    setTotals(null);
    setLoading(true);

    axios
      .post(`/delivery_report/query`, {
        authenticity_token: token,
        project: data.project,
        state_id: data.state_id,
        date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
        date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      })
      .then((response) => {
        console.log("submit response", response.data);

        setLoading(false);
        setSubmitted(false);
        if (response.data.state) {
          setProject(data.project);
          setTotals(response.data.totals);
          setResults(response.data.result);
        } else {
          setMessage({
            status: "Error",
            text: response.data.message,
          });
        }

        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        setLoading(false);
        setSubmitted(false);
        window.onbeforeunload = null;
      });
  };

  const onExport = (data) => {
    window.open(
      `/delivery_report/export?${new URLSearchParams({
        project: data.project,
        state_id: data.state_id,
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
        <Breadcrumb.Section>Delivery Report</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
      {renderForm()}
      <Divider />
      {renderActiveCounts()}
      {renderLoading()}
      {renderTable()}
      <br />
      <br />
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

  function renderActiveCounts() {
    const [open, setOpen] = useState(false);

    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: state_totals,
      direction: null,
    });
    const { column, data, direction } = state;

    return (
      <Accordion fluid styled>
        <Accordion.Title active={open} index={0} onClick={() => setOpen(!open)}>
          <Icon name="dropdown" />
          Active States: Easement Totals
        </Accordion.Title>
        <Accordion.Content active={open}>
          <Table sortable celled textAlign="center">
            <Table.Header>
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
                  sorted={column === "easement_count" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "easement_count" })
                  }
                >
                  Easement Count
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "easement_acres" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "easement_acres" })
                  }
                >
                  Easement Acres
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "total_cost" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "total_cost" })
                  }
                >
                  Current Cost
                </Table.HeaderCell>
                <Table.HeaderCell
                  sorted={column === "awarded" ? direction : null}
                  onClick={() =>
                    dispatch({ type: "CHANGE_SORT", column: "awarded" })
                  }
                >
                  Awarded
                </Table.HeaderCell>
              </Table.Row>
            </Table.Header>
            <Table.Body>
              {data.map((state, index) => {
                return (
                  <Table.Row key={index}>
                    <Table.Cell>{state.name}</Table.Cell>
                    <Table.Cell>{state.easement_count}</Table.Cell>
                    <Table.Cell>
                      {Number(state.easement_acres).toFixed(1)}
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.total_cost} currency />
                    </Table.Cell>
                    <Table.Cell>
                      <RenderValue value={state.awarded} currency />
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table.Body>
          </Table>
        </Accordion.Content>
      </Accordion>
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
            defaultValue={projects[0]}
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
            defaultValue="ALL"
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
                  errors[name]
                    ? {
                        content: errors[name].message,
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
          <Form.Field error={errors.hasOwnProperty("date_from")}>
            <div className="calendar-input">
              <Controller
                name={"date_from"}
                control={control}
                rules={{
                  required: "Required",
                }}
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Date From"}
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
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Date To"}
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
          <Button
            primary
            loading={submitted}
            disabled={submitted}
            onClick={handleSubmit(onSubmit)}
          >
            Submit
          </Button>
          <Button.Or />
          <Button onClick={handleSubmit(onExport)}>Export</Button>
        </Button.Group>
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

  function renderTable() {
    if (!results) return null;

    console.log("renderTable", results);

    if (Object.keys(results).length === 0) {
      return (
        <MessageBox
          title={"No Records Found"}
          message={"Query returned no records"}
        />
      );
    }

    return (
      <Fragment>
        <Divider />
        <Table celled textAlign="center">
          <Table.Header>
            <Table.Row>
              <Table.HeaderCell>State</Table.HeaderCell>
              <Table.HeaderCell>FIPS</Table.HeaderCell>
              <Table.HeaderCell>County</Table.HeaderCell>
              <Table.HeaderCell>Shipped Easements</Table.HeaderCell>
              <Table.HeaderCell>Shipped Acres</Table.HeaderCell>
              <Table.HeaderCell>Packing Slip</Table.HeaderCell>
              <Table.HeaderCell></Table.HeaderCell>
            </Table.Row>
          </Table.Header>

          <Table.Body>
            {Object.keys(results).map((keyName, keyIndex) => {
              // var count = 0;
              // var total_count = 0;
              // var acres = 0;
              // var total_acres = 0;
              // var acquisition_price = 0;
              // var orthos_price = 0;
              // var total_price = 0;
              var list = results[keyName].map((record, index) => {
                //   count += record.count;
                //   total_count += record.total_count;
                //   acres += record.acres;
                //   total_acres += record.total_acres;
                //   acquisition_price += record.acquisition_price;
                //   orthos_price += record.orthos_price;
                //   total_price += record.total_price;

                return (
                  <Table.Row key={`${keyIndex}_${index}`}>
                    <Table.Cell>{record.state_name}</Table.Cell>
                    <Table.Cell>{record.fips}</Table.Cell>
                    <Table.Cell>{record.county_name}</Table.Cell>
                    <Table.Cell>{record.count}</Table.Cell>
                    <Table.Cell>{record.acres.toFixed(6)}</Table.Cell>
                    <Table.Cell>{record.psn_name}</Table.Cell>
                    <Table.Cell></Table.Cell>
                  </Table.Row>
                );
              });

              var state_total = totals[keyName];
              console.warn({ state_total: state_total.total_delivery });

              // Previously Delivered
              list.push(
                <Table.Row key={`sumary_${keyIndex}_pd`} className="light-gray">
                  <Table.Cell>{keyName}</Table.Cell>
                  <Table.Cell></Table.Cell>
                  <Table.Cell>
                    <b>Previously Delivered</b>
                  </Table.Cell>
                  <Table.Cell>
                    {state_total.previously_delivered.easements}
                  </Table.Cell>
                  <Table.Cell>
                    {state_total.previously_delivered.acres === 0
                      ? "0.0"
                      : parseFloat(
                          state_total.previously_delivered.acres
                        ).toFixed(6)}
                  </Table.Cell>
                  <Table.Cell>
                    <b>Price Per {data.project === "NRI" ? "Site" : "Acre"}</b>
                  </Table.Cell>
                  <Table.Cell>
                    <b>Total</b>
                  </Table.Cell>
                </Table.Row>
              );

              // Previously Billed
              list.push(
                <Table.Row key={`sumary_${keyIndex}_pb`} className="light-gray">
                  <Table.Cell>{keyName}</Table.Cell>
                  <Table.Cell></Table.Cell>
                  <Table.Cell>
                    <b>Previously Billed</b>
                  </Table.Cell>
                  <Table.Cell>
                    {state_total.previously_billed.easements}
                  </Table.Cell>
                  <Table.Cell>
                    {state_total.previously_billed.acres === 0
                      ? "0.0"
                      : parseFloat(state_total.previously_billed.acres).toFixed(
                          6
                        )}
                  </Table.Cell>
                  <Table.Cell>
                    <b>
                      <RenderValue
                        value={state_total.previously_delivered.ppa}
                        currency
                      />
                    </b>
                  </Table.Cell>
                  <Table.Cell>
                    <b>
                      <RenderValue
                        value={state_total.previously_delivered.total}
                        currency
                      />
                    </b>
                  </Table.Cell>
                </Table.Row>
              );

              // Total Delivery
              list.push(
                <Table.Row key={`sumary_${keyIndex}_td`} className="light-gray">
                  <Table.Cell>{keyName}</Table.Cell>
                  <Table.Cell></Table.Cell>
                  <Table.Cell>
                    <b>Total Delivery</b>
                  </Table.Cell>
                  <Table.Cell>
                    {state_total.total_delivery.easements}
                  </Table.Cell>
                  <Table.Cell>
                    {state_total.total_delivery.acres === 0
                      ? "0.0"
                      : parseFloat(state_total.total_delivery.acres).toFixed(6)}
                  </Table.Cell>
                  <Table.Cell></Table.Cell>
                  <Table.Cell></Table.Cell>
                </Table.Row>
              );

              // Total billing
              list.push(
                <Table.Row
                  key={`sumary_${keyIndex}_totb`}
                  className="light-gray"
                >
                  <Table.Cell>{keyName}</Table.Cell>
                  <Table.Cell></Table.Cell>
                  <Table.Cell>
                    <b>Total Billing</b>
                  </Table.Cell>
                  <Table.Cell>{state_total.total_billing.easements}</Table.Cell>
                  <Table.Cell>
                    {state_total.total_billing.acres === 0
                      ? "0.0"
                      : state_total.total_billing.acres}
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue
                      value={state_total.total_billing.ppa}
                      currency
                    />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue
                      value={state_total.total_billing.total}
                      currency
                    />
                  </Table.Cell>
                </Table.Row>
              );

              // this billing
              list.push(
                <Table.Row
                  key={`sumary_${keyIndex}_thisb`}
                  className="light-gray"
                >
                  <Table.Cell>{keyName}</Table.Cell>
                  <Table.Cell></Table.Cell>
                  <Table.Cell>
                    <b>This Billing</b>
                  </Table.Cell>
                  <Table.Cell>{state_total.this_billing.easements}</Table.Cell>
                  <Table.Cell>{state_total.this_billing.acres}</Table.Cell>
                  <Table.Cell>
                    <RenderValue
                      value={state_total.this_billing.ppa}
                      currency
                    />
                  </Table.Cell>
                  <Table.Cell>
                    <RenderValue
                      value={state_total.this_billing.total}
                      currency
                    />
                  </Table.Cell>
                </Table.Row>
              );

              return list;
            })}
          </Table.Body>
        </Table>
      </Fragment>
    );
  }
}
