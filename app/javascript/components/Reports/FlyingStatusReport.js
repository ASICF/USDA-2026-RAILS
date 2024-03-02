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

import OtherSL from "./FlyingStatusReports/OtherSL";
import OtherNAIP from "./FlyingStatusReports/OtherNAIP";
import ContractorSL from "./FlyingStatusReports/ContractorSL";
import ContractorNAIP from "./FlyingStatusReports/ContractorNAIP";
import StateSL from "./FlyingStatusReports/StateSL";
import StateNAIP from "./FlyingStatusReports/StateNAIP";
import AllSitesByContractorAndStateSL from "./FlyingStatusReports/AllSitesByContractorAndStateSL";
import AllSitesByContractorAndStateNAIP from "./FlyingStatusReports/AllSitesByContractorAndStateNAIP";

export default function FlyingStatusReport({
  projects,
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

  console.log("FlyingStatusReport", {
    project,
    scope,
    results,
  });

  const resetForm = () => {
    reset({
      scope_id: "",
      state_id: "",
      project: "",
      date_from: "",
      date_to: "",
    });
    setSelectedMonth(null)
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
      .post(`/flying_status_reports/show`, {
        authenticity_token: token,
        scope_id: data.scope_id,
        project: data.project,
        date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
        date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setSubmitted(false);
        setLoading(false);

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
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Flying Status Report</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
      {renderForm()}
      <Divider />
      {renderLoading()}
      {project == "SL" && scope == "OTHER" && <OtherSL results={results} />}
      {project == "NAIP" && (scope == "OTHER" || scope == "contractor") && (
        <OtherNAIP results={results} />
      )}
      {project == "SL" && scope == "CONTRACTOR" && <ContractorSL results={results} />}
      {project == "NAIP" && scope == "CONTRACTOR" && <ContractorNAIP results={results} />}
      {project == "SL" && scope == "STATE" && <StateSL results={results} />}
      {project == "NAIP" && scope == "STATE" && <StateNAIP results={results} />}
      {project == "SL" && scope == "CONTRACTOR_STATE" && <AllSitesByContractorAndStateSL results={results} />}
      {project == "NAIP" && scope == "CONTRACTOR_STATE" && <AllSitesByContractorAndStateNAIP results={results} />}
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
            name={"scope_id"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                label={"Scope"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={[
                  { id: "CONTRACTOR", name: "All Sites by Contractor" },
                  { id: "STATE", name: "All Sites by State" },
                  {
                    id: "CONTRACTOR_STATE",
                    name: "All Sites by Contractor and State",
                  },
                ]
                  .concat(states)
                  .map((record) => {
                    return {
                      key: record.id,
                      text: record.name,
                      value: record.id,
                    };
                  })}
                error={
                  errors["scope_id"]
                    ? {
                        content: errors["scope_id"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
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

        <Button
        animated
          secondary
          floated="left"
          type="button"
          style={{ marginRight: "0.5em" }}
          onClick={() => resetForm()}
        >
           <ButtonContent visible>Reset</ButtonContent>
          <ButtonContent hidden>
          <Icon name="undo" />
          </ButtonContent>
        </Button>
        <Button  animated floated="right" primary loading={submitted}
       
disabled={submitted} 
onClick={handleSubmit(onSubmit)}>
            <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
          <Icon name='arrow right' />
          </ButtonContent>
        </Button>
        <div style={{ clear: "both" }} />
        
      </Form>
    );
  }
}
