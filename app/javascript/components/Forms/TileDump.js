import React, { useState, Fragment, useEffect } from "react";

import {
  Button,
  Header,
  Modal,
  Icon,
  Divider,
  Accordion,
  Breadcrumb,
  Grid,
  Form,
  List,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";

function TileDump({ states, projects, token }) {
  const [message, setMessage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [accordionState, setAccordionState] = useState(false);

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  console.log("TileDump", { states, projects });

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const resetForm = () => {
    reset({
      project: "",
      state_id: "",
      input_directory: "",
    });
  };

  const onSubmit = (data) => {
    console.error("onSubmit", { data });

    setLoading(true);
    setMessage({
      status: "loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    axios
      .post(`/tile_dump/upload`, {
        state_id: data.state_id,
        project: data.project,
        input_directory: data.input_directory,
        authenticity_token: token,
      })
      .then(({ data }) => {
        console.log("submit response", data);

        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });
        setLoading(false);
        resetForm()

        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.error("Error", err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        setLoading(false);
        window.onbeforeunload = null;
      });
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Inputs</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Tile Dump</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
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
            Iterates the Tile Dump Folder and finds any Tiles that have not been
            marked as Dumped. Also performs vallidation against files.
          </p>
          <Divider />
          <Grid divided="vertically">
            <Grid.Row columns={2}>
              <Grid.Column>
                <Header as="h5">Inputs</Header>
                <List bulleted>
                  <List.Item>
                    The state all the Tiffs are contained within
                  </List.Item>
                  <List.Item>
                    The Path to the Tile Dump Folder in the P Drive
                  </List.Item>
                </List>
              </Grid.Column>
              <Grid.Column>
                <Header as="h5">Process</Header>
                <List bulleted>
                  <List.Item>
                    Iterates the Tile Dump Folder and finds the associated Tile
                    in the system
                  </List.Item>
                  <List.Item>
                    If the Tile is not marked as Dumped then it is updated to
                    today's date and is passed to the validator. If the Tile has
                    already been set then it does not get re-validated.
                  </List.Item>
                  <List.Item>
                    Validator will check the Tiff Tags for Projection, 4 Band,
                    and in the correct UTM Zone
                  </List.Item>
                  <List.Item>
                    Any Errors that occur will be added to a Text file in the
                    Tile Dump folder
                  </List.Item>
                </List>
              </Grid.Column>
            </Grid.Row>
          </Grid>
        </Accordion.Content>
      </Accordion>
      <Divider />
      {renderMessage()}
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                width={8}
                fluid
                search
                selection
                clearable
                name={name}
                data-value={value}
                label={"Project"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record) => {
                  return {
                    key: record,
                    value: record,
                    text: record,
                  };
                })}
                error={
                  errors[name]
                    ? {
                        content: errors[name].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
          <Controller
            name={"state_id"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                width={8}
                fluid
                search
                selection
                clearable
                name={name}
                data-value={value}
                label={"State"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={states.map((record) => {
                  return {
                    key: record.id,
                    value: record.id,
                    text: record.name,
                  };
                })}
                error={
                  errors[name]
                    ? {
                        content: errors[name].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>
        <Form.Group>
          <Controller
            name={"input_directory"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                width={16}
                label="Tile Dump Folder"
                autoComplete="off"
                name={name}
                required={true}
                onBlur={onBlur}
                onChange={onChange}
                value={value || ""}
                error={
                  errors["input_directory"] && errors["input_directory"].message
                }
              />
            )}
          />
        </Form.Group>

        <Button
          primary
          floated="right"
          type="button"
          onClick={handleSubmit(onSubmit)}
          disabled={loading}
        >
          Submit
        </Button>
        <Button
          secondary
          floated="right"
          type="button"
          onClick={() => {
            resetForm();
          }}
        >
          Reset
        </Button>
        <div style={{ clear: "both" }} />
        <br />
        <br />
      </Form>
    </div>
  );

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
}

export default TileDump;
