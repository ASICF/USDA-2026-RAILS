import React, { useState, useRef } from "react";
import {
  Button,
  Grid,
  Header,
  Label,
  Accordion,
  Divider,
  Form,
  Breadcrumb,
  Icon,
  List,
  ButtonContent,
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

export default function FootprintRejection({ token }) {
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
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

  console.log("Rejection", {
    token,
    errors,
  });

  const handleChange = (e, { name, value }) => {
    console.log(name, value);
    setValue(name, value);
  };

  const resetForm = () => {
    console.error("reset form");
    reset({
      flight_date: "",
      reject_date: "",
      file: "",
    });
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);
    setLoading(true);
    const form = new FormData();

    form.append("authenticity_token", token);
    form.append(
      "rejection[flight_date]",
      moment(data.flight_date, "l").format("YYYY-MM-DD")
    );
    form.append("rejection[file]", data.file[0]);

    setMessage({
      status: "loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    window.onbeforeunload = () => {
      return "Leaving may interrupt the import process. Please wait til the operation is complete";
    };

    axios
      .post(`/rejections/footprint_upload`, form, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      })
      .then(({ data }) => {
        console.log("submit response", data);
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });
        // Reset form if successful
        if (data.state) {
          setTimeout(() => {
            resetForm();
          }, 500);
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
    setSubmitted(false);
    setLoading(false);
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Inputs</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Footprint Rejections</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Import</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderHelp()}
      <Divider />
      {renderMessage()}
      {renderForm()}
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
            Rejects Footprints that match the Strip Frame and it's Flight Date
            that does not have an associated tile.
          </p>
          <Divider />
          <Grid divided="vertically">
            <Grid.Row columns={2}>
              <Grid.Column>
                <Header as="h5">Inputs</Header>
                <List bulleted>
                  <List.Item>
                    A <b>single</b> <b>.txt</b> file
                  </List.Item>
                  <List.Item>
                    Text file <b>must</b> consist of a Strip Frame on separate
                    lines
                  </List.Item>
                  <List.Item>
                    Users can add a rejection message by separating the strip
                    frame with a space{" "}
                    <i>(e.g. 1234_5678 Clouds and shadows)</i>
                  </List.Item>
                </List>
              </Grid.Column>
              <Grid.Column>
                <Header as="h5">Process</Header>
                <List bulleted>
                  <List.Item>
                    The txt file will be iterated and the Footprint will be
                    found with the <b>Strip Frame</b> and it's{" "}
                    <b>Flight Date</b> will be removed if it has no assoicated
                    Tile
                  </List.Item>
                  <List.Item>
                    If the Footprint has an associated Tile then it will{" "}
                    <b>not be rejected</b>
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
    if (message && message.status === "loading") return null;

    return (
      <Form>
        <Form.Group widths="equal">
          <Form.Field error={errors.hasOwnProperty("flight_date")}>
            <div className="calendar-input">
              <Controller
                name={"flight_date"}
                control={control}
                rules={{
                  required: "Required",
                }}
                render={({ field: { name, value } }) => {
                  console.log("flight_date render", { name, value });
                  return (
                    <DateInput
                      closable
                      clearable
                      name={name}
                      label={"Flight Date"}
                      required={true}
                      value={value || ""}
                      dateFormat="MM/DD/YYYY"
                      iconPosition="left"
                      onChange={handleChange}
                      autoComplete="off"
                    />
                  );
                }}
              />
            </div>
            {errors[`flight_date`] && (
              <Label pointing prompt>
                {errors[`flight_date`].message}
              </Label>
            )}
          </Form.Field>

          <Form.Field
            required
            error={errors.hasOwnProperty("file")}
            style={{ margin: "0" }}
          >
            <label>Strip Frames (.txt)</label>
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
        </Form.Group>

        <Divider />

        <Button
          animated
          primary
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
        <Button
          animated
          secondary
          floated="right"
          type="button"
          onClick={() => resetForm()}
        >
          <ButtonContent visible>Reset</ButtonContent>
          <ButtonContent hidden>
            <Icon name="undo" />
          </ButtonContent>
        </Button>
        <div style={{ clear: "both" }} />
        <br />
        <br />
        <br />
      </Form>
    );
  }
}
