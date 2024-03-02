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
  ButtonContent
} from "semantic-ui-react";
import _, { result } from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";

import FlightCrewSL from "./FlightCrewReportPartials/FlightCrewSL";
import FlightCrewNAIP from "./FlightCrewReportPartials/FlightCrewNAIP";

export default function FlightCrewReport({
  projects,
  companies,
  months,
  states,
  token,
}) {
  const [message, setMessage] = useState(null);
  const [selectedMonth, setSelectedMonth] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [results, setResults] = useState([]);
  const [project, setProject] = useState(null);
  const [loading, setLoading] = useState(false);
  const [scope, setScope] = useState(null);
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

  console.log("FlightCrewReport", {
    project,
    scope,
    results,
    companies,
  });

  const resetForm = () => {
    reset({
      state_id: "",
      state_id: "",
      project: "",
      date_from: "",
      date_to: "",
    });
    setSelectedMonth(null);
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
    setResults([]);
    setProject(null);
    setScope(null);
    setLoading(true);
    setMessage(null);

    axios
      .post(`/flight_crew_report/query`, {
        authenticity_token: token,
        state_id: data.state_id,
        flown_by_id: data.flown_by_id,
        project: data.project,
        date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
        date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      })
      .then(({ data }) => {
        console.log("submit response", data);

        setResults(data.result);
        setProject(data.project);
        setScope(data.scope);

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
      setLoading(false);
        setSubmitted(false);
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Flight Crew</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
      {renderForm()}
      <Divider />
      {renderLoading()}
      {project == "SL" && <FlightCrewSL results={results} />}
      {project == "NAIP" && <FlightCrewNAIP results={results} />}
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
            name={"flown_by_id"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                label={"Flown By"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={[{ id: "ALL", name: "All Companies" }]
                  .concat(companies)
                  .map((record) => {
                    return {
                      key: record.id,
                      text: record.name,
                      value: record.id,
                    };
                  })}
                error={
                  errors["flown_by_id"]
                    ? {
                        content: errors["flown_by_id"].message,
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

        <Button animated floated="right" primary onClick={handleSubmit(onSubmit)}>
        <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
          <Icon name='arrow right' />
          </ButtonContent>
        </Button>
        <Button
          secondary
          animated
          floated="right"
          type="button"
          style={{ marginRight: "0.5em" }}
          onClick={() => resetForm()}
        >
          <ButtonContent visible>Reset</ButtonContent>
          <ButtonContent hidden>
          <Icon name="undo" />
          </ButtonContent>
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }
}
