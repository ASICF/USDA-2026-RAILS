import React, { useState, useEffect, useRef } from "react";
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
  Segment,
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

export default function PhotoIndexImport({
  companies,
  projects,
  token,
}) {
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
    token,
    errors,
  });

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const resetForm = () => {
    reset({
      project: "NRI/SL",
      flown_by_id: 1,
      // flight_date: "",
      file: "",
    });
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);
    setLoading(true);
    const form = new FormData();

    form.append("authenticity_token", token);
    form.append("photo_index[project]", data.project);
    form.append("photo_index[flown_by_id]", data.flown_by_id);
    // form.append(
    //   "photo_index[flight_date]",
    //   moment(data.flight_date, "l").format("YYYY-MM-DD")
    // );
    form.append("photo_index[file]", data.file[0]);

    setMessage({
      status: "loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    window.onbeforeunload = () => {
      return "Leaving may interrupt the import process. Please wait til the operation is complete";
    };

    axios
      .post(`/photo_index/upload`, form, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setSubmitted(false);
        setLoading(false);
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
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Inputs</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Photo Index</Breadcrumb.Section>
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
            Uploads the Photo Index File that is used to check sun angles and
            reject footprints if they are not met. This is not a replacement for
            the EO import but a way for Flight to quickly determine if a
            Footprint needs to be reflown due to Sun Angle.
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
                    Text file <b>must</b> contain the attributes named{" "}
                    <b>RUN</b>, <b>FRAME</b>, <b>GPS TIME</b>, <b>DATE</b>,{" "}
                    <b>WGS LATITUDE</b>, <b>WGS LONGITUDE</b>, and{" "}
                    <b>SUN ANGLE</b>
                  </List.Item>
                </List>
              </Grid.Column>
              <Grid.Column>
                <Header as="h5">Process</Header>
                <List bulleted>
                  <List.Item>
                    The Sun Angle is calculated based on the GPS Time and the
                    provided Flight Date
                  </List.Item>
                  <List.Item>
                    The associated footprint is found based on the Flight Date,
                    Strip Frame, Camera, Flown By, and if the Latitude/Longitude
                    contained within the footprint
                  </List.Item>
                  <List.Item>
                    If the Sun Angle is invalid then it will reject the
                    footprint
                  </List.Item>
                  <List.Item>The Tile does not get updated with</List.Item>
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
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={projects[0]}
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
            name={"flown_by_id"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={1}
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
                    text: `${record.alias} | ${record.name}`,
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
        </Form.Group>

        <Divider />

        <Divider />

        <Form.Field
          required
          error={errors.hasOwnProperty("file")}
          style={{ margin: "0" }}
        >
          <label>Photo Index (.txt)</label>
          <input
            {...register("file", { required: "Required" })}
            name="file"
            type="file"
            // ref={fileRef}
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
      </Form>
    );
  }
}
