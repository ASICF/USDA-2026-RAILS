import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Header,
  List,
  Message,
  Divider,
  Segment,
  Breadcrumb,
  Form,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import { DateInput } from "semantic-ui-calendar-react";
import axios from "axios";

export default function VectorMetadata({
  projects,
  all_states,
  sl_states,
  naip_states,
  token,
}) {
  const [message, setMessage] = useState(null);
  const [states, setStates] = useState(sl_states);
  const [data, setData] = useState({
    project: "SL",
    state_id: "",
    flight_date: "",
  });

  const handleChange = (e, { name, value }) => {
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

    const record = { ...data };
    record[name] = value;
    setData(record);
  };

  const handleSubmit = () => {
    if (data.flight_date.length === 10 && data.project && data.state_id) {
      data.authenticity_token = token;
      console.log("handleSubmit");
      axios.post("/query_vector_metadata", data).then((res) => {
        console.log(res);
      });
    } else {
      setMessage({
        status: "Error",
        title: "Errror Processing request",
        text: "Please review required fields in form and resubmit",
      });
    }
  };

  console.log("ExportVectorMetadata", {
    projects,
    all_states,
    sl_states,
    naip_states,
    states,
    data,
    disabled:
      data.flight_date.length === 10 && data.project && data.state_id
        ? false
        : true,
  });

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Vector Metadata</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />

      <Form>
        <Form.Group widths="equal">
          <Form.Select
            fluid
            search
            selection
            name={"project"}
            label={"Project"}
            required={true}
            value={data.project}
            //   defaultValue={data.project}
            onChange={handleChange}
            autoComplete="off"
            options={projects.map((record) => {
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
                required
                closable
                clearable
                label={"Flight Date"}
                name="flight_date"
                placeholder="Date"
                iconPosition="left"
                dateFormat="MM/DD/YYYY"
                value={data.flight_date}
                onChange={handleChange}
                autoComplete="off"
              />
            </div>
          </Form.Field>
          <Form.Select
            fluid
            search
            selection
            name={"state_id"}
            label={"State"}
            required={true}
            value={data.state_id}
            onChange={handleChange}
            autoComplete="off"
            options={[{ name: "All", id: "all" }]
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
          onClick={handleSubmit}
          disabled={
            data.flight_date.length === 10 && data.project && data.state_id
              ? false
              : true
          }
        >
          Submit
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    </div>
  );
}
