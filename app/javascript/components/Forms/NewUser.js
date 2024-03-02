import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Message,
  Divider,
  Breadcrumb,
  Form,
} from "semantic-ui-react";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";
import { Controller, useForm } from "react-hook-form";

export default function NewUser(props) {
  const [message, setMessage] = useState(null);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const {
    handleSubmit,
    reset,
    setValue,
    control,
    formState: { errors },
  } = useForm();

  useEffect(() => {
    if (message) {
      setTimeout(() => {
        setMessage(null);
      }, 5000);
    }
  }, [message]);

  const onSubmit = (data) => {
    setLoading(true)
    setSubmitted(true)
    axios
      .post(`/users`, {
        user: data,
        authenticity_token: props.token,
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setLoading(false)
        setSubmitted(false)
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.state
            ? "Successfully Created User, Invitation Sent."
            : data.message,
        });
        // Reset form if successful
        if (data.state) {
          reset();
        }
      })
      .catch((err) => {
        console.log(err.inner);
      });
  };

  const onSwitchChange = (e, { name, value }) => {
    setValue(name, value);
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Users</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Create New User</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      <Message>
        <p>
          Create a new User for the app that will send them an email to create a new password.
        </p>
      </Message>
      {message && <MessageBox status={message.status} message={message.text} />}
      <Form>
        <Controller
          name={"email"}
          control={control}
          rules={{ required: "Required" }}
          render={({ field: { name, onChange, value } }) => (
            <Form.Input
              fluid
              label={"Email"}
              name={name}
              onChange={onChange}
              value={value || ""}
              error={errors["email"] && errors["email"].message}
            />
          )}
        />
        <Form.Group widths="equal">
          <Controller
            name={"first_name"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, onChange, value } }) => (
              <Form.Input
                fluid
                label={"First Name"}
                name={name}
                onChange={onChange}
                value={value || ""}
                error={errors["first_name"] && errors["first_name"].message}
              />
            )}
          />
          <Controller
            name={"last_name"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, onChange, value } }) => (
              <Form.Input
                fluid
                label={"Last Name"}
                name={name}
                onChange={onChange}
                value={value || ""}
                error={errors["last_name"] && errors["last_name"].message}
              />
            )}
          />
        </Form.Group>
        <Form.Group widths="equal">
          <Controller
            name={"title"}
            control={control}
            render={({ field: { name, onChange, value } }) => (
              <Form.Input
                fluid
                label={"Title"}
                name={name}
                onChange={onChange}
                value={value || ""}
                error={errors["title"] && errors["title"].message}
              />
            )}
          />
          <Controller
            name={"role"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, onChange, value } }) => (
              <Form.Select
                fluid
                name={name}
                data-value={value}
                label={"Role"}
                value={value || ""}
                onChange={onSwitchChange}
                autoComplete="off"
                options={props.roles.map((record) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                  };
                })}
                error={
                  errors["role"]
                    ? {
                        content: errors["role"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
        </Form.Group>
        <Divider />

        <Button primary floated="right" 
        loading={submitted}
        disabled={submitted}
        onClick={handleSubmit(onSubmit)}>
          Submit
        </Button>
        <Button secondary floated="right" onClick={() => reset()}>
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    </div>
  );
}
