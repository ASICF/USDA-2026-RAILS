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
import { result } from "lodash";
import LoaderTargetPlugin from "webpack/lib/LoaderTargetPlugin";

// style
const emailBtnStyle = { position: "absolute", top: "7px", right: "5px" };

function DailyProgressReport(props) {
  console.log("DailyProgressReport", props);

  const [flightDates, setFlightDates] = useState(props.flight_dates);
  const [result, setResult] = useState(null);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
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
    setLoading(true);
    axios
      .post(`/daily_progress_reports/render`, {
        authenticity_token: props.token,
        flight_date: data.flight_date,
      })
      .then((response) => {
        console.log(response);
        setFlightDates(response.data.flight_dates);
        setResult(response.data.result);
        setSubmitted(false);
        setLoading(false);
      });
  };

  const handleEmail = (project, result) => {
    let html = "";

    result.accepted.forEach((item) => {
      html += `${item.date}%09${item.poly_id}%09A%0A`;
    });
    result.rejected.forEach((item) => {
      html += `${item.date}%09${item.poly_id}%09R%0A`;
    });

    // Cut off the email size if there are too many characters
    if (html.length > 1800) {
      html = "";
    }

    // Launch the email handler
    location.href = `mailto:${props.to}?cc=${props.cc.join(";")}&subject=${
      result.header
    }&body=${html}`;
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Daily Progress Reports</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      <Message>
        <Message.Header>Summary</Message.Header>
        <p>
          Choose the flight date to generate the report. A copy of the report
          will be generated and saved as a text file at:{" "}
          <i>
            <b>{props.folder_path}</b>
          </i>{" "}
          and available to download via the Timeline Report.
        </p>
      </Message>
      <Divider />

      <RenderMessage />
      <RenderSubmitForm />
      <RenderResults />
      <br />
    </div>
  );

  function RenderMessage() {
    if (flightDates.length > 0) return null;

    return (
      <MessageBox
        status={"Success"}
        title={"All Caught Up"}
        message={`All Flown Tiles have been marked as Reported`}
      />
    );
  }

  function RenderSubmitForm() {
    if (flightDates.length === 0) return null;

    return (
      <Form>
        <Form.Field>
          <Controller
            name={"flight_date"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={flightDates.length > 0 ? flightDates[0].value : null}
            render={({ field: { name, value, defaultValue } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                data-value={value}
                label={"Flight Dates to Report"}
                required={true}
                value={value || ""}
                defaultValue={defaultValue}
                onChange={handleChange}
                autoComplete="off"
                options={flightDates.map((record, index) => {
                  return {
                    key: record.value,
                    text: record.label,
                    value: record.value,
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
    );
  }

  function RenderResults() {
    if (!result) return null;

    return (
      <Fragment>
        <Divider />
        <Message>
          <Message.Content>
            <Message.Header>Important</Message.Header>
            <p>
              This report has been logged as generated and shipped and an email
              has been sent to the "Daily Progress Report" Mail Group. The app{" "}
              will not send an email to the USDA automatically.{" "}
              <b>You are required to send this email to the USDA</b>. You can
              click the <b>Email</b> button to launch Outlook and make sure the
              body completely copies (there is a max character limit when
              opening an email with the mailto link) or Open a new Email message
              and copy/paste the subject and body.
            </p>
            <p>
              If you open a new email include the following email addresses:
            </p>
            <b>TO:</b>
            <List bulleted items={props.to} />
            <b>CC:</b>
            <List bulleted items={props.cc} />
          </Message.Content>
        </Message>

        <Segment.Group>
          {result.nri && result.nri.accepted.length > 0 && (
            <>
              <Segment tertiary>
                <b>NRI</b>
                {/* <Button
                  secondary
                  floated="right"
                  style={emailBtnStyle}
                  onClick={() => handleEmail("NRI", result.nri)}
                >
                  Email
                </Button> */}
              </Segment>
              <Segment>
                <Header as="h5">Subject</Header>
                <p>{result.sl.header}</p>
              </Segment>
              <Segment>
                <Header as="h5">Body</Header>
                <p>Date Acquired: {result.nri.header}</p>

                <p>NRI Sites Acquired:</p>
                <List
                  style={{ whiteSpace: "pre" }}
                  items={result.nri.accepted.map((item) => (
                    <pre style={{ margin: 0 }}>{item}</pre>
                  ))}
                />
              </Segment>
            </>
          )}
          {result.sl && result.sl.accepted.length > 0 && (
            <>
              <Segment tertiary>
                <b>SL Project</b>
                {/* <Button
                  secondary
                  floated="right"
                  style={emailBtnStyle}
                  onClick={() => handleEmail("SL", result.sl)}
                >
                  Email
                </Button> */}
              </Segment>
              <Segment>
                <Header as="h5">Subject</Header>
                <p>SL {result.sl.header}</p>
              </Segment>
              <Segment>
                <Header as="h5">Body</Header>
                <p>Date Acquired: {result.sl.header}</p>

                <p>Easements Acquired:</p>
                <List
                  style={{ whiteSpace: "pre" }}
                  items={result.sl.accepted.map((item) => (
                    <pre style={{ margin: 0 }}>{item}</pre>
                  ))}
                />
              </Segment>
            </>
          )}
        </Segment.Group>
      </Fragment>
    );
  }
}

export default DailyProgressReport;
