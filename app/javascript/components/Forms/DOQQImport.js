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
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";

export default function DOQQImport({ states, token }) {
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
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

  console.log({ errors });

  const resetForm = () => {
    reset({
      files: "",
    });
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true)
    setLoading(true)
    const form = new FormData();

    form.append("authenticity_token", token);
    form.append("state_id", data.state_id);

    // Iterate the files and append them to the Form Data object
    for (let i = 0; i < data.files.length; i++) {
      let file = data.files.item(i);
      form.append("files[]", file);
    }

    setMessage({
      status: "loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    window.onbeforeunload = () => {
      return "Leaving may interrupt the import process. Please wait til the operation is complete";
    };

    axios
      .post(`/doqqs/upload`, form, {
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
        <Breadcrumb.Section>DOQQ</Breadcrumb.Section>
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
          <p>Imports the DOQQs via Shapefile</p>
          <Divider />
          <Grid divided="vertically">
            <Grid.Row columns={2}>
              <Grid.Column>
                <Header as="h5">Inputs</Header>
                <List bulleted>
                  <List.Item>
                    A <b>single shapefile</b> that contains a{" "}
                    <b>.shp, .shx, .dbf, and .prj</b> files
                  </List.Item>
                </List>
              </Grid.Column>
              <Grid.Column>
                <Header as="h5">Process</Header>
                <List bulleted>
                  <List.Item>
                    The associationed County, State, and UTM will be verified
                    and calculated
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
          <Form.Field
            required
            error={errors.hasOwnProperty("files")}
            style={{ margin: "0" }}
          >
            <label>DOQQ Shapefile (.shp, .shx, .dbf, and .prj)</label>
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
          <Controller
            name={"state_id"}
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
                label={"State"}
                required={true}
                value={value}
                onChange={(i, { value }) => {
                  setValue("state_id", value);
                }}
                autoComplete="off"
                options={states.map((record) => {
                  return {
                    key: record.id,
                    value: record.id,
                    text: record.name,
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
        </Form.Group>

        <Divider />

        <Button
          primary
          floated="right"
          type="button"
          loading={submitted}
          disabled={submitted}
          onClick={handleSubmit(onSubmit)}
        >
          Submit
        </Button>
        <Button
          secondary
          floated="right"
          type="button"
          onClick={() => resetForm()}
        >
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }
}
