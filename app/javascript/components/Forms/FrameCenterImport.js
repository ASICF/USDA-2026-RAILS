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

export default function FrameCenterImport({
  companies,
  cameras,
  states,
  projects,
  sl_split_path,
  nri_split_path,
  token,
}) {
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [project, setProject] = useState("NRI/SL");
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  // const fileRef = useRef()

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  console.log("FrameCenterImport", {
    errors: errors,
    // companies,
    // cameras,
    // states,
    // projects,
    // token,
    // errors,
  });

  const handleChange = (e, { name, value }) => {
    if (name === "project") setProject(value);
    setValue(name, value);
  };

  const resetForm = () => {
    reset({
      project: "NRI/SL",
      flown_by_id: 1,
      camera_id: 4,
      flight_date: "",
      file: "",
    });
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);
    setLoading(true);
    const form = new FormData();

    form.append("authenticity_token", token);
    form.append("frame_centers[project]", data.project);
    form.append("frame_centers[flown_by_id]", data.flown_by_id);
    form.append("frame_centers[camera_id]", data.camera_id);
    form.append(
      "frame_centers[flight_date]",
      moment(data.flight_date, "l").format("YYYY-MM-DD")
    );
    if (project === "NAIP")
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
          <p>Imports the Frame Centers as text files</p>
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
                    <b>Strip Frame</b>, <b>GPS Time</b>, <b>X</b>, <b>Y</b>,{" "}
                    <b>Z</b>, <b>Omega Phi</b>, and <b>Kappa</b>
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
                    The Frame Center points select Footprints that they are
                    contained within
                  </List.Item>
                  <List.Item>
                    The Footprints are then dissolved and selects all the Tiles
                    (that have not been marked as AT Started) that are contained
                    within and sets the current date as the AT Start and AT Done
                    date
                  </List.Item>
                  <List.Item>
                    The selected Tile then matches to the nearest Frame Center
                    (from within this upload) and copies the Strip Frame
                  </List.Item>
                  <List.Item>
                    The EO is split up by State and UTM into a folder structure
                    in the Output EO Path directory for production
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
        </Form.Group>
        <Form.Group widths="equal">
          <Controller
            name={"camera_id"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={4}
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
          {project === "NAIP" && (
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
          )}
        </Form.Group>

        <Form.Group widths="equal">
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
              // ref={fileRef}
            />
            {errors[`file`] && (
              <Label pointing prompt>
                {errors[`file`].message}
              </Label>
            )}
          </Form.Field>

          <Form.Field>
            <label>EO Splitter Output</label>
            <p style={{ margin: "0.5em" }}>
              SL:  {sl_split_path}<br/>
              NRI:  {nri_split_path}
            </p>
          </Form.Field>
        </Form.Group>

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
          secondary
          animated
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
