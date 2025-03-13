import React, { useState, useEffect, useRef, Fragment } from "react";
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

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

export default function FootprintImport({
  projects,
  companies,
  cameras,
  planes,
  states,
  token,
}) {
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [project, setProject] = useState("NRI/SL");
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

  console.log("FootprintImport", {
    errors: errors,
    // projects,
    // companies,
    // cameras,
    // planes,
    // states,
    // token,
    // errors,
  });

  useEffect(() => {
    setValue("project", "NRI/SL");
    setValue("utm", "none");
  }, []);

  const handleChange = (e, { name, value }) => {
    if (name === "project") setProject(value);
    setValue(name, value);
  };

  const checkboxChange = (e, { name, checked }) => {
    setValue(name, checked);
  };

  const resetForm = () => {
    reset({
      project: "NRI/SL",
      flown_by_id: 1,
      flight_date: "",
      state_id: "",
      plane_id: 4,
      camera_id: 4,
      pilot_name: "",
      sensor_operator: "",
      last_file: false,
      files: null,
    });
    setProject("NRI/SL");
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);
    setLoading(true);
    const form = new FormData();

    form.append("authenticity_token", token);
    form.append("footprints[project]", data.project);
    form.append("footprints[flown_by_id]", data.flown_by_id);
    form.append(
      "footprints[flight_date]",
      moment(data.flight_date, "l").format("YYYY-MM-DD")
    );
    form.append("footprints[plane_id]", data.plane_id);
    form.append("footprints[camera_id]", data.camera_id);
    form.append("footprints[pilot_name]", data.pilot_name || "");
    form.append("footprints[sensor_operator]", data.sensor_operator || "");
    form.append("footprints[last_file]", data.last_file ? 1 : 0);
    if (project === "NAIP") form.append("footprints[state_id]", data.state_id);

    // Iterate the files and append them to the Form Data object
    for (let i = 0; i < data.files.length; i++) {
      let file = data.files.item(i);
      form.append("footprints[files][]", file);
    }

    setMessage({
      status: "Loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    window.onbeforeunload = () => {
      return "Leaving may interrupt the import process. Please wait til the operation is complete";
    };

    axios
      .post(`/footprints/upload`, form, {
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
        <Breadcrumb.Section>Footprints</Breadcrumb.Section>
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
          <p>Imports the Footprints flown by ASI or sub-contractors</p>
          <Divider />
          <Grid divided="vertically">
            <Grid.Row columns={2}>
              <Grid.Column>
                <Header as="h5">Inputs</Header>
                <List bulleted>
                  <List.Item>
                    A <b>single</b> shapefile that contains a{" "}
                    <b>.shp, .shx, .dbf, and .prj</b> files
                  </List.Item>
                  <List.Item>
                    The shapefile must contain a field called <b>"Name"</b> that
                    contains the Strip Frame required for joining to Frame
                    Centers
                  </List.Item>
                  <List.Item>
                    Check the <b>Last File for the Day</b> if it is the final
                    footprint upload for the day. This will send an email to
                    User's notifying them that all the footprints are uploaded
                  </List.Item>
                </List>
              </Grid.Column>
              <Grid.Column>
                <Header as="h5">Process</Header>
                <List bulleted>
                  <List.Item>
                    The Project dropdown allows scoping to a specific Project.
                    By Default it will be applied to all projects.
                  </List.Item>
                  <List.Item>NAIP Footprints must have a GSD of 60</List.Item>
                  <List.Item>
                    All Footprints are dissolved into a single feature
                  </List.Item>
                  <List.Item>
                    The non-flown Buffered Easements or DOQQ that are completely
                    contained by the Dissolved Footprints are selected and given
                    the Flown Date provided in the Form
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
        </Form.Group>
        <Form.Group widths="equal">
          <Controller
            name={"plane_id"}
            control={control}
            defaultValue={4}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                data-value={value}
                label={"Plane"}
                required={true}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={planes.map((record) => {
                  return {
                    key: record.id,
                    text: record.label,
                    disabled: !record.sl && !record.naip,
                    content: (
                      <Fragment>
                        {record.label}{" "}
                        {record.naip && (
                          <Label
                            size="tiny"
                            style={{ margin: "0 0.25em", float: "right" }}
                          >
                            NAIP
                          </Label>
                        )}
                        {record.sl && (
                          <Label
                            size="tiny"
                            style={{ margin: "0 0.25em", float: "right" }}
                          >
                            SL
                          </Label>
                        )}
                        {!record.sl && !record.naip && (
                          <Label
                            size="tiny"
                            style={{ margin: "0 0.25em", float: "right" }}
                          >
                            NA
                          </Label>
                        )}
                      </Fragment>
                    ),
                    value: record.id,
                  };
                })}
                error={
                  errors["plane_id"]
                    ? {
                        content: errors["plane_id"].message,
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
            defaultValue={4}
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
                    disabled: !record.sl && !record.naip,
                    content: (
                      <Fragment>
                        {record.label}{" "}
                        {record.naip && (
                          <Label
                            size="tiny"
                            style={{ margin: "0 0.25em", float: "right" }}
                          >
                            NAIP
                          </Label>
                        )}
                        {record.sl && (
                          <Label
                            size="tiny"
                            style={{ margin: "0 0.25em", float: "right" }}
                          >
                            SL
                          </Label>
                        )}
                        {!record.sl && !record.naip && (
                          <Label
                            size="tiny"
                            color="red"
                            style={{ margin: "0 0.25em", float: "right" }}
                          >
                            NA
                          </Label>
                        )}
                      </Fragment>
                    ),
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

        <Form.Group>
          <Form.Field
            required
            error={errors.hasOwnProperty("files")}
            style={{ margin: "0", width: "100%" }}
          >
            <label>Shapefile (.shp, .shx, .dbf, .prj)</label>
            <input
              {...register("files", { required: "Required" })}
              name="files"
              type="file"
              multiple
            />
            {errors[`files`] && (
              <Label pointing prompt>
                {errors[`files`].message}
              </Label>
            )}
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
        <br />
        <br />
        <br />
      </Form>
    );
  }
}
