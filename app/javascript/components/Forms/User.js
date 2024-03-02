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
  ButtonContent
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";

export default function User({ record, roles, token }) {
  const [message, setMessage] = useState(null);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const {
    handleSubmit,
    reset,
    setValue,
    register,
    getValues,
    control,
    formState: { errors },
  } = useForm();

  //   console.error("User", { record, roles, token, errors, values: getValues() });

  useEffect(() => {
    setValue("id", record.id);
  }, []);

  const handleChange = (e, { name, value }) => {
    console.log(name, value);
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data, `/users/${data.id}`);
    setSubmitted(true);
    setLoading(true);

    axios
      .patch(`/users/${data.id}`, {
        user: data,
        authenticity_token: token,
      })
      .then(({ data }) => {
        console.log("response", data);

        if (data.pass) {
          setMessage({
            status: "Success",
            text: data.message,
          });
          setTimeout(() => {
            window.location.href = "/users";
          }, 3000);
        } else {
          setMessage({
            status: "Error",
            text: data.message ? data.message : "Something went wrong",
          });
        }
      })
      .catch((err) => {
        console.error(err);
      });
    setSubmitted(false);
    setLoading(false);
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Manage</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>
          <a href="/users/">Users</a>
        </Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>
          {record.first_name} {record.last_name}
        </Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>Edit</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {renderMessage()}
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

  function renderForm() {
    if (message && message.status === "loading") return null;

    return (
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"first_name"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={record.first_name || ""}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                label={"First Name"}
                name={name}
                required={true}
                onBlur={onBlur}
                onChange={onChange}
                value={value || ""}
                autoComplete="off"
                error={errors["first_name"] && errors["first_name"].message}
              />
            )}
          />
          <Controller
            name={"last_name"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={record.last_name || ""}
            render={({ field: { name, onBlur, onChange, value } }) => (
              <Form.Input
                fluid
                label={"Last Name"}
                name={name}
                required={true}
                onBlur={onBlur}
                onChange={onChange}
                value={value || ""}
                autoComplete="off"
                error={errors["last_name"] && errors["last_name"].message}
              />
            )}
          />
        </Form.Group>

        <Form.Group widths="equal">
          <Controller
            name={"role"}
            control={control}
            rules={{ required: "Required" }}
            defaultValue={record.role || ""}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                label={"Role"}
                value={value || ""}
                onChange={handleChange}
                autoComplete="off"
                options={roles.map((role) => {
                  return {
                    key: role,
                    text: role,
                    value: role,
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
          <Controller
            name={"approved"}
            control={control}
            defaultValue={record.approved}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                label={"Approved"}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={[
                  { label: "Yes", value: true },
                  { label: "No", value: false },
                ].map((record) => {
                  return {
                    key: record.label,
                    text: record.label,
                    value: record.value,
                  };
                })}
                error={
                  errors["approved"]
                    ? {
                        content: errors["approved"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
          <Controller
            name={"marked_as_destroyed"}
            control={control}
            defaultValue={record.marked_as_destroyed}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                name={name}
                required={true}
                label={"Marked as Destroyed"}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={[
                  { label: "Yes", value: true },
                  { label: "No", value: false },
                ].map((record) => {
                  return {
                    key: record.label,
                    text: record.label,
                    value: record.value,
                  };
                })}
                error={
                  errors["marked_as_destroyed"]
                    ? {
                        content: errors["marked_as_destroyed"].message,
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
          animated
          onClick={handleSubmit(onSubmit)}
        >
        <ButtonContent visible>Submit</ButtonContent>
          <ButtonContent hidden>
          <Icon name='arrow right' />
          </ButtonContent>
        </Button>
        <Button secondary animated floated="right" type="button" onClick={() => reset()}>
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
