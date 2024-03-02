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
  ButtonContent
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

export default function Rejection({ token }) {
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
    setLoading(true)
    const form = new FormData();

    form.append("authenticity_token", token);
    form.append(
      "rejection[flight_date]",
      moment(data.flight_date, "l").format("YYYY-MM-DD")
    );
    // form.append(
    //   "rejection[reject_date]",
    //   moment(data.flight_date, "l").format("YYYY-MM-DD")
    // );
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
      .post(`/rejections/upload`, form, {
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
    setLoading(false)
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Inputs</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Rejections</Breadcrumb.Section>
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
            Rejects Tiles that match teh PolyID and it's associated Footprints
            and Frame Centers
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
                    Text file <b>must</b> consist of a Poly ID on separate lines
                  </List.Item>
                </List>
              </Grid.Column>
              <Grid.Column>
                <Header as="h5">Process</Header>
                <List bulleted>
                  <List.Item>
                    The txt file will be iterated and the Easement will be found
                    with the Poly ID and it's <b>Flight Date</b> will be reset
                    to null
                  </List.Item>
                  <List.Item>
                    The Associated Tile will be cloned to the{" "}
                    <b>Rejected Tile</b> and record will be reset back to "Ready
                    to Fly" state
                  </List.Item>
                  <List.Item>
                    The associated Footprints to the Tile will be iterated and
                    each Footprint will then check it's associations to the
                    other Tile. If the Footprint has no other association it is
                    cloned to the <b>Rejected Footprint</b> and the original
                    record will be deleted. If it has other associated Tiles it
                    is not destroyed.
                  </List.Item>
                  <List.Item>
                    The Rejected Footprint's associated Frame Center will be
                    cloned to the <b>Rejected Frame Centers</b> and the original
                    will be destroyed
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
            <label>Poly IDs (.txt)</label>
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

          {/* <Form.Field error={errors.hasOwnProperty("reject_date")}>
            <div className="calendar-input">
              <Controller
                name={"reject_date"}
                control={control}
                rules={{
                  required: "Required",
                }}
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Reject Date"}
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
            {errors[`reject_date`] && (
              <Label pointing prompt>
                {errors[`reject_date`].message}
              </Label>
            )}
          </Form.Field> */}
        </Form.Group>

        {/* <Form.Field error={errors.hasOwnProperty("file")}>
          <Controller
            name={"file"}
            control={control}
            defaultValue={""}
            rules={{
              required: "Required",
            }}
            render={({ field: { name, value, defaultValue } }) => {
              console.error("file render", { name, value, defaultValue });
              return (
                <input
                  type="file"
                  name={name}
                  value={value.filename}
                  ref={fileRef}
                  onChange={(event) => {
                    return fileChange(event.target.files);
                  }}
                />
              );
            }}
          />
          {errors[`file`] && (
            <Label pointing prompt>
              {errors[`file`].message}
            </Label>
          )}
        </Form.Field> */}

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
          <Icon name='arrow right' />
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
