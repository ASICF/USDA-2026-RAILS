import React, { useState, Fragment, useEffect } from "react";

import {
  Button,
  Header,
  Modal,
  Icon,
  Divider,
  Segment,
  Breadcrumb,
  Grid,
  Form,
  ButtonContent,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";

const Loadout = ({ record, cameras, planes, companies, token }) => {
  const [message, setMessage] = useState(null);
  const [promptDestroy, setPromptDestroy] = useState(false);
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

  console.error("loadouts", { record, cameras, planes, companies, token });

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setSubmitted(true);
    setLoading(true);
    var obj = { authenticity_token: token };
    for (const property in data) {
      obj[`loadout[${property}]`] = data[property];
    }

    if (record.id) {
      axios
        .patch(`/loadouts/${record.id}`, {
          loadout: data,
          authenticity_token: token,
        })
        .then(({ data }) => handleResponse(data));
    } else {
      axios
        .post(`/loadouts`, {
          loadout: data,
          authenticity_token: token,
        })
        .then(({ data }) => handleResponse(data));
    }
  };

  const destroy = () => {
    console.error("destroy");

    axios
      .delete(`/loadouts/${record.id}`, {
        data: { authenticity_token: token },
      })
      .then(({ data }) => {
        setPromptDestroy(false);
        handleResponse(data);
      });
  };

  const handleResponse = (data) => {
    console.log("response", data);
    if (data.pass) {
      setMessage({
        status: "Success",
        text: data.message,
      });
      setTimeout(() => {
        window.location.href = "/loadouts";
      }, 3000);
    } else {
      setMessage({
        status: "Error",
        text: data.message ? data.message : "Something went wrong",
      });
    }
    setLoading(false);
    setSubmitted(false);
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Manage</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Loadouts</Breadcrumb.Section>
        {record.id ? (
          <Fragment>
            <Breadcrumb.Divider />
            <Breadcrumb.Section>{record.id}</Breadcrumb.Section>
            <Breadcrumb.Divider />
            <Breadcrumb.Section active>Edit</Breadcrumb.Section>
          </Fragment>
        ) : (
          <Fragment>
            <Breadcrumb.Divider />
            <Breadcrumb.Section active>New</Breadcrumb.Section>
          </Fragment>
        )}
      </Breadcrumbs>
      <Divider />
      <MessageBox
        title={"Notice"}
        message={`The Loadout Name should be a single uppercase letter.`}
      />
      {renderMessage()}
      {renderDestroyPrompt()}
      {renderForm()}
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

  function renderDestroyPrompt() {
    if (!promptDestroy) return null;

    return (
      <Modal
        basic
        // onClose={() => setOpen(false)}
        // onOpen={() => setOpen(true)}
        open={true}
        size="small"
      >
        <Header icon>
          <Icon name="delete" />
          Are you sure you want to Delete Record?
        </Header>
        <Modal.Content style={{ textAlign: "center" }}>
          <p>
            Proceeding will destroy the record and there is no restoring the
            record.
          </p>
        </Modal.Content>
        <Modal.Actions>
          <Button inverted onClick={() => setPromptDestroy(false)}>
            Cancel
          </Button>
          <Button animated color="red" inverted onClick={() => destroy()}>
            <ButtonContent visible>Destroy</ButtonContent>
            <ButtonContent hidden>
              <Icon name="check circle" />
            </ButtonContent>
          </Button>
        </Modal.Actions>
      </Modal>
    );
  }

  function renderForm() {
    if (message && message.status === "loading") return null;

    return (
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"name"}
            control={control}
            rules={{
              required: "Required",
              pattern: {
                value: /^[A-Z]$/, // Strictly validates for a single uppercase letter
                message: "Must be a single uppercase letter",
              },
            }}
            defaultValue={record.name ? record.name.toUpperCase() : ""}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                autoComplete="off"
                label={"Name"}
                name={name}
                required={true}
                maxLength={1}
                onBlur={onBlur}
                onChange={(e) => {
                  // Convert the input to uppercase immediately
                  const val = e.target.value.toUpperCase();

                  // Only updates state if it's an empty string (for deletes)
                  // or a single uppercase letter from A to Z
                  if (val === "" || /^[A-Z]$/.test(val)) {
                    onChange(val);
                  }
                }}
                value={value || ""}
                error={errors["name"] && errors["name"].message}
                style={{ textTransform: "uppercase" }} // UX Polish: ensures the visual caret behaves nicely when typing
              />
            )}
          />
          <Controller
            name={"plane_id"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={record.plane_id || ""}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                label={"Plane"}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={planes.map((record) => {
                  return {
                    key: record.id,
                    text: record.name,
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
            rules={{ required: "Required" }}
            defaultValue={record.camera_id || ""}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                label={"Camera"}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={cameras.map((record) => {
                  return {
                    key: record.id,
                    text: record.name,
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
        <Divider />

        {record.id && (
          <Button
            animated="fade"
            color="red"
            floated="left"
            type="button"
            onClick={() => setPromptDestroy(true)}
          >
            <ButtonContent visible>Destroy</ButtonContent>
            <ButtonContent hidden>
              <Icon name="delete" />
            </ButtonContent>
          </Button>
        )}
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
          onClick={() => reset()}
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
};

export default Loadout;
