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
  Icon,
  ButtonContent,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import { DateInput } from "semantic-ui-calendar-react";
import { Controller, useForm } from "react-hook-form";
import axios from "axios";

const WeeklyProgressReport = ({ projects, path, to, cc, token }) => {
  const [submitted, setSubmitted] = useState(false);
  const [message, setMessage] = useState(null);

  console.log("WeeklyProgressReport", { projects, path, to, cc, token });

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);

    setSubmitted(true);
    axios
      .post(`/weekly_progress_reports/generate`, {
        authenticity_token: token,
        project: data.project,
      })
      .then(({ data }) => {
        console.log(data);

        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });

        if (data.state && data.id) {
          window.open(`/history_download/${data.id}`);
        }

        setSubmitted(false);
      });
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Weekly Progress Reports</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      <Message>
        <Message.Header>Summary</Message.Header>
        <p>
          Choose the Project to generate and download the report. A copy of the
          report will be generated and saved as a text file at:{" "}
          <i>
            <b>{path}</b>
          </i>{" "}
          and available to download via the Timeline Report.
        </p>

        <b>Send To:</b>
        <List bulleted items={to} />
        <b>CC:</b>
        <List bulleted items={cc} />
      </Message>
      <Divider />

      {message && (
        <MessageBox
          status={message.status}
          title={message.title}
          message={message.text}
        />
      )}

      <Form>
        <Form.Field>
          <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={projects.length > 0 ? projects[0] : null}
            render={({ field: { name, value, defaultValue } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                data-value={value}
                label={"Project"}
                required={true}
                value={value || ""}
                defaultValue={defaultValue}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record, index) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                    // disabled: index > 0 ? true : false,
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
        </Form.Field>
        <Divider />

        <Button
          primary
          animated
          floated="right"
          type="button"
          loading={submitted}
          disabled={submitted}
          onClick={handleSubmit(onSubmit)}
        >
          <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
            <Icon name="arrow right" />
          </ButtonContent>
        </Button>
        <div style={{ clear: "both" }}></div>
      </Form>
    </div>
  );
};

export default WeeklyProgressReport;
