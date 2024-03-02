import React, { useState, useEffect, Fragment } from "react";
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

export default function ADSImport({ companies, cameras, states, token }) {
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

  console.log("FrameCenterImport", {
    companies,
    cameras,
    states,
    token,
    errors,
  });

  useEffect(() => {
    setValue("utm", "none");
  }, []);

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setLoading(true)
    setSubmitted(true)
    const form = new FormData();

    form.append("authenticity_token", token);
    form.append("frame_centers[flown_by_id]", data.flown_by_id);
    form.append("frame_centers[camera_id]", data.camera_id);
    form.append(
      "frame_centers[flight_date]",
      moment(data.flight_date, "l").format("YYYY-MM-DD")
    );
    form.append("frame_centers[state_id]", data.state_id);
    form.append("frame_centers[file]", data.file[0]);

    setMessage({
      status: "loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    window.onbeforeunload = () => {
      return "Leaving may interrupt the import process. Please wait til the operation is complete";
    };

    axios
      .post(`/frame_centers/upload`, form, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setLoading(false)
        setSubmitted(false)
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });
        // Reset form if successful
        if (data.state) {
          reset();
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
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Inputs</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Frame Centers</Breadcrumb.Section>
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
          <p>Imports the Airborne Digital Sensors as Shapefiles</p>
          <Divider />
          <Grid divided="vertically">
            <Grid.Row columns={2}>
              <Grid.Column>
                <Header as="h5">Inputs</Header>
                <List bulleted>
                  <List.Item>
                    Only upload <b>One</b> shapefile at at time
                  </List.Item>
                  <List.Item>
                    If uploading a Shapefile it must include <b>.shp</b>,{" "}
                    <b>.shx</b>, <b>.dbf</b>, and <b>.prj</b> files
                  </List.Item>
                </List>
              </Grid.Column>
              <Grid.Column>
                <Header as="h5">Process</Header>
                <List bulleted>
                  <List.Item>
                    The Flight Date Time will be extracted from the filename
                  </List.Item>
                  <List.Item>
                    The shapefile will be ingested and iterated to create each
                    feature
                  </List.Item>
                  <List.Item>
                    The features will be dissolved into a single feature based
                    on the Flight Date, Flown By Company, Camera, and State.
                  </List.Item>
                  <List.Item>
                    The dissolved feature will be spatial queried against the
                    Easements and it will seelct any features that are
                    completely contained.
                  </List.Item>
                  <List.Item>
                    The easements are then iterated and the associated tiles
                    that match the same scopes as the ADS it will update the AT
                    Start/AT Done date. 
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
                data-value={value}
                label={"Flown By"}
                required={true}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={companies.map((record) => {
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
          <Controller
            name={"camera_id"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                data-value={value}
                label={"Camera"}
                required={true}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={cameras.map((record) => {
                  return {
                    key: record.id,
                    text: record.label,
                    value: record.id,
                  };
                })}
                error={
                  errors["camera_id"]
                    ? {
                        content: errors["camera_id"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>
        <Form.Group widths="equal">
          <Form.Field error={errors.hasOwnProperty("flight_date")}>
            <div className="calendar-input">
              <Controller
                name={"flight_date"}
                control={control}
                rules={{
                  required: "Required",
                }}
                render={({ field: { name, value, defaultValue } }) => (
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
                )}
              />
            </div>
            {errors[`flight_date`] && (
              <Label pointing prompt>
                {errors[`flight_date`].message}
              </Label>
            )}
          </Form.Field>
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
                data-value={value}
                label={"State"}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={states.map((record) => {
                  return {
                    key: record.id,
                    text: record.name,
                    value: record.id,
                  };
                })}
                error={
                  errors["utm"]
                    ? {
                        content: errors["utm"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>

        <Form.Field
          required
          error={errors.hasOwnProperty("file")}
          style={{ margin: "0" }}
        >
          <label>EO Frame Centers (.txt)</label>
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
          <Icon name='arrow right' />
          </ButtonContent>
        </Button>
        <Button secondary floated="right" type="button" onClick={() => reset()}>
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }
}
